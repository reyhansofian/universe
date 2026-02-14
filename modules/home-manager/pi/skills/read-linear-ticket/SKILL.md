---
name: read-linear-ticket
description: Use when reading, reviewing, or analyzing Linear tickets. Fetches ticket details and enriches with comments, dependencies, and related context.
---

# Read Linear Ticket

## When to Use

Use this skill when:
- User shares a Linear URL (e.g., `https://linear.app/team/issue/TECH-123`)
- User asks to read, review, or summarize a Linear ticket
- User provides a Linear ticket ID (e.g., "TECH-123")
- User asks "what's the status of..." a ticket
- User wants to understand a ticket before starting work
- User asks to review their assigned tickets

**IMPORTANT**: You have direct access to Linear via MCP tools. Never say you cannot access Linear URLs. Extract the issue identifier from the URL and use `linear_search_issues` to fetch it.

## Workflow

### Read from URL

When user shares a Linear URL like `https://linear.app/myteam/issue/TECH-123/some-title`:

1. **Extract identifier**: The issue ID is in the URL path after `/issue/`. Example: `TECH-123`
2. **Search for issue**: Use `mcp__linear__linear_search_issues` with the identifier
3. **Enrich and present**: Follow the Single Ticket workflow below

URL patterns:
- `https://linear.app/<workspace>/issue/<ID>/<slug>` - issue page
- `https://linear.app/<workspace>/issue/<ID>` - issue page (no slug)

### Single Ticket

1. **Resolve ticket**: Extract issue ID from user input (e.g., "TECH-123", a URL, or description)
2. **Fetch issue**: Use `mcp__linear__linear_search_issues` with the identifier
3. **Fetch comments**: Use `mcp__linear__linear_add_comment` is write-only - instead, read comments from the issue resource URI `linear-issue:///{issueId}`
4. **Enrich with context**:
   - Check for blocked/blocking relationships
   - Note the parent issue or sub-issues if any
   - Note the cycle/project assignment
   - Check assignee and current state
5. **Present enriched summary** using the output format below

### My Tickets

1. **Fetch assigned issues**: Use `mcp__linear__linear_get_user_issues`
2. **Group by state**: Organize into In Progress, Todo, Backlog
3. **Summarize each** with title, priority, and age

### Team Tickets

1. **Resolve team**: Default to "Tech" or specified team
2. **Search issues**: Use `mcp__linear__linear_search_issues` with team and status filters
3. **Present grouped summary**

## Output Format

Present each ticket as:

```
### TECH-123: Title Here
**Status**: In Progress | **Priority**: High | **Assignee**: Name
**Cycle**: Sprint 24 | **Created**: 3 days ago

#### Summary
[2-3 sentence summary of WHAT and HOW from description]

#### Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

#### Dependencies
- Blocked by: TECH-100 (Title) - In Progress
- Blocks: TECH-150 (Title) - Todo

#### Recent Activity
- [2h ago] @name: Comment summary
- [1d ago] Status changed: Todo -> In Progress
```

## Enrichment Rules

| Data Point | How to Get | When to Include |
|------------|-----------|-----------------|
| Comments | Issue resource URI | Always (last 5) |
| Dependencies | Issue resource URI | When present |
| Sub-issues | Issue resource URI | When present |
| Cycle | Issue resource URI | When assigned |
| Labels | Search result | Always |
| Priority | Search result | Always |

## Tool Reference

| Tool | Use For |
|------|---------|
| `linear_search_issues` | Find tickets by ID, title, status, team, assignee |
| `linear_get_user_issues` | Get current user's assigned tickets |

Resources:
- `linear-issue:///{issueId}` - Full issue details with comments and relations
- `linear-team:///{teamId}/issues` - All team issues
- `linear-user:///me` - Current user info

## Examples

**"Read TECH-123"** - Fetch single ticket, enrich, present summary

**"What are my tickets?"** - Fetch user issues, group by state, summarize

**"Show me all open bugs on Tech team"** - Search with team + label/state filters

**"What's blocking TECH-200?"** - Fetch ticket, focus on dependency chain

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Showing raw markdown dump | Parse and present clean summary |
| Missing dependencies | Always check blocked/blocking relations |
| No comment context | Include last 5 comments with timestamps |
| Stale data assumption | Always fetch fresh from API |
