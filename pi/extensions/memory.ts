import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import * as fs from "fs";
import * as path from "path";
import * as http from "http";
import * as crypto from "crypto";
import { execSync } from "child_process";

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

const CONFIG = {
  BRIDGE_URL: "http://localhost:8021",
  OLLAMA_URL: "http://localhost:11434",
  OLLAMA_MODEL: "llama3.2:3b",
  BRIDGE_TIMEOUT: 15000,
  OLLAMA_TIMEOUT: 12000,
  MIN_SCORE: 0.3,
  PROJECT_MEMORY_LIMIT: 10,
  GLOBAL_PATTERN_LIMIT: 5,
  QUERY_LIMIT: 10,
  AUTO_SAVE_THRESHOLD: 0.65,
  DISCARD_THRESHOLD: 0.35,
  MAX_MEMORIES: 5,
  MIN_SESSION_MESSAGES: 5,
  QUEUE_DIR: path.join(process.env.HOME || "", ".forgetful", "queue"),
  EXPORT_DIR: path.join(process.env.HOME || "", ".forgetful", "transcripts"),
  LOG_FILE: "/tmp/forgetful-hooks.log",
};

// Skip patterns for user prompts that don't need memory lookup
const SKIP_PATTERNS = [
  /^\/\w+/,
  /^(hi|hello|hey|thanks|ok|yes|no|continue|go on|done|quit|exit)$/i,
  /^.{0,10}$/,
  /^\s*$/,
];

// Pattern extraction regexes for agent responses
const AGENT_PATTERNS: Record<string, RegExp[]> = {
  explanations: [
    /\bthe (?:issue|problem|bug) (?:is|was) (?:that\s+)?(.+?)\.(?:\s|$)/gi,
    /\bthis (?:happens|occurs|fails) because\s+(.+?)\.(?:\s|$)/gi,
    /\bthe root cause(?:\s+is)?:?\s*(.+?)\.(?:\s|$)/gi,
  ],
  solutions: [
    /\b(?:I\s+)?(?:fixed|resolved|solved|updated|changed)(?:\s+(?:this|it|the))?\s+(?:by\s+)?(.+?)\.(?:\s|$)/gi,
    /\bthe (?:fix|solution)(?:\s+is)?:?\s*(.+?)\.(?:\s|$)/gi,
    /\b(?:added|removed|updated|modified)\s+(.+?)\s+(?:to|from|in)\s+(.+?)\.(?:\s|$)/gi,
  ],
  architecture: [
    /\bthis (?:pattern|approach|design)\s+(.+?)\.(?:\s|$)/gi,
    /\bthe (?:better|correct|proper|right) (?:way|approach)(?:\s+is)?\s+(.+?)\.(?:\s|$)/gi,
  ],
  warnings: [
    /\b(?:note|important|careful|watch out|warning):?\s*(.+?)\.(?:\s|$)/gi,
    /\bthis (?:won't|doesn't|can't|will not) work (?:because|if|when|unless)\s+(.+?)\.(?:\s|$)/gi,
  ],
  failures: [
    /\bthis (?:didn't|doesn't|won't) work because\s+(.+?)\.(?:\s|$)/gi,
    /\b(?:tried|attempted)\s+(.+?)\s+but\s+(.+?)\.(?:\s|$)/gi,
  ],
  system: [
    /\b(\w+(?:\s+\w+)?)\s+(?:has|includes?|provides?|supports?)\s+(?:its own|a built-in)\s+(.+?)\.(?:\s|$)/gi,
  ],
};

// LLM extraction prompt (shared by compact + shutdown)
const EXTRACTION_PROMPT = `Extract knowledge worth remembering from this coding session. Return JSON array only.

Categories:
- decision: Technical choices with reasoning
- solution: Concrete fixes that could be reapplied
- pattern: Reusable techniques or approaches
- learning: New insights or gotchas discovered
- architecture: Design decisions or structural insights
- system: Facts about tools/systems being used
- failure: What didn't work and why
- preference: User preferences for future reference

Rules:
- ONLY extract information EXPLICITLY STATED in the session text
- Extract SPECIFIC knowledge - names, tools, configurations
- Each item must be self-contained
- Maximum 5 items
- Return empty array [] if nothing worth remembering

Format: [{"type": "<category>", "content": "<extracted text>"}]

Session text:
"""
{text}
"""

JSON:`;

// Type-specific scoring prompts
const SCORING_PROMPTS: Record<string, string> = {
  decision: `Score if this is a clear technical decision worth remembering (0.0-1.0). Only output the number.\nText: "{content}"\nScore:`,
  solution: `Score if this describes a concrete reapplyable solution (0.0-1.0). Only output the number.\nText: "{content}"\nScore:`,
  pattern: `Score if this describes a reusable technique (0.0-1.0). Only output the number.\nText: "{content}"\nScore:`,
  learning: `Score if this is a specific insight or gotcha (0.0-1.0). Only output the number.\nText: "{content}"\nScore:`,
  architecture: `Score if this describes a reusable architectural decision (0.0-1.0). Only output the number.\nText: "{content}"\nScore:`,
  system: `Score if this is a useful fact about a tool or system (0.0-1.0). Only output the number.\nText: "{content}"\nScore:`,
  failure: `Score if this describes what didn't work and why (0.0-1.0). Only output the number.\nText: "{content}"\nScore:`,
  preference: `Score if this is a clear user preference (0.0-1.0). Only output the number.\nText: "{content}"\nScore:`,
};

const DEFAULT_SCORING_PROMPT = `Score if this is valuable technical knowledge (0.0-1.0). Only output the number.\nText: "{content}"\nScore:`;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function log(tag: string, msg: string) {
  try {
    fs.appendFileSync(
      CONFIG.LOG_FILE,
      `${new Date().toISOString()} [pi:${tag}] ${msg}\n`
    );
  } catch {}
}

function httpPost(
  urlString: string,
  body: unknown,
  timeout = CONFIG.BRIDGE_TIMEOUT
): Promise<any> {
  return new Promise((resolve) => {
    const postData = JSON.stringify(body);
    const url = new URL(urlString);

    const options: http.RequestOptions = {
      hostname: url.hostname,
      port: url.port,
      path: url.pathname,
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Content-Length": Buffer.byteLength(postData),
      },
      timeout,
    };

    const req = http.request(options, (res) => {
      let data = "";
      res.on("data", (chunk) => (data += chunk));
      res.on("end", () => {
        try {
          resolve(JSON.parse(data));
        } catch {
          resolve(null);
        }
      });
    });

    req.on("error", () => resolve(null));
    req.on("timeout", () => {
      req.destroy();
      resolve(null);
    });
    req.write(postData);
    req.end();
  });
}

function detectProject(cwd: string): {
  name: string;
  forgetfulId: number | null;
  repoName: string | null;
} {
  let name: string | null = null;
  let forgetfulId: number | null = null;
  let repoName: string | null = null;

  // Priority 1: .forgetful/project.json
  try {
    const fp = path.join(cwd, ".forgetful", "project.json");
    if (fs.existsSync(fp)) {
      const proj = JSON.parse(fs.readFileSync(fp, "utf8"));
      if (proj.name) name = proj.name;
      if (proj.forgetful_id) forgetfulId = proj.forgetful_id;
      if (proj.repo_name) repoName = proj.repo_name;
    }
  } catch {}

  // Priority 2: git remote
  if (!repoName) {
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
          if (!name) name = repoName.split("/").pop() || null;
        }
      }
    } catch {}
  }

  // Priority 3: package.json
  if (!name) {
    try {
      const pkgPath = path.join(cwd, "package.json");
      if (fs.existsSync(pkgPath)) {
        const pkg = JSON.parse(fs.readFileSync(pkgPath, "utf8"));
        if (pkg.name) name = pkg.name;
      }
    } catch {}
  }

  return {
    name: name || path.basename(cwd),
    forgetfulId,
    repoName,
  };
}

function loadLocalContext(cwd: string): {
  overview: string | null;
  decisions: string | null;
} {
  let overview: string | null = null;
  let decisions: string | null = null;

  try {
    const p = path.join(cwd, ".forgetful", "context.md");
    if (fs.existsSync(p)) overview = fs.readFileSync(p, "utf8").trim();
  } catch {}

  try {
    const p = path.join(cwd, ".forgetful", "decisions.md");
    if (fs.existsSync(p)) decisions = fs.readFileSync(p, "utf8").trim();
  } catch {}

  return { overview, decisions };
}

function cleanText(text: string): string {
  return text
    .replace(/<system-reminder>[\s\S]*?<\/system-reminder>/gi, "")
    .replace(/```[\s\S]*?```/g, "")
    .replace(/^\|.*$/gm, "")
    .replace(/https?:\/\/\S+/g, "")
    .replace(/<[^>]+>/g, "")
    .trim();
}

function hashContent(content: string): string {
  return crypto.createHash("md5").update(content).digest("hex");
}

function shouldSkip(prompt: string): boolean {
  if (!prompt || typeof prompt !== "string") return true;
  return SKIP_PATTERNS.some((p) => p.test(prompt.trim()));
}

// ---------------------------------------------------------------------------
// Bridge API helpers
// ---------------------------------------------------------------------------

async function bridgeRecall(
  query: string,
  limit: number,
  projectId?: number | null
): Promise<any[]> {
  const body: any = { query, limit };
  if (projectId) body.current_project_id = projectId;
  const result = await httpPost(`${CONFIG.BRIDGE_URL}/recall`, body);
  return Array.isArray(result) ? result : [];
}

async function bridgeBatchRecall(
  queries: Array<{ query: string; limit: number }>,
  projectId?: number | null
): Promise<any[][]> {
  const body: any = { queries, current_project_id: projectId || null };
  const result = await httpPost(
    `${CONFIG.BRIDGE_URL}/recall/batch`,
    body,
    CONFIG.BRIDGE_TIMEOUT
  );
  return Array.isArray(result) ? result : queries.map(() => []);
}

async function bridgeEnsureProject(
  name: string,
  repoName?: string | null
): Promise<number | null> {
  const body: any = { name };
  if (repoName) body.repo_name = repoName;
  const result = await httpPost(`${CONFIG.BRIDGE_URL}/project/ensure`, body);
  return result?.id || null;
}

async function bridgeStore(memory: any, projectIds?: number[]): Promise<any> {
  const body: any = {
    title: memory.title,
    content: memory.content,
    context: memory.context || "Auto-extracted by pi memory extension",
    tags: memory.tags,
    keywords: memory.keywords,
    importance: memory.importance,
  };
  if (projectIds?.length) body.project_ids = projectIds;
  return httpPost(`${CONFIG.BRIDGE_URL}/store`, body);
}

async function bridgeCheckDuplicate(content: string): Promise<boolean> {
  const result = await httpPost(`${CONFIG.BRIDGE_URL}/check-duplicate`, {
    content,
    threshold: 0.85,
  });
  return result?.isDuplicate === true;
}

async function bridgeLink(
  memoryId: number,
  relatedIds: number[]
): Promise<void> {
  await httpPost(`${CONFIG.BRIDGE_URL}/link`, {
    memory_id: memoryId,
    related_ids: relatedIds,
  });
}

// ---------------------------------------------------------------------------
// Ollama helpers (for extraction + scoring)
// ---------------------------------------------------------------------------

async function ollamaGenerate(
  prompt: string,
  maxTokens = 2000,
  timeout = CONFIG.OLLAMA_TIMEOUT
): Promise<string | null> {
  const result = await httpPost(
    `${CONFIG.OLLAMA_URL}/api/generate`,
    {
      model: CONFIG.OLLAMA_MODEL,
      prompt,
      stream: false,
      options: { temperature: 0.3, num_predict: maxTokens },
    },
    timeout
  );
  return result?.response?.trim() || null;
}

async function extractWithLLM(
  text: string,
  sessionText: string
): Promise<Array<{ type: string; content: string }>> {
  const prompt = EXTRACTION_PROMPT.replace("{text}", text.slice(0, 4000));
  const response = await ollamaGenerate(prompt, 2500, CONFIG.OLLAMA_TIMEOUT * 2);
  if (!response) return [];

  let parsed: any[] | null = null;

  // Try direct parse
  const jsonMatch = response.match(/\[[\s\S]*\]/);
  if (jsonMatch) {
    try {
      parsed = JSON.parse(jsonMatch[0]);
    } catch {}
  }

  // Try repairing truncated JSON
  if (!parsed) {
    const start = response.indexOf("[");
    if (start >= 0) {
      const truncated = response.slice(start);
      const lastBrace = truncated.lastIndexOf("}");
      if (lastBrace > 0) {
        try {
          parsed = JSON.parse(truncated.slice(0, lastBrace + 1) + "]");
        } catch {}
      }
    }
  }

  if (!Array.isArray(parsed)) return [];

  // Filter valid items
  const valid = parsed.filter(
    (item) =>
      item.type &&
      item.content &&
      typeof item.content === "string" &&
      item.content.length >= 20
  );

  // Grounding check - reject hallucinated content
  return valid.filter((item) => {
    const words = item.content
      .toLowerCase()
      .replace(/[^a-z0-9\s]/g, " ")
      .split(/\s+/)
      .filter((w: string) => w.length >= 4);
    if (words.length === 0) return true;
    const sessionLower = sessionText.toLowerCase();
    const found = words.filter((w: string) => sessionLower.includes(w));
    return found.length / words.length >= 0.5;
  });
}

async function scoreCandidate(
  content: string,
  type: string
): Promise<number> {
  const template = SCORING_PROMPTS[type] || DEFAULT_SCORING_PROMPT;
  const prompt = template.replace("{content}", content.slice(0, 200));
  const response = await ollamaGenerate(prompt, 10, 5000);
  if (!response) return 0.5;

  const match = response.match(/([0-9]*\.?[0-9]+)/);
  if (match) {
    const score = parseFloat(match[1]);
    return isNaN(score) ? 0.5 : Math.max(0, Math.min(1, score));
  }
  return 0.5;
}

// ---------------------------------------------------------------------------
// Formatting
// ---------------------------------------------------------------------------

function formatMemorySection(title: string, memories: any[]): string {
  const filtered = memories.filter((m) => (m.score || 0) >= CONFIG.MIN_SCORE);
  if (filtered.length === 0) return "";

  let output = `### ${title}\n`;
  for (const mem of filtered) {
    const score = (mem.score || 0).toFixed(2);
    output += `- **[${score}] ${mem.title || "Untitled"}**\n`;
    if (mem.tags?.length) output += `  Tags: ${mem.tags.join(", ")}\n`;
    output += `  ${mem.content || ""}\n\n`;
  }
  return output;
}

function formatProjectContext(
  project: string,
  projectMemories: any[],
  globalPatterns: any[],
  localContext: { overview: string | null; decisions: string | null }
): string | null {
  const hasPM = projectMemories.some((m) => (m.score || 0) >= CONFIG.MIN_SCORE);
  const hasGP = globalPatterns.some((m) => (m.score || 0) >= CONFIG.MIN_SCORE);
  const hasLocal = localContext.overview || localContext.decisions;

  if (!hasPM && !hasGP && !hasLocal) return null;

  let output = `<project_context>\n## Project: ${project}\n\n`;
  if (localContext.overview)
    output += `### Project Overview\n${localContext.overview}\n\n`;
  if (localContext.decisions)
    output += `### Local Decisions Log\n${localContext.decisions}\n\n`;
  output += formatMemorySection("Key Decisions & Architecture", projectMemories);
  output += formatMemorySection("Relevant Patterns", globalPatterns);
  output += `---\nThis context was loaded automatically at session start.\n</project_context>`;
  return output;
}

function formatRecallResults(memories: any[]): string | null {
  const filtered = memories.filter((m) => (m.score || 0) >= CONFIG.MIN_SCORE);
  if (filtered.length === 0) return null;

  let output =
    "<memory_context>\n## Relevant Knowledge from Memory\n\n";
  for (const mem of filtered.slice(0, 8)) {
    const score = (mem.score || 0).toFixed(2);
    output += `- **[${score}] ${mem.title || "Untitled"}**\n  ${
      (mem.content || "").slice(0, 150)
    }\n\n`;
  }
  output +=
    "---\n*Use this context to inform your approach.*\n</memory_context>";
  return output;
}

// ---------------------------------------------------------------------------
// Pattern extraction (from agent responses)
// ---------------------------------------------------------------------------

function extractPatterns(
  text: string
): Array<{ type: string; content: string }> {
  const candidates: Array<{ type: string; content: string }> = [];

  for (const [type, patterns] of Object.entries(AGENT_PATTERNS)) {
    for (const pattern of patterns) {
      const regex = new RegExp(pattern.source, pattern.flags);
      let match: RegExpExecArray | null;
      while ((match = regex.exec(text)) !== null) {
        const extracted = match
          .slice(1)
          .filter(Boolean)
          .join(" - ");
        if (extracted && extracted.length >= 20 && extracted.length < 500) {
          candidates.push({ type, content: extracted.trim() });
        }
      }
    }
  }

  // Deduplicate
  const seen = new Set<string>();
  return candidates
    .filter((c) => {
      if (seen.has(c.content)) return false;
      seen.add(c.content);
      return true;
    })
    .slice(0, 5);
}

// ---------------------------------------------------------------------------
// Queue management (for pattern extraction -> session end pipeline)
// ---------------------------------------------------------------------------

function queueCandidates(
  candidates: Array<{ type: string; content: string }>,
  sessionId: string,
  project: string
) {
  if (candidates.length === 0) return;
  try {
    if (!fs.existsSync(CONFIG.QUEUE_DIR))
      fs.mkdirSync(CONFIG.QUEUE_DIR, { recursive: true });

    const queueFile = path.join(CONFIG.QUEUE_DIR, `${sessionId}.jsonl`);
    const lines = candidates
      .map((c) =>
        JSON.stringify({ ...c, project, queued_at: new Date().toISOString() })
      )
      .join("\n") + "\n";

    fs.appendFileSync(queueFile, lines);
    log("queue", `Queued ${candidates.length} candidates`);
  } catch (e: any) {
    log("queue", `Failed: ${e.message}`);
  }
}

function readQueue(sessionId: string): Array<{ type: string; content: string; project?: string }> {
  const queueFile = path.join(CONFIG.QUEUE_DIR, `${sessionId}.jsonl`);
  if (!fs.existsSync(queueFile)) return [];
  try {
    return fs
      .readFileSync(queueFile, "utf8")
      .trim()
      .split("\n")
      .filter((l) => l.trim())
      .map((l) => { try { return JSON.parse(l); } catch { return null; } })
      .filter(Boolean);
  } catch {
    return [];
  }
}

function cleanupQueue(sessionId: string) {
  try {
    const f = path.join(CONFIG.QUEUE_DIR, `${sessionId}.jsonl`);
    if (fs.existsSync(f)) fs.unlinkSync(f);
  } catch {}
}

// ---------------------------------------------------------------------------
// Transcript export
// ---------------------------------------------------------------------------

function exportSessionAsMarkdown(
  messages: Array<{ role: string; content: string }>,
  sessionId: string,
  reason: string
): string | null {
  try {
    if (!fs.existsSync(CONFIG.EXPORT_DIR))
      fs.mkdirSync(CONFIG.EXPORT_DIR, { recursive: true });

    const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
    const exportPath = path.join(
      CONFIG.EXPORT_DIR,
      `${sessionId}-${reason}-${timestamp}.md`
    );

    let md = `# Session Transcript (${reason})\n\n`;
    md += `- Session ID: ${sessionId}\n`;
    md += `- Exported at: ${new Date().toISOString()}\n\n---\n\n`;

    for (const msg of messages) {
      const role = msg.role === "user" ? "User" : "Assistant";
      md += `## ${role}\n\n${msg.content}\n\n`;
    }

    fs.writeFileSync(exportPath, md);
    log("export", `Exported transcript to ${exportPath}`);
    return exportPath;
  } catch (e: any) {
    log("export", `Failed: ${e.message}`);
    return null;
  }
}

// ---------------------------------------------------------------------------
// Save pipeline (used by compact + shutdown)
// ---------------------------------------------------------------------------

async function savePipeline(
  memories: Array<{
    title: string;
    content: string;
    tags: string[];
    keywords: string[];
    confidence: number;
    importance: number;
  }>,
  projectIds: number[],
  cwd: string
) {
  const high = memories.filter((m) => m.confidence >= CONFIG.AUTO_SAVE_THRESHOLD);
  const low = memories.filter(
    (m) =>
      m.confidence >= CONFIG.DISCARD_THRESHOLD &&
      m.confidence < CONFIG.AUTO_SAVE_THRESHOLD
  );

  let saved = 0;
  let dupes = 0;

  for (const memory of high) {
    const isDupe = await bridgeCheckDuplicate(memory.content);
    if (isDupe) {
      dupes++;
      continue;
    }

    const result = await bridgeStore(
      {
        ...memory,
        context: `Auto-extracted (confidence: ${memory.confidence.toFixed(2)})`,
      },
      projectIds
    );

    if (result && result.success !== false) {
      saved++;
      if (result.id) {
        const related = await bridgeRecall(memory.content, 3);
        const relatedIds = related
          .filter((m) => m.id !== result.id && m.score > 0.5)
          .map((m) => m.id);
        if (relatedIds.length > 0) await bridgeLink(result.id, relatedIds);
      }
    }
  }

  // Queue low-confidence for review
  if (low.length > 0) {
    const pendingDir = path.join(cwd, ".forgetful", "pending");
    try {
      if (!fs.existsSync(pendingDir))
        fs.mkdirSync(pendingDir, { recursive: true });
      const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
      fs.writeFileSync(
        path.join(pendingDir, `pending-${timestamp}.json`),
        JSON.stringify(
          {
            extracted_at: new Date().toISOString(),
            memories: low.map((m) => ({
              ...m,
              status: "pending_review",
              reason: `Confidence ${m.confidence.toFixed(2)} below ${CONFIG.AUTO_SAVE_THRESHOLD}`,
            })),
          },
          null,
          2
        )
      );
    } catch (e: any) {
      log("save", `Failed to write pending: ${e.message}`);
    }
  }

  log(
    "save",
    `Saved ${saved}/${high.length} (${dupes} dupes), queued ${low.length} for review`
  );
}

// ---------------------------------------------------------------------------
// Full extraction pipeline (compact + shutdown share this)
// ---------------------------------------------------------------------------

async function runExtractionPipeline(
  messages: Array<{ role: string; content: string }>,
  cwd: string,
  sessionId: string,
  reason: string
) {
  const userText = cleanText(
    messages
      .filter((m) => m.role === "user")
      .map((m) => m.content)
      .join("\n\n")
  );
  const agentText = cleanText(
    messages
      .filter((m) => m.role === "assistant")
      .slice(-3)
      .map((m) => m.content)
      .join("\n\n")
  );
  const combinedText = `USER:\n${userText}\n\nASSISTANT:\n${agentText}`;

  if (combinedText.length < 200) {
    log(reason, `Text too short: ${combinedText.length} chars`);
    return;
  }

  const { name: projectName, forgetfulId, repoName } = detectProject(cwd);
  let projectId = forgetfulId;
  if (!projectId) {
    projectId = await bridgeEnsureProject(projectName, repoName);
  }
  const projectIds = projectId ? [projectId] : [];

  log(reason, `Extracting from ${combinedText.length} chars for ${projectName}`);
  const extractions = await extractWithLLM(combinedText, combinedText);
  log(reason, `Extracted ${extractions.length} items`);

  // Process queued candidates from agent_end
  const queued = readQueue(sessionId);

  if (extractions.length === 0 && queued.length === 0) {
    cleanupQueue(sessionId);
    return;
  }

  // Score all extractions
  const allMemories = [];

  for (const item of extractions.slice(0, CONFIG.MAX_MEMORIES)) {
    const score = await scoreCandidate(item.content, item.type);
    allMemories.push({
      title: `${item.type.charAt(0).toUpperCase() + item.type.slice(1)}: ${item.content.slice(0, 55)}...`,
      content: `**${item.type.charAt(0).toUpperCase() + item.type.slice(1)}:** ${item.content}`,
      tags: [projectName, item.type, `${reason}-extracted`],
      keywords: [item.type, projectName],
      confidence: score,
      importance: item.type === "decision" || item.type === "solution" ? 7 : 6,
    });
  }

  // Score queued candidates
  const typeMap: Record<string, { tag: string; label: string; importance: number; scoringKey: string }> = {
    explanations: { tag: "root-cause", label: "Root Cause", importance: 7, scoringKey: "solution" },
    solutions: { tag: "solution", label: "Solution", importance: 7, scoringKey: "solution" },
    architecture: { tag: "architecture", label: "Architecture", importance: 6, scoringKey: "architecture" },
    warnings: { tag: "gotcha", label: "Gotcha", importance: 6, scoringKey: "learning" },
    failures: { tag: "failure", label: "Failure", importance: 7, scoringKey: "failure" },
    system: { tag: "system", label: "System", importance: 6, scoringKey: "system" },
  };

  const seenContent = new Set(allMemories.map((m) => m.content));
  for (const candidate of queued) {
    if (seenContent.has(candidate.content)) continue;
    seenContent.add(candidate.content);

    const meta = typeMap[candidate.type] || {
      tag: "insight",
      label: "Insight",
      importance: 5,
      scoringKey: "learning",
    };
    const score = await scoreCandidate(candidate.content, meta.scoringKey);
    allMemories.push({
      title: `${meta.label}: ${candidate.content.slice(0, 55)}...`,
      content: `**${meta.label}:** ${candidate.content}`,
      tags: [projectName, meta.tag, "agent-extracted"],
      keywords: [meta.tag, projectName],
      confidence: score,
      importance: meta.importance,
    });
  }

  await savePipeline(allMemories.slice(0, 10), projectIds, cwd);
  cleanupQueue(sessionId);
}

// ---------------------------------------------------------------------------
// Read session messages from pi's session manager
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

function getSessionId(ctx: any): string {
  try {
    const file = ctx.sessionManager.getSessionFile();
    if (file) return path.basename(file, path.extname(file));
  } catch {}
  return `pi-${Date.now()}`;
}

// ---------------------------------------------------------------------------
// Extension entry point
// ---------------------------------------------------------------------------

export default function (pi: ExtensionAPI) {
  // Extension state
  let projectName: string | null = null;
  let projectId: number | null = null;
  let pendingContext: string | null = null;
  let lastInputHash: string | null = null;

  // =========================================================================
  // 1. SESSION START - detect project, query bridge for context
  // =========================================================================

  pi.on("session_start", async (_event, ctx) => {
    try {
      const cwd = ctx.cwd || process.cwd();
      const project = detectProject(cwd);
      projectName = project.name;
      projectId = project.forgetfulId;

      log("start", `Project: ${projectName}, cwd: ${cwd}`);

      // Run project ensure + batch recall in parallel to cut latency
      const ensurePromise = !projectId
        ? bridgeEnsureProject(projectName, project.repoName)
        : Promise.resolve(projectId);

      const recallPromise = bridgeBatchRecall(
        [
          { query: `${projectName} project architecture`, limit: CONFIG.PROJECT_MEMORY_LIMIT },
          { query: "global patterns conventions best practices", limit: CONFIG.GLOBAL_PATTERN_LIMIT },
        ],
        projectId // may be null on first run, that's OK - bridge handles it
      );

      const [resolvedId, batchResults] = await Promise.all([
        ensurePromise,
        recallPromise,
      ]);

      if (resolvedId) {
        projectId = resolvedId;
        log("start", `Resolved project ID: ${projectId}`);
      }

      const [projectMemories, globalPatterns] = batchResults;

      // Load local .forgetful/ files
      const localContext = loadLocalContext(cwd);

      // Format and store for injection
      const formatted = formatProjectContext(
        projectName,
        projectMemories,
        globalPatterns,
        localContext
      );

      if (formatted) {
        pendingContext = formatted;
        log("start", `Prepared context for ${projectName}`);
      } else {
        log("start", "No context to inject");
      }
    } catch (e: any) {
      log("start", `Error: ${e.message}`);
    }
  });

  // =========================================================================
  // 2. BEFORE AGENT START - inject session context
  // =========================================================================

  pi.on("before_agent_start", async (_event, _ctx) => {
    if (!pendingContext) return;

    try {
      // Inject project context as a system entry
      pi.appendEntry("memory_context", {
        type: "project_context",
        content: pendingContext,
      });
      log("inject", "Injected project context");
      pendingContext = null;
    } catch (e: any) {
      // Fallback: send as message
      try {
        pi.sendMessage(pendingContext!, { role: "system" });
        log("inject", "Injected via sendMessage fallback");
      } catch (e2: any) {
        log("inject", `Failed to inject: ${e.message}, ${e2.message}`);
      }
      pendingContext = null;
    }
  });

  // =========================================================================
  // 3. INPUT - query bridge with user prompt, inject relevant memories
  // =========================================================================

  pi.on("input", async (event, ctx) => {
    try {
      const userPrompt = event.text;
      if (!userPrompt || shouldSkip(userPrompt)) {
        return { action: "continue" };
      }

      // Hash check to avoid duplicate queries
      const hash = hashContent(userPrompt);
      if (hash === lastInputHash) return { action: "continue" };
      lastInputHash = hash;

      log("input", `Query: ${userPrompt.slice(0, 60)}`);

      // Query bridge for relevant memories
      const results = await bridgeRecall(
        userPrompt,
        CONFIG.QUERY_LIMIT,
        projectId
      );

      if (!results || results.length === 0) {
        return { action: "continue" };
      }

      log("input", `Got ${results.length} results`);

      const formatted = formatRecallResults(results);
      if (!formatted) return { action: "continue" };

      // Inject memory context
      try {
        pi.appendEntry("memory_context", {
          type: "recall",
          content: formatted,
        });
      } catch {
        try {
          pi.sendMessage(formatted, { role: "system" });
        } catch {}
      }

      log("input", "Injected recall results");
    } catch (e: any) {
      log("input", `Error: ${e.message}`);
    }

    return { action: "continue" };
  });

  // =========================================================================
  // 4. AGENT END - extract patterns from last response, queue for later
  // =========================================================================

  pi.on("agent_end", async (_event, ctx) => {
    try {
      const messages = getSessionMessages(ctx);
      if (messages.length === 0) return;

      // Get last assistant message
      const lastAssistant = messages
        .filter((m) => m.role === "assistant")
        .pop();
      if (!lastAssistant || lastAssistant.content.length < 50) return;

      const cleaned = cleanText(lastAssistant.content);
      const candidates = extractPatterns(cleaned);

      if (candidates.length > 0) {
        const sessionId = getSessionId(ctx);
        const cwd = ctx.cwd || process.cwd();
        const project = projectName || path.basename(cwd);
        queueCandidates(candidates, sessionId, project);
        log("agent-end", `Queued ${candidates.length} candidates`);
      }
    } catch (e: any) {
      log("agent-end", `Error: ${e.message}`);
    }
  });

  // =========================================================================
  // 5. SESSION BEFORE COMPACT - export transcript, extract + save memories
  // =========================================================================

  pi.on("session_before_compact", async (_event, ctx) => {
    const COMPACT_TIMEOUT = 25000;
    const done = new Promise<void>((resolve) => {
      setTimeout(() => {
        log("compact", "Timeout - aborting extraction");
        resolve();
      }, COMPACT_TIMEOUT);
    });

    const work = (async () => {
      try {
        const cwd = ctx.cwd || process.cwd();
        const sessionId = getSessionId(ctx);
        const messages = getSessionMessages(ctx);

        log("compact", `Processing ${messages.length} messages`);

        // Export transcript
        exportSessionAsMarkdown(messages, sessionId, "compact");

        // Run extraction pipeline
        if (messages.length >= CONFIG.MIN_SESSION_MESSAGES) {
          await runExtractionPipeline(messages, cwd, sessionId, "compact");
        }
      } catch (e: any) {
        log("compact", `Error: ${e.message}`);
      }
    })();

    await Promise.race([work, done]);
    log("compact", "Done");
  });

  // =========================================================================
  // 6. SESSION SHUTDOWN - export transcript, extract + save, process queue
  // =========================================================================

  pi.on("session_shutdown", async (_event, ctx) => {
    // Hard timeout - never block session exit
    const SHUTDOWN_TIMEOUT = 20000;
    const done = new Promise<void>((resolve) => {
      setTimeout(() => {
        log("shutdown", "Timeout - aborting extraction");
        resolve();
      }, SHUTDOWN_TIMEOUT);
    });

    const work = (async () => {
      try {
        const cwd = ctx.cwd || process.cwd();
        const sessionId = getSessionId(ctx);
        const messages = getSessionMessages(ctx);

        log("shutdown", `Processing ${messages.length} messages`);

        // Export transcript (fast, local I/O only)
        exportSessionAsMarkdown(messages, sessionId, "end");

        // Run extraction pipeline (slow, involves Ollama)
        if (messages.length >= CONFIG.MIN_SESSION_MESSAGES) {
          await runExtractionPipeline(messages, cwd, sessionId, "shutdown");
        }
      } catch (e: any) {
        log("shutdown", `Error: ${e.message}`);
      }
    })();

    // Race: finish work or timeout, whichever comes first
    await Promise.race([work, done]);
    log("shutdown", "Done");
  });
}
