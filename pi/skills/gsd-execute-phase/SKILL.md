---
name: gsd-execute-phase
description: "Execute all tasks in a phase plan with atomic commits and state tracking."
metadata:
  preferred-model: claude-opus-4-6
---

# GSD: Execute Phase

Execute all plans in a phase sequentially with atomic commits per task.

## Arguments

Phase number (integer or decimal). Required.

Flags:
- `--gaps-only` - execute only gap closure plans

## Process

### 1. Validate
- Find phase directory matching argument
- Count PLAN.md files
- Check which have SUMMARY.md (already complete)
- If `--gaps-only`: filter to plans with `gap_closure: true`
- Build list of incomplete plans
- Error if no plans found

### 2. Group by Wave
- Read `wave` from each plan's frontmatter
- Group plans by wave number
- Report wave structure

### 3. Execute Waves
For each wave in order, for each plan in the wave:

1. Read the PLAN.md
2. Execute each task sequentially
3. After each task:
   - Stage only files modified by that task (never `git add .`)
   - Commit with format: `{type}({phase}-{plan}): {task-name}`
   - Types: feat, fix, test, refactor, perf, chore
   - Record commit hash
4. After all tasks in plan:
   - Create SUMMARY.md with what was accomplished, commit hashes, any deviations
   - Commit: `docs({phase}-{plan}): complete [plan-name] plan`

### 4. Deviation Handling
During execution:
- **Auto-fix bugs** - fix immediately, document in Summary
- **Auto-add critical** - security/correctness gaps, add and document
- **Auto-fix blockers** - can't proceed without fix, do it and document
- **Ask about architectural** - major structural changes, stop and ask user

### 5. Verify Phase Goal
After all plans complete:
- Check must_haves from plans against actual codebase (not just SUMMARY claims)
- Create VERIFICATION.md with results
- Route by status:
  - `passed` -> continue
  - `gaps_found` -> suggest `/skill:gsd-plan-phase {X} --gaps`

### 6. Update State
- Update ROADMAP.md (mark phase complete)
- Update STATE.md (current position, last activity)
- Update REQUIREMENTS.md (mark phase requirements as Complete)
- Commit: `docs({phase}): complete {phase-name} phase`

### 7. Present Results and Next Steps
- If more phases remain: suggest next phase
- If all phases complete: suggest milestone completion
- If gaps found: suggest gap closure planning

## Commit Rules
- Stage files individually (never `git add .` or `git add -A`)
- Per-task commits: `{type}({phase}-{plan}): {task-name}`
- Plan metadata commit: `docs({phase}-{plan}): complete [plan-name] plan`
- Phase completion commit: `docs({phase}): complete {phase-name} phase`
- No attribution footers
