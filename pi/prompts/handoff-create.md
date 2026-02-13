---
description: Create a handoff document for any AI coding agent to continue your work
---

Create a `HANDOFF.md` file that enables ANY AI coding agent to continue this work seamlessly.

## Gather Context First

Run these commands to understand current state:
- `git status` - see uncommitted changes
- `git diff --stat` - see what files changed
- `git log --oneline -5` - recent commits from this session

Review the conversation history to extract:
- The original task/goal
- What was completed
- **What was tried and didn't work** (critical - saves hours)
- Key decisions and their rationale
- User preferences expressed during the session
- Error messages encountered and how they were resolved

## Write HANDOFF.md

Use this structure (omit empty sections, but NEVER omit Failed Approaches if any exist):

```markdown
# Handoff: [Brief Task Title]

**Generated**: [date/time]
**Branch**: [git branch]
**Status**: [In Progress / Blocked / Ready for Review]

## Goal

[1-2 sentences: what the user wants to achieve]

## Completed

- [x] [Specific completed item]
- [x] [Another completed item]

## Not Yet Done

- [ ] [Remaining task - be specific]
- [ ] [Another remaining task]

## Failed Approaches (Don't Repeat These)

[IMPORTANT: Always include this if anything was tried and abandoned. Be specific:]
- What was attempted
- Why it failed (error message, performance issue, design flaw)
- Why the current approach is better

## Key Decisions

| Decision | Rationale |
|----------|-----------|
| [Choice made] | [Why this approach] |

## Current State

**Working**: [What's functional right now]

**Broken**: [What's not working, error messages if relevant]

**Uncommitted Changes**: [Summary of unstaged/staged changes]

## Files to Know

| File | Why It Matters |
|------|----------------|
| `path/to/key/file.ts` | [Brief description] |

## Code Context

[Include actual code the next agent needs. Don't describe - show:]

**Key interfaces/signatures** (so the agent knows how to call/modify them)

**API request/response shapes** (if backend work)

**Non-obvious logic** (anything tricky that isn't self-documenting)

## Resume Instructions

[Be extremely specific. Not "test the feature" but step-by-step with expected outcomes:]

1. [Setup step if needed - migrations, env vars, etc.]
2. [First action with exact command or file to edit]
3. [Verification step with expected outcome]
   - Expected: [what should happen]
   - If it fails: [what to check]

## Setup Required

[Only if there are prerequisites the next agent needs]

## Warnings

[Gotchas, things that look wrong but are intentional, or traps to avoid]
```

## Guidelines

- **Failed approaches are mandatory** - if anything was tried and abandoned, document it
- **Show code, don't describe** - include actual signatures, interfaces, response shapes
- **Testing steps need expected outcomes** - "verify it works" is useless
- Be brutally concise - every word should earn its place
- Include error messages verbatim when relevant
- Use file paths relative to repo root
- If there's a blocker, say so prominently
- Omit empty sections (except Failed Approaches - say "None" if truly nothing failed)

Save to `HANDOFF.md` in the working directory. If `$ARGUMENTS` specifies a path, use that instead.
