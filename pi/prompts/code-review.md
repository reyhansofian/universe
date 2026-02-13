---
description: Code review with parallel specialized reviewers
model: claude-sonnet-4-5-20250929
thinking: medium
---

# Code Review - Multi-Agent Parallel

You are leading a code review using specialized reviewer subagents.

## Step 1: Collect the diff

Determine what to review:
- If `$ARGUMENTS` specifies a branch name, run: `git diff $ARGUMENTS...HEAD`
- If `$ARGUMENTS` specifies file paths, run: `git diff -- $ARGUMENTS`
- If `$ARGUMENTS` is empty, run: `git diff` (unstaged changes), falling back to `git diff HEAD~1` if no unstaged changes exist

Store the full diff output. You will pass it to each reviewer.

## Step 2: Run parallel reviewers

Use the `subagent` tool to run 4 reviewers in parallel. Pass the full diff as part of each task string.

```json
{
  "tasks": [
    { "agent": "security-reviewer", "task": "Review this diff for security issues:\n\n<diff>\n{THE_DIFF}\n</diff>" },
    { "agent": "architect-reviewer", "task": "Review this diff for architectural concerns:\n\n<diff>\n{THE_DIFF}\n</diff>" },
    { "agent": "quality-reviewer", "task": "Review this diff for code quality:\n\n<diff>\n{THE_DIFF}\n</diff>" },
    { "agent": "test-reviewer", "task": "Review this diff for test coverage gaps:\n\n<diff>\n{THE_DIFF}\n</diff>" }
  ],
  "clarify": false
}
```

Replace `{THE_DIFF}` with the actual diff content.

## Step 3: Synthesize findings

After all 4 reviewers complete, collect their results. Produce a single report:

```
## Code Review Summary

### P0 - Critical (must fix before merge)
- [finding] (source: security/architect/quality/tests)

### P1 - High (should fix before merge)
- [finding] (source: ...)

### P2 - Medium (fix soon)
- [finding] (source: ...)

### P3 - Low (consider fixing)
- [finding] (source: ...)

### Verdict: APPROVE / REQUEST_CHANGES / NEEDS_DISCUSSION
```

Omit priority sections that have no findings.
