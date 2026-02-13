---
description: Resume work from previous session with full context restoration
model: claude-opus-4-6
thinking: high
---

Restore complete project context and resume work from a previous session.

## Process

1. **Verify project exists:**
   ```bash
   test -d .planning && echo "exists" || echo "missing"
   ```
   If missing, suggest `/skill:gsd-new-project`.

2. **Load STATE.md** for current position, decisions, blockers.

3. **Check for checkpoints:**
   - Look for `.continue-here.md` files in phase directories
   - Look for incomplete plans (PLAN.md without matching SUMMARY.md)

4. **If checkpoint found:** Read it and present:
   ```
   Resuming from: [phase/plan/task]

   What was done: [summary]
   What remains: [remaining tasks]
   Next action: [from .continue-here.md]

   Ready to continue?
   ```

5. **If no checkpoint:** Fall back to STATE.md position and present current status.

6. **Heed context:**
   - Follow decisions already made
   - Don't repeat approaches that were tried and abandoned
   - Pick up exactly where the previous session left off

7. **Route to next action:**
   - If unexecuted plans exist: suggest executing them
   - If phase needs planning: suggest planning
   - If between phases: suggest next phase

$ARGUMENTS
