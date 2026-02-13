---
description: Check project progress, show context, and route to next action
model: claude-sonnet-4-5-20250929
thinking: low
---

Check project progress and provide situational awareness.

## Process

1. **Verify planning structure exists:**
   ```bash
   test -d .planning && echo "exists" || echo "missing"
   ```
   If no `.planning/` directory: suggest running `/skill:gsd-new-project`.

2. **Load full project context:**
   - Read `.planning/STATE.md` for living memory (position, decisions, issues)
   - Read `.planning/ROADMAP.md` for phase structure and objectives
   - Read `.planning/PROJECT.md` for current state
   - Read `.planning/config.json` for settings

3. **Gather recent work context:**
   - Find the 2-3 most recent SUMMARY.md files
   - Extract what was accomplished, key decisions, any issues

4. **Parse current position:**
   - From STATE.md: current phase, plan number, status
   - Calculate: total plans, completed plans, remaining plans
   - Note any blockers or concerns
   - Count pending todos: `ls .planning/todos/pending/*.md 2>/dev/null | wc -l`

5. **Present status report:**

```
# [Project Name]

**Progress:** [visual bar] X/Y plans complete
**Profile:** [quality/balanced/budget]

## Recent Work
- [Phase X, Plan Y]: [what was accomplished]

## Current Position
Phase [N] of [total]: [phase-name]
Plan [M] of [phase-total]: [status]

## Key Decisions Made
- [decisions from STATE.md]

## Blockers/Concerns
- [any blockers]

## What's Next
[Next phase/plan objective from ROADMAP]
```

6. **Route to next action:**
   - If unexecuted plans exist: suggest `/gsd:execute-phase {phase}`
   - If phase needs planning: suggest `/gsd:plan-phase {phase}`
   - If phase complete, more remain: suggest next phase
   - If all phases complete: suggest milestone completion

$ARGUMENTS
