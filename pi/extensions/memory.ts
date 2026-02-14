/**
 * memory-v2.ts - Simplified memory hook for Pi
 *
 * Philosophy: The hook handles what the agent CAN'T do (pre-session recall,
 * per-input recall, capturing insights from responses). The agent handles
 * what it does BETTER (deciding what to save deliberately via MCP tools).
 *
 * Dependencies:
 *   - qmd CLI (for searching memory collection)
 *   - pi CLI in print mode (for background session summarization)
 *   - memory MCP directory (~/.config/memory/) for direct file writes
 *
 * Removed dependencies (vs v1):
 *   - forgetful-bridge (replaced by qmd CLI + direct filesystem)
 *   - Ollama (replaced by pi -p with Sonnet for summarization)
 *   - Queue system (no deferred extraction pipeline)
 *   - Transcript export (Pi has its own session files)
 *
 * Lifecycle hooks:
 *   1. session_start         → search qmd for project context
 *   2. before_agent_start    → inject recalled context
 *   3. input                 → search qmd for per-message recall
 *   4. agent_end             → capture ★ Insight blocks to memory
 *   5. session_before_compact → save session checkpoint
 *   6. session_shutdown      → spawn background summarizer (detached)
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import * as fs from "fs";
import * as path from "path";
import * as crypto from "crypto";
import { execSync, spawn } from "child_process";

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

const CONFIG = {
  /** qmd collection name for memories */
  MEMORY_COLLECTION: "memory",

  /** Directory where memory MCP stores markdown files */
  MEMORY_DIR: path.join(process.env.HOME || "", ".config", "memory"),

  /**
   * Token budget: 2% of 200K context = 4,000 tokens ≈ 16,000 chars.
   * Split: 60% session start (project context), 40% per-input (recall).
   * Session start is one-time; per-input repeats but gets compacted.
   */

  /** Max total chars for project topics at session start (60% of budget) */
  PROJECT_TOPIC_BUDGET: 8000,

  /** Max total chars for global patterns at session start */
  GLOBAL_RECALL_BUDGET: 1600,

  /** Max results for global recall search */
  GLOBAL_RECALL_LIMIT: 5,

  /** Max results for per-input recall */
  INPUT_RECALL_LIMIT: 5,

  /** Max total chars for per-input recall injection (40% of budget) */
  INPUT_RECALL_BUDGET: 6400,

  /** Minimum score (0-100) to include a qmd result */
  MIN_SCORE: 40,

  /** Timeout for qmd CLI calls (ms) */
  QMD_TIMEOUT: 5000,

  /** Max chars of memory content to include per search result */
  MAX_CONTENT_CHARS: 400,

  /** Model for background session summarization (via pi -p) */
  SUMMARIZER_MODEL: "anthropic/claude-sonnet-4-20250514:off",

  /** Minimum session messages to trigger summarization */
  MIN_MESSAGES_FOR_SUMMARY: 5,

  /** Temp directory for passing session data to background summarizer */
  TEMP_DIR: path.join(process.env.HOME || "", ".cache", "pi-memory"),

  /** Log file for debugging */
  LOG_FILE: "/tmp/pi-memory-hook.log",

  /** Skip patterns for user prompts that don't need recall */
  SKIP_PATTERNS: [
    /^\/\w+/,                 // slash commands
    /^(hi|hello|hey|thanks|ok|yes|no|sure|continue|go on|done|quit|exit)$/i,
    /^.{0,15}$/,              // very short messages
    /^\s*$/,                  // empty
  ],
};

// ---------------------------------------------------------------------------
// Logging
// ---------------------------------------------------------------------------

function log(tag: string, msg: string) {
  try {
    fs.appendFileSync(
      CONFIG.LOG_FILE,
      `${new Date().toISOString()} [memory:${tag}] ${msg}\n`
    );
  } catch { }
}

// ---------------------------------------------------------------------------
// Project detection
// ---------------------------------------------------------------------------

function detectProject(cwd: string): { name: string; repoName: string | null } {
  let name: string | null = null;
  let repoName: string | null = null;

  try {
    const remote = execSync("git config --get remote.origin.url", {
      cwd,
      encoding: "utf8",
      timeout: 1000,
      stdio: ["pipe", "pipe", "pipe"],
    }).trim();
    if (remote) {
      const match = remote.match(/[/:]([^/]+\/[^/]+?)(?:\.git)?$/);
      if (match?.[1]) {
        repoName = match[1];
        name = repoName.split("/").pop() || null;
      }
    }
  } catch { }

  if (!name) {
    try {
      const pkgPath = path.join(cwd, "package.json");
      if (fs.existsSync(pkgPath)) {
        const pkg = JSON.parse(fs.readFileSync(pkgPath, "utf8"));
        if (pkg.name) name = pkg.name;
      }
    } catch { }
  }

  return { name: name || path.basename(cwd), repoName };
}

// ---------------------------------------------------------------------------
// qmd CLI wrapper
// ---------------------------------------------------------------------------

interface QmdResult {
  path: string;
  score: number;
  title: string;
  snippet: string;
}

function qmdSearch(query: string, limit: number): QmdResult[] {
  try {
    // Truncate query to avoid E2BIG (ARG_MAX) on long user messages
    const safeQuery = query.slice(0, 500).replace(/\n/g, " ").trim();
    if (!safeQuery) return [];

    const raw = execSync(
      `qmd search ${JSON.stringify(safeQuery)} -c ${CONFIG.MEMORY_COLLECTION} -n ${limit} --files`,
      {
        encoding: "utf8",
        timeout: CONFIG.QMD_TIMEOUT,
        stdio: ["pipe", "pipe", "pipe"],
      }
    ).trim();

    if (!raw) return [];

    const results: QmdResult[] = [];
    for (const line of raw.split("\n")) {
      if (!line.trim()) continue;
      // Format: #docid,score,qmd://memory/path/to/file.md
      const parts = line.split(",");
      if (parts.length < 3) continue;

      const score = parseFloat(parts[1]) * 100;
      const filePath = parts.slice(2).join(",").trim();
      if (score < CONFIG.MIN_SCORE) continue;

      results.push({ path: filePath, score, title: "", snippet: "" });
    }

    // Fetch content for top results
    for (const result of results) {
      try {
        const content = execSync(
          `qmd get ${JSON.stringify(result.path)} -l 20`,
          {
            encoding: "utf8",
            timeout: 3000,
            stdio: ["pipe", "pipe", "pipe"],
          }
        ).trim();

        const titleMatch = content.match(/^title::\s*(.+)$/m);
        if (titleMatch) result.title = titleMatch[1].trim();

        const tagsMatch = content.match(/^tags::\s*(.+)$/m);
        const tags = tagsMatch ? tagsMatch[1].trim() : "";

        const bodyStart = content.indexOf("\n\n");
        const body = bodyStart >= 0 ? content.slice(bodyStart + 2) : content;

        result.snippet = body.slice(0, CONFIG.MAX_CONTENT_CHARS).trim();
        if (tags) result.snippet = `[${tags}]\n${result.snippet}`;
      } catch { }
    }

    return results;
  } catch (e: any) {
    log("qmd", `Search failed: ${e.message}`);
    return [];
  }
}

// ---------------------------------------------------------------------------
// Direct project file reading (for session start)
// ---------------------------------------------------------------------------

interface ProjectTopic {
  filename: string;
  title: string;
  content: string;
}

/**
 * Reads project topic files, fitting within a character budget.
 * Files are sorted by last modified (most recent first) so the most
 * recently updated topics get priority if the budget is tight.
 * Content is truncated per-file if needed to fit more topics.
 */
function readProjectTopics(project: string): ProjectTopic[] {
  const safeProject = project.replace(/[^a-zA-Z0-9_-]/g, "-");
  const projectsDir = path.join(CONFIG.MEMORY_DIR, "projects");

  if (!fs.existsSync(projectsDir)) return [];

  const topics: ProjectTopic[] = [];

  try {
    const files = fs.readdirSync(projectsDir)
      .filter((f) => f.startsWith(`${safeProject}--`) && f.endsWith(".md"));

    if (files.length === 0) return [];

    // Sort by modification time (most recently updated first)
    const withStats = files.map((f) => {
      const fp = path.join(projectsDir, f);
      try {
        return { file: f, mtime: fs.statSync(fp).mtimeMs };
      } catch {
        return { file: f, mtime: 0 };
      }
    });
    withStats.sort((a, b) => b.mtime - a.mtime);

    // Read files within budget
    let budgetLeft = CONFIG.PROJECT_TOPIC_BUDGET;
    const maxPerFile = files.length > 5
      ? Math.floor(CONFIG.PROJECT_TOPIC_BUDGET / files.length)
      : 600; // generous if few files

    for (const { file } of withStats) {
      if (budgetLeft <= 100) break; // not enough room for meaningful content

      try {
        const raw = fs.readFileSync(path.join(projectsDir, file), "utf8");

        const titleMatch = raw.match(/^title::\s*(.+)$/m);
        const title = titleMatch ? titleMatch[1].trim() : file;

        const bodyStart = raw.indexOf("\n\n");
        let body = bodyStart >= 0 ? raw.slice(bodyStart + 2).trim() : raw;

        if (body.length < 20) continue;

        // Truncate to fit budget
        const allowance = Math.min(body.length, maxPerFile, budgetLeft);
        if (body.length > allowance) {
          body = body.slice(0, allowance) + "\n[...truncated]";
        }

        topics.push({ filename: file, title, content: body });
        budgetLeft -= body.length;
      } catch { }
    }

    if (budgetLeft < CONFIG.PROJECT_TOPIC_BUDGET) {
      log("read-topics", `Loaded ${topics.length}/${files.length} topics (${CONFIG.PROJECT_TOPIC_BUDGET - budgetLeft} chars used)`);
    }
  } catch (e: any) {
    log("read-topics", `Failed: ${e.message}`);
  }

  return topics;
}

// ---------------------------------------------------------------------------
// Formatting
// ---------------------------------------------------------------------------

function formatStartContext(
  project: string,
  projectTopics: ProjectTopic[],
  globalMemories: QmdResult[]
): string | null {
  if (projectTopics.length === 0 && globalMemories.length === 0) return null;

  let output = `<memory_context>\n## Project Memory: ${project}\n\n`;

  if (projectTopics.length > 0) {
    for (const topic of projectTopics) {
      output += `### ${topic.title}\n`;
      output += `${topic.content}\n\n`;
    }
  }

  if (globalMemories.length > 0) {
    output += `### Related Patterns (cross-project)\n`;
    let globalChars = 0;
    for (const mem of globalMemories) {
      const entry = `- **${mem.title || mem.path}** (${mem.score.toFixed(0)}%)\n${mem.snippet ? `  ${mem.snippet.replace(/\n/g, "\n  ")}\n` : ""}\n`;
      if (globalChars + entry.length > CONFIG.GLOBAL_RECALL_BUDGET) break;
      output += entry;
      globalChars += entry.length;
    }
  }

  output += `</memory_context>`;
  return output;
}

function formatInputRecall(memories: QmdResult[]): string | null {
  if (memories.length === 0) return null;

  let output = "<memory_recall>\n";
  let charsUsed = 0;

  for (const mem of memories) {
    const line = `- **${mem.title || mem.path}** (${mem.score.toFixed(0)}%): ${(mem.snippet || "").split("\n")[0].slice(0, 150)}`;

    if (charsUsed + line.length > CONFIG.INPUT_RECALL_BUDGET) break;

    output += line + "\n";
    charsUsed += line.length;
  }

  if (charsUsed === 0) return null;

  output += "</memory_recall>";
  return output;
}

// ---------------------------------------------------------------------------
// Insight extraction from agent responses
// ---------------------------------------------------------------------------

/**
 * Extracts ★ Insight blocks from agent responses.
 *
 * Matches the pattern:
 *   ★ Insight - <title> ─────
 *   [content lines]
 *   ─────────────────────────
 */
function extractInsights(text: string): Array<{ title: string; content: string }> {
  const insights: Array<{ title: string; content: string }> = [];

  // Match insight blocks: ★ ... ─── through closing ───
  const pattern = /[★✦]\s*(?:Insight)\s*[-─—:]+\s*([^\n─]+)─*\n([\s\S]*?)─{5,}/gi;
  let match: RegExpExecArray | null;

  while ((match = pattern.exec(text)) !== null) {
    const title = match[1].trim().replace(/\s*─+$/, "").trim();
    const content = match[2].trim();

    // Skip empty or trivial insights
    if (content.length < 30) continue;

    insights.push({ title, content });
  }

  return insights;
}

/**
 * Saves an insight directly to the memory directory as a markdown file.
 * Uses the same frontmatter format as the memory MCP so qmd can index it.
 */
function saveInsightToMemory(
  title: string,
  content: string,
  project: string,
  repoName: string | null
): boolean {
  try {
    const category = categorizeInsight(content);
    const dir = path.join(CONFIG.MEMORY_DIR, category);

    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });

    // Generate a slug from the title
    const slug = title
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-|-$/g, "")
      .slice(0, 60);

    const filename = `${slug}.md`;
    const filepath = path.join(dir, filename);

    // Skip if a file with this name already exists (likely duplicate)
    if (fs.existsSync(filepath)) {
      log("insight", `Skipped duplicate: ${filename}`);
      return false;
    }

    const date = new Date().toISOString().split("T")[0];
    const tags = [`#${project}`, "#insight", "#auto-extracted"];
    if (repoName) tags.push(`#${repoName.replace(/\//g, "-")}`);

    const md = [
      `title:: ${title}`,
      `tags:: ${tags.join(", ")}`,
      `created:: [[${date}]]`,
      `importance:: 6`,
      `type:: insight`,
      repoName ? `source-repo:: ${repoName}` : null,
      "",
      content,
      "",
    ]
      .filter((line) => line !== null)
      .join("\n");

    fs.writeFileSync(filepath, md);
    log("insight", `Saved: ${category}/${filename}`);
    return true;
  } catch (e: any) {
    log("insight", `Failed to save: ${e.message}`);
    return false;
  }
}

/**
 * Simple keyword-based categorization matching the memory MCP's categories.
 */
function categorizeInsight(content: string): string {
  const lower = content.toLowerCase();

  if (/\b(api|endpoint|route|request|response|rest|graphql|grpc)\b/.test(lower))
    return "api";
  if (/\b(architect|design|pattern|structure|layer|module|component)\b/.test(lower))
    return "architecture";
  if (/\b(auth|token|jwt|oauth|session|permission|credential)\b/.test(lower))
    return "auth";
  if (/\b(config|env|setting|variable|yaml|toml|dotenv)\b/.test(lower))
    return "config";
  if (/\b(database|sql|query|migration|schema|table|index|postgres|mysql)\b/.test(lower))
    return "database";
  if (/\b(deploy|docker|ci|cd|pipeline|infra|terraform|k8s|kubernetes)\b/.test(lower))
    return "infrastructure";
  if (/\b(test|spec|assert|mock|fixture|coverage|jest|vitest|pytest)\b/.test(lower))
    return "testing";

  return "workflows"; // default bucket
}

// ---------------------------------------------------------------------------
// Session checkpoint (for compact events)
// ---------------------------------------------------------------------------

/**
 * Saves a lightweight checkpoint of the session topics to memory.
 * No LLM needed - just extracts file paths and key terms mentioned.
 */
function saveSessionCheckpoint(
  messages: Array<{ role: string; content: string }>,
  project: string,
  repoName: string | null
): boolean {
  if (messages.length < 5) return false;

  try {
    // Collect mentioned file paths
    const allText = messages.map((m) => m.content).join("\n");
    const files = new Set<string>();
    const filePattern = /(?:^|\s)([\w./\\-]+\.(?:ts|js|py|go|rs|yaml|yml|json|md|sql|tsx|jsx))\b/g;
    let match: RegExpExecArray | null;
    while ((match = filePattern.exec(allText)) !== null) {
      files.add(match[1]);
    }

    // Extract user's main topics (first line of each user message)
    const topics = messages
      .filter((m) => m.role === "user")
      .map((m) => m.content.split("\n")[0].slice(0, 100))
      .filter((t) => t.length > 15)
      .slice(-5); // last 5 topics

    if (topics.length === 0 && files.size === 0) return false;

    const dir = path.join(CONFIG.MEMORY_DIR, "workflows");
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });

    const date = new Date().toISOString().split("T")[0];
    const time = new Date().toISOString().replace(/[:.]/g, "-").slice(0, 19);
    const filename = `session-checkpoint-${time}.md`;
    const filepath = path.join(dir, filename);

    const md = [
      `title:: Session Checkpoint: ${project} (${date})`,
      `tags:: #${project}, #session-checkpoint, #auto-extracted`,
      `created:: [[${date}]]`,
      `importance:: 4`,
      `type:: checkpoint`,
      repoName ? `source-repo:: ${repoName}` : null,
      "",
      `## Topics Discussed`,
      ...topics.map((t) => `- ${t}`),
      "",
      files.size > 0 ? `## Files Referenced` : null,
      ...(files.size > 0 ? [...files].slice(0, 15).map((f) => `- \`${f}\``) : []),
      "",
    ]
      .filter((line) => line !== null)
      .join("\n");

    fs.writeFileSync(filepath, md);
    log("checkpoint", `Saved: ${filename} (${topics.length} topics, ${files.size} files)`);
    return true;
  } catch (e: any) {
    log("checkpoint", `Failed: ${e.message}`);
    return false;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function hashContent(content: string): string {
  return crypto.createHash("md5").update(content).digest("hex");
}

function shouldSkip(prompt: string): boolean {
  if (!prompt || typeof prompt !== "string") return true;
  return CONFIG.SKIP_PATTERNS.some((p) => p.test(prompt.trim()));
}

function getSessionMessages(
  ctx: any
): Array<{ role: string; content: string }> {
  const messages: Array<{ role: string; content: string }> = [];
  try {
    const branch = ctx.sessionManager.getBranch();
    for (const entry of branch) {
      if (!entry.message) continue;
      const role = entry.message.role || entry.type;
      if (role !== "user" && role !== "assistant") continue;

      let text = "";
      const content = entry.message.content;

      if (typeof content === "string") {
        text = content;
      } else if (Array.isArray(content)) {
        text = content
          .filter((b: any) => b.type === "text" && b.text)
          .map((b: any) => b.text)
          .join("\n");
      }

      if (text && text.length > 10) {
        messages.push({ role, content: text });
      }
    }
  } catch (e: any) {
    log("session", `Failed to read messages: ${e.message}`);
  }
  return messages;
}

// ---------------------------------------------------------------------------
// Extension entry point
// ---------------------------------------------------------------------------

export default function(pi: ExtensionAPI) {
  let pendingContext: string | null = null;
  let projectName: string | null = null;
  let repoName: string | null = null;
  let lastInputHash: string | null = null;

  // =========================================================================
  // 1. SESSION START - search qmd for project context
  // =========================================================================

  pi.on("session_start", async (_event, ctx) => {
    try {
      const cwd = ctx.cwd || process.cwd();
      const project = detectProject(cwd);
      projectName = project.name;
      repoName = project.repoName;

      log("start", `Project: ${projectName}, cwd: ${cwd}`);

      // 1. Read all project topic files directly (guaranteed, no search needed)
      const projectTopics = readProjectTopics(projectName);

      // 2. Search for cross-project patterns that might be relevant
      const globalResults = qmdSearch(
        `${projectName} conventions patterns best practices`,
        CONFIG.GLOBAL_RECALL_LIMIT
      );

      const formatted = formatStartContext(projectName, projectTopics, globalResults);

      if (formatted) {
        pendingContext = formatted;
        log("start", `Prepared: ${projectTopics.length} topics + ${globalResults.length} global`);
      } else {
        log("start", "No memories found");
      }
    } catch (e: any) {
      log("start", `Error: ${e.message}`);
    }
  });

  // =========================================================================
  // 2. BEFORE AGENT START - inject recalled context
  // =========================================================================

  pi.on("before_agent_start", async (_event, _ctx) => {
    if (!pendingContext) return;

    try {
      pi.appendEntry("memory_context", {
        type: "project_context",
        content: pendingContext,
      });
      log("inject", "Injected project context");
    } catch {
      try {
        pi.sendMessage(pendingContext!, { role: "system" });
      } catch { }
    }
    pendingContext = null;
  });

  // =========================================================================
  // 3. INPUT - per-message recall from qmd
  // =========================================================================
  //
  // On each user message, search qmd for relevant memories and inject them.
  // This ensures the agent always has relevant context without needing to
  // remember to search itself. Skips trivial inputs and deduplicates.
  //

  pi.on("input", async (event, _ctx) => {
    try {
      const userPrompt = event.text;
      if (!userPrompt || shouldSkip(userPrompt)) {
        return { action: "continue" };
      }

      const hash = hashContent(userPrompt);
      if (hash === lastInputHash) return { action: "continue" };
      lastInputHash = hash;

      log("input", `Query: ${userPrompt.slice(0, 60)}`);

      const results = qmdSearch(userPrompt, CONFIG.INPUT_RECALL_LIMIT);
      if (results.length === 0) return { action: "continue" };

      log("input", `Found ${results.length} results`);

      const formatted = formatInputRecall(results);
      if (!formatted) return { action: "continue" };

      try {
        pi.appendEntry("memory_recall", {
          type: "input_recall",
          content: formatted,
        });
      } catch {
        try {
          pi.sendMessage(formatted, { role: "system" });
        } catch { }
      }

      log("input", "Injected recall");
    } catch (e: any) {
      log("input", `Error: ${e.message}`);
    }
    return { action: "continue" };
  });

  // =========================================================================
  // 4. AGENT END - capture ★ Insight blocks from responses
  // =========================================================================
  //
  // The agent produces educational insight blocks (from the explanatory
  // output style). These are high-quality, already-summarized knowledge
  // that's perfect for memory. We extract and save them directly.
  //

  pi.on("agent_end", async (_event, ctx) => {
    try {
      const messages = getSessionMessages(ctx);
      if (messages.length === 0) return;

      const lastAssistant = messages
        .filter((m) => m.role === "assistant")
        .pop();
      if (!lastAssistant || lastAssistant.content.length < 50) return;

      const insights = extractInsights(lastAssistant.content);
      if (insights.length === 0) return;

      const project = projectName || "unknown";

      let saved = 0;
      for (const insight of insights) {
        if (saveInsightToMemory(insight.title, insight.content, project, repoName)) {
          saved++;
        }
      }

      if (saved > 0) {
        log("agent-end", `Saved ${saved}/${insights.length} insights`);
      }
    } catch (e: any) {
      log("agent-end", `Error: ${e.message}`);
    }
  });

  // =========================================================================
  // 5. SESSION BEFORE COMPACT - save session checkpoint
  // =========================================================================
  //
  // When context is about to be compacted, save a lightweight checkpoint
  // of what was discussed (topics + files). No LLM needed.
  // This is a safety net - the agent should have saved important memories
  // during the session, but this captures breadcrumbs if it didn't.
  //

  pi.on("session_before_compact", async (_event, ctx) => {
    try {
      const messages = getSessionMessages(ctx);
      const project = projectName || "unknown";

      saveSessionCheckpoint(messages, project, repoName);
      log("compact", `Checkpoint saved (${messages.length} messages)`);
    } catch (e: any) {
      log("compact", `Error: ${e.message}`);
    }
  });

  // =========================================================================
  // 6. SESSION SHUTDOWN - spawn background summarizer via pi -p
  // =========================================================================
  //
  // Copies the session JSONL to a temp location, then spawns a detached
  // shell script that pipes it to `pi -p` (Sonnet) for summarization.
  // Sonnet understands Pi's JSONL format natively - no preprocessing needed.
  // The detached process outlives Pi's exit.
  //

  pi.on("session_shutdown", async (_event, ctx) => {
    try {
      const messages = getSessionMessages(ctx);

      if (messages.length < CONFIG.MIN_MESSAGES_FOR_SUMMARY) {
        log("shutdown", `Skipped (${messages.length} < ${CONFIG.MIN_MESSAGES_FOR_SUMMARY} messages)`);
        return;
      }

      // Get the session JSONL file path
      let sessionFile: string | null = null;
      try {
        sessionFile = ctx.sessionManager.getSessionFile();
      } catch { }

      if (!sessionFile || !fs.existsSync(sessionFile)) {
        log("shutdown", "No session file found, skipping summarization");
        return;
      }

      const project = projectName || "unknown";
      const repo = repoName || "";

      // Copy session JSONL to temp (original may be modified after shutdown)
      if (!fs.existsSync(CONFIG.TEMP_DIR))
        fs.mkdirSync(CONFIG.TEMP_DIR, { recursive: true });

      const tempSession = path.join(CONFIG.TEMP_DIR, `session-${Date.now()}.jsonl`);
      fs.copyFileSync(sessionFile, tempSession);

      const sessionSize = fs.statSync(tempSession).size;

      // Build and spawn the summarizer
      const script = buildSummarizerScript(
        tempSession,
        project,
        repo,
        CONFIG.MEMORY_DIR,
        CONFIG.LOG_FILE,
        CONFIG.SUMMARIZER_MODEL
      );

      const child = spawn("bash", ["-c", script], {
        detached: true,
        stdio: "ignore",
        env: { ...process.env },
      });
      child.unref();

      log("shutdown", `Spawned summarizer (pid: ${child.pid}, ${messages.length} messages, ${(sessionSize / 1024).toFixed(0)}K)`);
    } catch (e: any) {
      log("shutdown", `Error: ${e.message}`);
    }
  });
}

// ---------------------------------------------------------------------------
// Background summarizer shell script builder
// ---------------------------------------------------------------------------
//
// Generates a bash script that maintains TOPIC-BASED memory files per project.
//
// Flow:
//   1. Find existing <project>--*.md files in projects/ directory
//   2. Feed existing file titles + content + new session JSONL to Sonnet
//   3. Sonnet decides: which files to update, which new topics to create
//   4. For updates: merge new info into existing file content
//   5. For creates: write new topic file
//
// This gives natural dedup (topics get merged, not appended) and natural
// organization (Sonnet decides topic boundaries, not keyword matching).
//

function buildSummarizerScript(
  sessionFile: string,
  project: string,
  repoName: string,
  memoryDir: string,
  logFile: string,
  model: string
): string {
  const safeProject = project.replace(/[^a-zA-Z0-9_-]/g, "-");

  return `
set -euo pipefail

SESSION_FILE="${sessionFile}"
PROJECT="${project}"
SAFE_PROJECT="${safeProject}"
REPO_NAME="${repoName}"
MEMORY_DIR="${memoryDir}"
LOG_FILE="${logFile}"
PROJECTS_DIR="$MEMORY_DIR/projects"

log() { echo "$(date -Iseconds) [memory:summarizer] $1" >> "$LOG_FILE" 2>/dev/null || true; }

SESSION_SIZE=$(wc -c < "$SESSION_FILE" | tr -d ' ')
log "Starting: project=$PROJECT size=\${SESSION_SIZE}B model=${model}"

mkdir -p "$PROJECTS_DIR"

# Collect existing topic files for this project
EXISTING_SECTION=""
FILE_COUNT=0
for f in "$PROJECTS_DIR"/"\${SAFE_PROJECT}"--*.md; do
  [ -f "$f" ] || continue
  FILE_COUNT=$((FILE_COUNT + 1))
  BASENAME=$(basename "$f")
  # Extract body after frontmatter (after first blank line)
  BODY=$(awk 'BEGIN{found=0} /^$/{if(!found){found=1;next}} found{print}' "$f")
  EXISTING_SECTION="$EXISTING_SECTION
---
FILE: $BASENAME
CONTENT:
$BODY
"
done

log "Found $FILE_COUNT existing topic files for $SAFE_PROJECT"

# Build prompt
PROMPT_FILE=$(mktemp /tmp/pi-summary-prompt-XXXXXX.txt)

cat > "$PROMPT_FILE" << 'PROMPT_END'
You maintain topic-based memory files for a project. Each file covers ONE specific topic/area.

PROMPT_END

if [ -n "$EXISTING_SECTION" ]; then
  echo "EXISTING MEMORY FILES for this project:" >> "$PROMPT_FILE"
  echo "$EXISTING_SECTION" >> "$PROMPT_FILE"
  echo "---" >> "$PROMPT_FILE"
  echo "" >> "$PROMPT_FILE"
fi

cat >> "$PROMPT_FILE" << 'PROMPT_END'
Given the NEW SESSION JSONL below, produce a JSON response with:
1. "updates" - existing files that need new info merged in. Include the FULL updated content (merged old + new, not just the diff).
2. "creates" - new topic files for topics not covered by existing files.

Rules:
- Each file should cover ONE coherent topic (max 300 words per file)
- Be specific: include file names, commands, config values
- Bullet points under clear headers
- File names must use format: PROJECTNAME--topic-slug.md
- Only create/update if the session has meaningful info for that topic
- Skip trivial sessions (just greetings, short Q&A with no lasting value)
- Output ONLY valid JSON, no markdown fencing, no preamble, no explanation

PROMPT_END

echo "Project name for filenames: $SAFE_PROJECT" >> "$PROMPT_FILE"
echo "" >> "$PROMPT_FILE"
echo "NEW SESSION JSONL:" >> "$PROMPT_FILE"
cat "$SESSION_FILE" >> "$PROMPT_FILE"
echo "" >> "$PROMPT_FILE"
echo "JSON:" >> "$PROMPT_FILE"

# Call pi -p
RAW_RESPONSE=$(cat "$PROMPT_FILE" | pi -p --model "${model}" 2>/dev/null) || {
  log "pi -p failed (exit $?)"
  rm -f "$SESSION_FILE" "$PROMPT_FILE"
  exit 1
}

rm -f "$PROMPT_FILE"

# Extract JSON from response (strip any markdown fencing or preamble)
# First try: find the JSON object directly
JSON_RESPONSE=$(echo "$RAW_RESPONSE" | grep -Pzo '(?s)\{.*\}' | tr '\\0' '\\n')
if [ -z "$JSON_RESPONSE" ]; then
  # Fallback: pipe through python to extract JSON
  JSON_RESPONSE=$(echo "$RAW_RESPONSE" | python3 -c "
import sys, re, json
text = sys.stdin.read()
m = re.search(r'\\{[\\s\\S]*\\}', text)
if m:
    try:
        json.loads(m.group())
        print(m.group())
    except: pass
" 2>/dev/null)
fi

if [ -z "$JSON_RESPONSE" ]; then
  log "No valid JSON in response, skipping"
  rm -f "$SESSION_FILE"
  exit 0
fi

log "Got JSON response (\${#JSON_RESPONSE} chars)"

DATE=$(date +%Y-%m-%d)
TAGS="#$PROJECT, #project-memory, #auto-maintained"
[ -n "$REPO_NAME" ] && TAGS="$TAGS, #$(echo "$REPO_NAME" | tr '/' '-')"

SAVED=0
UPDATED=0

# Process updates
echo "$JSON_RESPONSE" | jq -c '.updates[]? // empty' 2>/dev/null | while IFS= read -r item; do
  FILENAME=$(echo "$item" | jq -r '.filename // empty')
  CONTENT=$(echo "$item" | jq -r '.content // empty')

  if [ -z "$FILENAME" ] || [ -z "$CONTENT" ] || [ \${#CONTENT} -lt 30 ]; then
    continue
  fi

  # Ensure filename has correct project prefix
  case "$FILENAME" in
    "\${SAFE_PROJECT}"--*) ;; # good
    *) FILENAME="\${SAFE_PROJECT}--$FILENAME" ;;
  esac

  FILEPATH="$PROJECTS_DIR/$FILENAME"

  # Extract title from filename for frontmatter
  TITLE=$(echo "$FILENAME" | sed "s/^\${SAFE_PROJECT}--//" | sed 's/\.md$//' | tr '-' ' ')

  {
    echo "title:: $PROJECT: $TITLE"
    echo "tags:: $TAGS"
    echo "updated:: [[$DATE]]"
    echo "importance:: 7"
    echo "type:: project-memory"
    [ -n "$REPO_NAME" ] && echo "source-repo:: $REPO_NAME"
    echo ""
    echo "$CONTENT"
    echo ""
  } > "$FILEPATH"

  log "Updated: $FILENAME (\${#CONTENT} chars)"
  UPDATED=$((UPDATED + 1))
done

# Process creates
echo "$JSON_RESPONSE" | jq -c '.creates[]? // empty' 2>/dev/null | while IFS= read -r item; do
  FILENAME=$(echo "$item" | jq -r '.filename // empty')
  CONTENT=$(echo "$item" | jq -r '.content // empty')

  if [ -z "$FILENAME" ] || [ -z "$CONTENT" ] || [ \${#CONTENT} -lt 30 ]; then
    continue
  fi

  case "$FILENAME" in
    "\${SAFE_PROJECT}"--*) ;; # good
    *) FILENAME="\${SAFE_PROJECT}--$FILENAME" ;;
  esac

  FILEPATH="$PROJECTS_DIR/$FILENAME"

  # Skip if file already exists (shouldn't happen but safety check)
  if [ -f "$FILEPATH" ]; then
    log "Skipped create (already exists): $FILENAME"
    continue
  fi

  TITLE=$(echo "$FILENAME" | sed "s/^\${SAFE_PROJECT}--//" | sed 's/\.md$//' | tr '-' ' ')

  {
    echo "title:: $PROJECT: $TITLE"
    echo "tags:: $TAGS"
    echo "created:: [[$DATE]]"
    echo "importance:: 7"
    echo "type:: project-memory"
    [ -n "$REPO_NAME" ] && echo "source-repo:: $REPO_NAME"
    echo ""
    echo "$CONTENT"
    echo ""
  } > "$FILEPATH"

  log "Created: $FILENAME (\${#CONTENT} chars)"
  SAVED=$((SAVED + 1))
done

# Clean up
rm -f "$SESSION_FILE"
log "Done"
`;
}
