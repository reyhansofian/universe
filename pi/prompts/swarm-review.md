---
description: Quick code review using swarm mode
model: claude-sonnet-4-5-20250929
thinking: medium
---

# Quick Code Review - Swarm Mode

You are performing a quick code review using swarm mode.

## Step 1: Collect the diff

Determine what to review:
- If `$ARGUMENTS` specifies a branch or files, use: `git diff $ARGUMENTS`
- If empty, use: `git diff` (unstaged), falling back to `git diff HEAD~1`

## Step 2: Swarm on the review

Use `/swarm` to review the diff with this task:

> Review the following code diff for issues across four dimensions: security (injection, auth bypass, credential leaks, OWASP top 10), architecture (SOLID violations, coupling, API design), code quality (readability, duplication, naming, error handling), and test coverage (missing tests, edge cases, silent failures). Rate each finding P0-P3. Output a prioritized list grouped by severity, with a final verdict of APPROVE, REQUEST_CHANGES, or NEEDS_DISCUSSION.
>
> Diff:
> [paste diff here]

## Step 3: Report

Present the swarm's findings as-is. Add a one-line summary at the top with the verdict and total finding count.
