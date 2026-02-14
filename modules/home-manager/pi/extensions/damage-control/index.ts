import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { readFileSync, existsSync } from "fs";
import { resolve } from "path";
import { parse as parseYaml } from "yaml";

interface Pattern { pattern: string; reason: string; ask?: boolean; scope?: string; }
interface Config {
  bashToolPatterns: Pattern[];
  mcpToolPatterns: Pattern[];
  zeroAccessPaths: string[];
  readOnlyPaths: string[];
  noDeletePaths: string[];
}

function loadConfig(): Config {
  const globalRaw = readFileSync(resolve(__dirname, "patterns.yaml"), "utf-8");
  const global = parseYaml(globalRaw) as Config;

  // Merge project-local patterns if they exist
  const localPath = resolve(process.cwd(), ".pi/extensions/damage-control/patterns.yaml");
  if (existsSync(localPath)) {
    const localRaw = readFileSync(localPath, "utf-8");
    const local = parseYaml(localRaw) as Partial<Config>;
    if (local.bashToolPatterns) global.bashToolPatterns.push(...local.bashToolPatterns);
    if (local.mcpToolPatterns) global.mcpToolPatterns.push(...local.mcpToolPatterns);
    if (local.zeroAccessPaths) global.zeroAccessPaths.push(...local.zeroAccessPaths);
    if (local.readOnlyPaths) global.readOnlyPaths.push(...local.readOnlyPaths);
    if (local.noDeletePaths) global.noDeletePaths.push(...local.noDeletePaths);
  }
  return global;
}

function expandPath(p: string): string {
  return p.replace(/^~/, process.env.HOME || "");
}

function matchesPath(filePath: string, paths: string[]): boolean {
  const abs = resolve(filePath);
  return paths.some(p => {
    const expanded = expandPath(p);
    if (expanded.includes("*")) {
      const re = new RegExp(expanded.replace(/\./g, "\\.").replace(/\*/g, ".*"));
      return re.test(abs) || re.test(filePath);
    }
    return abs.startsWith(expanded) || filePath.includes(p);
  });
}

export default function (pi: ExtensionAPI) {
  const config = loadConfig();
  const bashRegexes = config.bashToolPatterns.map(p => ({
    re: new RegExp(p.pattern), reason: p.reason, ask: p.ask ?? false
  }));
  const mcpRegexes = config.mcpToolPatterns.map(p => ({
    re: new RegExp(p.pattern), reason: p.reason
  }));

  pi.on("tool_call", async (event, ctx) => {
    const toolName = event.toolName;

    // --- Bash guard ---
    if (toolName === "bash") {
      const cmd = event.input?.command || "";
      for (const { re, reason, ask } of bashRegexes) {
        if (re.test(cmd)) {
          if (ask) {
            const ok = await ctx.ui.confirm("Confirm command", `${reason}\n\n${cmd}`, { defaultNo: true });
            if (!ok) return { block: true, reason };
          } else {
            return { block: true, reason };
          }
        }
      }
      // Check noDeletePaths against rm commands
      if (/\brm\b/.test(cmd)) {
        for (const p of config.noDeletePaths) {
          if (cmd.includes(expandPath(p)) || cmd.includes(p)) {
            return { block: true, reason: `Cannot delete protected path: ${p}` };
          }
        }
      }
    }

    // --- Path-based guards for write/edit ---
    if (toolName === "write" || toolName === "edit") {
      const path = event.input?.file_path || "";
      if (matchesPath(path, config.zeroAccessPaths)) {
        return { block: true, reason: `Zero-access path: ${path}` };
      }
      if (matchesPath(path, config.readOnlyPaths)) {
        return { block: true, reason: `Read-only path: ${path}` };
      }
    }

    // --- Path-based guards for read ---
    if (toolName === "read") {
      const path = event.input?.file_path || "";
      if (matchesPath(path, config.zeroAccessPaths)) {
        return { block: true, reason: `Zero-access path: ${path}` };
      }
    }

    // --- MCP guard ---
    if (toolName === "mcp") {
      const toolInput = JSON.stringify(event.input || {});
      for (const { re, reason } of mcpRegexes) {
        if (re.test(toolInput)) {
          const ok = await ctx.ui.confirm("MCP operation", `${reason}\n\n${toolInput.slice(0, 200)}`, { defaultNo: true });
          if (!ok) return { block: true, reason };
        }
      }
    }
  });
}
