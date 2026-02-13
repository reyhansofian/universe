---
description: Execute a quick task with atomic commits and state tracking
model: claude-opus-4-6
thinking: high
---

Execute a small, ad-hoc task with GSD guarantees (atomic commits, STATE.md tracking) while skipping research and verification.

## Process

1. **Validate:** Check `.planning/ROADMAP.md` exists. If not, suggest `/skill:gsd-new-project`.

2. **Get task description:** Ask what needs to be done if not provided in arguments.

3. **Create quick task directory:**
   ```bash
   mkdir -p .planning/quick
   # Find next sequential number (001, 002, etc.)
   # Create .planning/quick/NNN-slug/
   ```

4. **Plan:** Create a single plan with 1-3 focused tasks in the quick task directory. Quick tasks should be atomic and self-contained. Write to `NNN-PLAN.md`.

5. **Execute:** Work through the plan. Commit each task atomically using conventional commit format. Create `NNN-SUMMARY.md` with what was done.

6. **Update STATE.md:** Add row to "Quick Tasks Completed" table (create section if it doesn't exist). Update "Last activity" line.

7. **Commit artifacts:**
   ```bash
   git add .planning/quick/NNN-slug/NNN-PLAN.md
   git add .planning/quick/NNN-slug/NNN-SUMMARY.md
   git add .planning/STATE.md
   git commit -m "docs(quick-NNN): description"
   ```

## Constraints
- Single plan with 1-3 tasks
- No research phase, no checker phase
- Quick tasks live in `.planning/quick/` separate from planned phases
- Updates STATE.md, NOT ROADMAP.md

$ARGUMENTS
