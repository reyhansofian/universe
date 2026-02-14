/**
 * memory-v3.ts - Lean memory hook for Pi
 *
 * Philosophy: Inject a compact INDEX of available memories, not full content.
 * The agent has qmd tools to fetch what it needs on-demand.
 *
 * What changed from v2:
 *   - Session start injects ~20 lines (title list) instead of ~100+ lines of content
 *   - Removed per-input recall (agent can search via qmd tools when it needs to)
 *   - Kept insight extraction and background summarization (those write, not read)
 *   - Total injection: ~500-1500 chars vs ~5000-8000 chars before
 *
 * Lifecycle hooks:
 *   1. session_start         → build compact topic index
 *   2. before_agent_start    → inject index (~20 lines)
 *   3. agent_end             → capture insight blocks to memory
 *   4. session_before_compact → save session checkpoint
 *   5. session_shutdown      → spawn background summarizer (detached)
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
  MEMORY_COLLECTION: "memory",
  MEMORY_DIR: path.join(process.env.HOME || "", ".config", "memory"),

  /** Max chars for the entire session-start injection */
  INDEX_BUDGET: 1500,

  /** Max project topic titles to show */
  MAX_TOPIC_TITLES: 10,

  /** Timeout for qmd CLI calls (ms) */
  QMD_TIMEOUT: 5000,

  SUMMARIZER_MODEL: "anthropic/claude-sonnet-4-20250514:off",
  MIN_MESSAGES_FOR_SUMMARY: 5,
  TEMP_DIR: path.join(process.env.HOME || "", ".cache", "pi-memory"),
  LOG_FILE: "/tmp/pi-memory-hook.log",
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
  } catch {}
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
  } catch {}

  if (!name) {
    try {
      const pkgPath = path.join(cwd, "package.json");
      if (fs.existsSync(pkgPath)) {
        const pkg = JSON.parse(fs.readFileSync(pkgPath, "utf8"));
        if (pkg.name) name = pkg.name;
      }
    } catch {}
  }

  return { name: name || path.basename(cwd), repoName };
}

// ---------------------------------------------------------------------------
// Build compact topic index (titles only, no content)
// ---------------------------------------------------------------------------

interface TopicEntry {
  filename: string;
  title: string;
  importance: number;
}

function buildTopicIndex(project: string): TopicEntry[] {
  const safeProject = project.replace(/[^a-zA-Z0-9_-]/g, "-");
  const projectsDir = path.join(CONFIG.MEMORY_DIR, "projects");

  if (!fs.existsSync(projectsDir)) return [];

  const topics: TopicEntry[] = [];

  try {
    const files = fs.readdirSync(projectsDir)
      .filter((f) => f.startsWith(`${safeProject}--`) && f.endsWith(".md"));

    for (const file of files) {
      try {
        const raw = fs.readFileSync(path.join(projectsDir, file), "utf8");
        const titleMatch = raw.match(/^title::\s*(.+)$/m);
        const impMatch = raw.match(/^importance::\s*(\d+)$/m);

        topics.push({
          filename: file,
          title: titleMatch ? titleMatch[1].trim() : file.replace(".md", ""),
          importance: impMatch ? parseInt(impMatch[1], 10) : 5,
        });
      } catch {}
    }

    // Sort by importance descending
    topics.sort((a, b) => b.importance - a.importance);
  } catch (e: any) {
    log("index", `Failed: ${e.message}`);
  }

  return topics.slice(0, CONFIG.MAX_TOPIC_TITLES);
}

// ---------------------------------------------------------------------------
// Count memories per category (cheap fs operation)
// ---------------------------------------------------------------------------

function countMemories(): Record<string, number> {
  const counts: Record<string, number> = {};
  const categories = [
    "api", "architecture", "auth", "config", "database",
    "infrastructure", "testing", "workflows",
  ];

  for (const cat of categories) {
    const dir = path.join(CONFIG.MEMORY_DIR, cat);
    try {
      if (fs.existsSync(dir)) {
        const n = fs.readdirSync(dir).filter((f) => f.endsWith(".md")).length;
        if (n > 0) counts[cat] = n;
      }
    } catch {}
  }

  return counts;
}

// ---------------------------------------------------------------------------
// Format the lean context injection
// ---------------------------------------------------------------------------

function formatLeanContext(
  project: string,
  topics: TopicEntry[],
  memoryCounts: Record<string, number>
): string | null {
  const totalMemories = Object.values(memoryCounts).reduce((a, b) => a + b, 0);

  if (topics.length === 0 && totalMemories === 0) return null;

  const lines: string[] = [];
  lines.push(`<memory_context>`);
  lines.push(`Project: ${project} | ${totalMemories} memories indexed (use qmd_search to fetch)`);

  if (topics.length > 0) {
    lines.push(`\nProject topics (use qmd_get to read full content):`);
    for (const t of topics) {
      lines.push(`- [${t.importance}] ${t.title}`);
    }
  }

  if (totalMemories > 0) {
    const summary = Object.entries(memoryCounts)
      .map(([cat, n]) => `${cat}:${n}`)
      .join(", ");
    lines.push(`\nMemory index: ${summary}`);
  }

  lines.push(`</memory_context>`);

  return lines.join("\n");
}

// ---------------------------------------------------------------------------
// Insight extraction (kept from v2 - this writes, doesn't bloat context)
// ---------------------------------------------------------------------------

function extractInsights(text: string): Array<{ title: string; content: string }> {
  const insights: Array<{ title: string; content: string }> = [];
  const pattern = /[★✦]\s*(?:Insight)\s*[-─—:]+\s*([^\n─]+)─*\n([\s\S]*?)─{5,}/gi;
  let match: RegExpExecArray | null;

  while ((match = pattern.exec(text)) !== null) {
    const title = match[1].trim().replace(/\s*─+$/, "").trim();
    const content = match[2].trim();
    if (content.length < 30) continue;
    insights.push({ title, content });
  }

  return insights;
}

function categorizeInsight(content: string): string {
  const lower = content.toLowerCase();
  if (/\b(api|endpoint|route|request|response|rest|graphql|grpc)\b/.test(lower)) return "api";
  if (/\b(architect|design|pattern|structure|layer|module|component)\b/.test(lower)) return "architecture";
  if (/\b(auth|token|jwt|oauth|session|permission|credential)\b/.test(lower)) return "auth";
  if (/\b(config|env|setting|variable|yaml|toml|dotenv)\b/.test(lower)) return "config";
  if (/\b(database|sql|query|migration|schema|table|index|postgres|mysql)\b/.test(lower)) return "database";
  if (/\b(deploy|docker|ci|cd|pipeline|infra|terraform|k8s|kubernetes)\b/.test(lower)) return "infrastructure";
  if (/\b(test|spec|assert|mock|fixture|coverage|jest|vitest|pytest)\b/.test(lower)) return "testing";
  return "workflows";
}

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

    const slug = title
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-|-$/g, "")
      .slice(0, 60);

    const filename = `${slug}.md`;
    const filepath = path.join(dir, filename);

    if (fs.existsSync(filepath)) return false;

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

// ---------------------------------------------------------------------------
// Session helpers
// ---------------------------------------------------------------------------

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

function saveSessionCheckpoint(
  messages: Array<{ role: string; content: string }>,
  project: string,
  repoName: string | null
): boolean {
  if (messages.length < 5) return false;

  try {
    const allText = messages.map((m) => m.content).join("\n");
    const files = new Set<string>();
    const filePattern = /(?:^|\s)([\w./\\-]+\.(?:ts|js|py|go|rs|yaml|yml|json|md|sql|tsx|jsx))\b/g;
    let match: RegExpExecArray | null;
    while ((match = filePattern.exec(allText)) !== null) {
      files.add(match[1]);
    }

    const topics = messages
      .filter((m) => m.role === "user")
      .map((m) => m.content.split("\n")[0].slice(0, 100))
      .filter((t) => t.length > 15)
      .slice(-5);

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
    log("checkpoint", `Saved: ${filename}`);
    return true;
  } catch (e: any) {
    log("checkpoint", `Failed: ${e.message}`);
    return false;
  }
}

// ---------------------------------------------------------------------------
// Extension entry point
// ---------------------------------------------------------------------------

export default function (pi: ExtensionAPI) {
  let pendingContext: string | null = null;
  let projectName: string | null = null;
  let repoName: string | null = null;

  // =========================================================================
  // 1. SESSION START - build compact topic index (no content fetching)
  // =========================================================================

  pi.on("session_start", async (_event, ctx) => {
    try {
      const cwd = ctx.cwd || process.cwd();
      const project = detectProject(cwd);
      projectName = project.name;
      repoName = project.repoName;

      log("start", `Project: ${projectName}, cwd: ${cwd}`);

      const topics = buildTopicIndex(projectName);
      const counts = countMemories();
      const formatted = formatLeanContext(projectName, topics, counts);

      if (formatted) {
        pendingContext = formatted;
        log("start", `Prepared lean index: ${formatted.length} chars, ${topics.length} topics`);
      } else {
        log("start", "No memories found");
      }
    } catch (e: any) {
      log("start", `Error: ${e.message}`);
    }
  });

  // =========================================================================
  // 2. BEFORE AGENT START - inject lean index
  // =========================================================================

  pi.on("before_agent_start", async (_event, _ctx) => {
    if (!pendingContext) return;

    try {
      pi.appendEntry("memory_context", {
        type: "project_context",
        content: pendingContext,
      });
      log("inject", `Injected lean index (${pendingContext.length} chars)`);
    } catch {
      try {
        pi.sendMessage(pendingContext!, { role: "system" });
      } catch {}
    }
    pendingContext = null;
  });

  // =========================================================================
  // 3. AGENT END - capture insight blocks (writes only, no context bloat)
  // =========================================================================

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
  // 4. SESSION BEFORE COMPACT - save checkpoint
  // =========================================================================

  pi.on("session_before_compact", async (_event, ctx) => {
    try {
      const messages = getSessionMessages(ctx);
      const project = projectName || "unknown";
      saveSessionCheckpoint(messages, project, repoName);
    } catch (e: any) {
      log("compact", `Error: ${e.message}`);
    }
  });

  // =========================================================================
  // 5. SESSION SHUTDOWN - spawn background summarizer
  // =========================================================================

  pi.on("session_shutdown", async (_event, ctx) => {
    try {
      let sessionFile: string | null = null;
      try {
        sessionFile = ctx.sessionManager.getSessionFile();
      } catch {}

      const sessionDir = ctx.sessionManager.getSessionDir();
      if (sessionDir?.includes("/teams/") || sessionFile?.includes("/teams/")) {
        log("shutdown", "Skipped team worker session");
        return;
      }

      const messages = getSessionMessages(ctx);
      if (messages.length < CONFIG.MIN_MESSAGES_FOR_SUMMARY) {
        log("shutdown", `Skipped (${messages.length} < ${CONFIG.MIN_MESSAGES_FOR_SUMMARY} messages)`);
        return;
      }

      if (!sessionFile || !fs.existsSync(sessionFile)) {
        log("shutdown", "No session file found");
        return;
      }

      const project = projectName || "unknown";
      const repo = repoName || "";

      if (!fs.existsSync(CONFIG.TEMP_DIR))
        fs.mkdirSync(CONFIG.TEMP_DIR, { recursive: true });

      // Extract only user/assistant text from session JSONL.
      // Raw JSONL includes tool calls, MCP metadata, binary content etc.
      // that bloats it to 400K+. The actual conversation text is usually <50K.
      const tempSession = path.join(CONFIG.TEMP_DIR, `session-${Date.now()}.txt`);
      const extracted = extractConversationText(sessionFile);
      if (!extracted || extracted.length < 100) {
        log("shutdown", "No meaningful conversation text extracted");
        return;
      }
      fs.writeFileSync(tempSession, extracted);
      log("shutdown", `Extracted ${(extracted.length / 1024).toFixed(0)}K conversation text from ${(fs.statSync(sessionFile).size / 1024).toFixed(0)}K session`);

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

      log("shutdown", `Spawned summarizer (pid: ${child.pid}, ${messages.length} messages)`);
    } catch (e: any) {
      log("shutdown", `Error: ${e.message}`);
    }
  });
}

// ---------------------------------------------------------------------------
// Session text extraction (JSONL -> plain conversation)
// ---------------------------------------------------------------------------

const MAX_EXTRACTED_CHARS = 50_000; // ~12K tokens, well within Sonnet's context

/**
 * Reads a session JSONL and extracts only user/assistant text content.
 * Drops tool calls, tool results, MCP metadata, thinking blocks, images etc.
 * This typically reduces a 400K+ JSONL to <50K of actual conversation.
 */
function extractConversationText(sessionFile: string): string | null {
  try {
    const raw = fs.readFileSync(sessionFile, "utf8");
    const lines: string[] = [];
    let totalChars = 0;

    for (const line of raw.split("\n")) {
      if (!line.trim()) continue;

      let entry: any;
      try {
        entry = JSON.parse(line);
      } catch {
        continue;
      }

      // Skip non-message entries (model changes, thinking level, custom, etc.)
      if (entry.type !== "human" && entry.type !== "assistant") continue;

      const message = entry.message;
      if (!message) continue;

      let text = "";

      if (typeof message.content === "string") {
        text = message.content;
      } else if (Array.isArray(message.content)) {
        // Only extract text blocks, skip tool_use, tool_result, image, etc.
        const textParts = message.content
          .filter((b: any) => b.type === "text" && b.text)
          .map((b: any) => b.text);
        text = textParts.join("\n");
      }

      if (!text || text.length < 10) continue;

      const role = entry.type === "human" ? "USER" : "ASSISTANT";
      const entry_text = `[${role}]: ${text}\n`;

      if (totalChars + entry_text.length > MAX_EXTRACTED_CHARS) {
        // Add what fits and stop
        lines.push(entry_text.slice(0, MAX_EXTRACTED_CHARS - totalChars));
        lines.push("\n[...truncated, session continues...]");
        break;
      }

      lines.push(entry_text);
      totalChars += entry_text.length;
    }

    return lines.length > 0 ? lines.join("\n") : null;
  } catch (e: any) {
    log("extract", `Failed: ${e.message}`);
    return null;
  }
}

// ---------------------------------------------------------------------------
// Background summarizer
// ---------------------------------------------------------------------------

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

EXISTING_SECTION=""
FILE_COUNT=0
for f in "$PROJECTS_DIR"/"\${SAFE_PROJECT}"--*.md; do
  [ -f "$f" ] || continue
  FILE_COUNT=$((FILE_COUNT + 1))
  BASENAME=$(basename "$f")
  BODY=$(awk 'BEGIN{found=0} /^$/{if(!found){found=1;next}} found{print}' "$f")
  EXISTING_SECTION="$EXISTING_SECTION
---
FILE: $BASENAME
CONTENT:
$BODY
"
done

log "Found $FILE_COUNT existing topic files for $SAFE_PROJECT"

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

RAW_RESPONSE=$(cat "$PROMPT_FILE" | pi -p --model "${model}" 2>/dev/null) || {
  log "pi -p failed (exit $?)"
  rm -f "$SESSION_FILE" "$PROMPT_FILE"
  exit 1
}

rm -f "$PROMPT_FILE"

JSON_RESPONSE=$(echo "$RAW_RESPONSE" | grep -Pzo '(?s)\{.*\}' | tr '\\0' '\\n')
if [ -z "$JSON_RESPONSE" ]; then
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

echo "$JSON_RESPONSE" | jq -c '.updates[]? // empty' 2>/dev/null | while IFS= read -r item; do
  FILENAME=$(echo "$item" | jq -r '.filename // empty')
  CONTENT=$(echo "$item" | jq -r '.content // empty')

  if [ -z "$FILENAME" ] || [ -z "$CONTENT" ] || [ \${#CONTENT} -lt 30 ]; then continue; fi

  case "$FILENAME" in
    "\${SAFE_PROJECT}"--*) ;;
    *) FILENAME="\${SAFE_PROJECT}--$FILENAME" ;;
  esac

  FILEPATH="$PROJECTS_DIR/$FILENAME"
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
done

echo "$JSON_RESPONSE" | jq -c '.creates[]? // empty' 2>/dev/null | while IFS= read -r item; do
  FILENAME=$(echo "$item" | jq -r '.filename // empty')
  CONTENT=$(echo "$item" | jq -r '.content // empty')

  if [ -z "$FILENAME" ] || [ -z "$CONTENT" ] || [ \${#CONTENT} -lt 30 ]; then continue; fi

  case "$FILENAME" in
    "\${SAFE_PROJECT}"--*) ;;
    *) FILENAME="\${SAFE_PROJECT}--$FILENAME" ;;
  esac

  FILEPATH="$PROJECTS_DIR/$FILENAME"
  if [ -f "$FILEPATH" ]; then
    log "Skipped create (exists): $FILENAME"
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
done

rm -f "$SESSION_FILE"
log "Done"
`;
}
