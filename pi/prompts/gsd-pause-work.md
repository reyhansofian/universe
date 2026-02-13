---
description: Create context handoff when pausing work mid-phase
model: claude-sonnet-4-5-20250929
thinking: low
---

Create a `.continue-here.md` handoff file to preserve complete work state across sessions.

## Process

1. **Detect:** Find current phase directory from most recently modified files.

2. **Gather complete state:**
   - Current position: which phase, which plan, which task
   - Work completed this session
   - Work remaining in current plan/phase
   - Decisions made and rationale
   - Blockers/issues
   - Mental context: the approach, next steps
   - Files modified but not committed

3. **Write handoff** to `.planning/phases/XX-name/.continue-here.md`:

```markdown
---
phase: XX-name
task: 3
total_tasks: 7
status: in_progress
last_updated: [timestamp]
---

<current_state>
[Where exactly are we? Immediate context]
</current_state>

<completed_work>
- Task 1: [name] - Done
- Task 2: [name] - Done
- Task 3: [name] - In progress, [what's done]
</completed_work>

<remaining_work>
- Task 3: [what's left]
- Task 4: Not started
</remaining_work>

<decisions_made>
- Decided to use [X] because [reason]
</decisions_made>

<blockers>
- [Blocker 1]: [status/workaround]
</blockers>

<next_action>
Start with: [specific first action when resuming]
</next_action>
```

4. **Commit:**
   ```bash
   git add .planning/phases/*/.continue-here.md
   git commit -m "wip: [phase-name] paused at task [X]/[Y]"
   ```

5. **Confirm:** Show location and how to resume (`/gsd-resume-work`).

$ARGUMENTS
