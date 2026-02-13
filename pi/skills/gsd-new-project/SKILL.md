---
name: gsd-new-project
description: "Initialize a new project with .planning/ directory, PROJECT.md, ROADMAP.md, and phase breakdown."
metadata:
  preferred-model: claude-opus-4-6
---

# GSD: New Project

Initialize a new project through: questioning -> research (optional) -> requirements -> roadmap.

## Creates:
- `.planning/PROJECT.md` - project context
- `.planning/config.json` - workflow preferences
- `.planning/research/` - domain research (optional)
- `.planning/REQUIREMENTS.md` - scoped requirements
- `.planning/ROADMAP.md` - phase structure
- `.planning/STATE.md` - project memory

**After this command:** Run `/gsd-progress` to see next steps.

## Phase 1: Setup

1. **Abort if project exists:**
   ```bash
   [ -f .planning/PROJECT.md ] && echo "ERROR: Project already initialized. Use /gsd-progress" && exit 1
   ```

2. **Initialize git repo** if none exists in current directory.

3. **Detect existing code (brownfield):**
   Check for source files (*.ts, *.js, *.py, etc.) and manifest files (package.json, etc.).
   If code exists, offer to analyze the codebase first or skip.

## Phase 2: Deep Questioning

Ask: "What do you want to build?"

Follow the thread with probing questions:
- What excited them, what problem sparked this
- What they mean by vague terms
- What's already decided vs open
- Surface assumptions, find edges, reveal motivation

When you could write a clear PROJECT.md, ask if they're ready to proceed or want to explore more.

## Phase 3: Write PROJECT.md

Synthesize all context into `.planning/PROJECT.md`:
- What This Is (1-2 sentences)
- Core Value (the ONE thing that must work)
- Constraints
- Key Decisions (from questioning)
- Requirements (categorized as Validated/Active/Out of Scope)

Commit: `docs: initialize project`

## Phase 4: Workflow Preferences

Ask about:
- **Mode**: YOLO (auto-approve) vs Interactive (confirm each step)
- **Depth**: Quick (3-5 phases) / Standard (5-8) / Comprehensive (8-12)
- **Git tracking**: Commit planning docs or keep local-only

Create `.planning/config.json` with settings.
Commit: `chore: add project config`

## Phase 5: Research (Optional)

Offer domain research before defining requirements.

If research selected, sequentially research:
1. **Stack** - standard tech stack for this domain
2. **Features** - table stakes vs differentiators
3. **Architecture** - component boundaries, data flow
4. **Pitfalls** - common mistakes and prevention

Write each to `.planning/research/` and create a SUMMARY.md.

Use Serena MCP for codebase analysis and Context7 MCP for framework docs where relevant.

## Phase 6: Define Requirements

Present features by category (from research or conversation).
For each category, ask which features are in v1 vs deferred.

Generate `.planning/REQUIREMENTS.md` with:
- v1 Requirements with REQ-IDs (AUTH-01, CONTENT-02, etc.)
- v2 Requirements (deferred)
- Out of Scope (explicit exclusions)
- Traceability section

Requirements must be specific and testable, user-centric, and atomic.

Commit: `docs: define v1 requirements`

## Phase 7: Create Roadmap

Create `.planning/ROADMAP.md`:
1. Derive phases from requirements (don't impose structure)
2. Map every v1 requirement to exactly one phase
3. Derive 2-5 success criteria per phase (observable user behaviors)
4. Validate 100% coverage

Also create `.planning/STATE.md` with initial state.

Present roadmap for approval. Iterate if user wants adjustments.

Commit: `docs: create roadmap (N phases)`

## Phase 8: Done

Present completion summary with artifact locations and next steps.
Suggest: `/gsd-progress` to check status, or start planning Phase 1.
