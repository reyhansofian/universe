---
name: create-linear-ticket
description: Use when creating Linear tickets or issues. Applies standard template with WHAT, HOW, CRITERIA sections and assigns to current user by default.
---

# Create Linear Ticket

## When to Use

Use this skill when:
- User asks to create a Linear ticket/issue
- User wants to log a bug, feature request, or task in Linear
- Converting notes or requirements into Linear tickets
- User references a Linear URL as context for a new ticket (e.g., "create a follow-up for TECH-123")

**IMPORTANT**: You have direct access to Linear via MCP tools. If a user shares a Linear URL as context, extract the issue ID and use `mcp__linear__linear_search_issues` to fetch it before creating the new ticket. Never say you cannot access Linear URLs.

## Default Behavior

- **Assignee**: Always assign to "me" (current user) unless specified otherwise
- **Team**: Use "Tech" team unless specified otherwise
- **Status**: Set to "Todo" unless specified otherwise

## Description Template

All tickets MUST use this template structure:

```markdown
## WHAT

[Describe the problem, bug, or feature request]

[Include screenshots, videos, or links for additional context if available]

## HOW

[Describe the expected outcome or proposed solution]

[Include mockups or design references if available]

## CRITERIA

[List acceptance criteria for the happy path]
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3
```

## Workflow

1. **Resolve context**: If user provides a Linear URL or ticket ID as context, fetch it first with `mcp__linear__linear_search_issues` to pull in relevant details (title, description, acceptance criteria) for the new ticket
2. **Gather information**: Ask user for WHAT, HOW, and CRITERIA if not provided
2. **Determine team**: Default to "Tech" or ask if unclear
3. **Set title**: Create concise, descriptive title (under 70 characters)
4. **Create ticket**: Use `mcp__linear__linear_create_issue` with:
   - `title`: Descriptive title
   - `description`: Formatted with WHAT/HOW/CRITERIA template
   - `teamId`: Resolve "Tech" team ID first via `mcp__linear__linear_search_issues` or resource URIs
   - `assigneeId`: Resolve current user via `mcp__linear__linear_get_user_issues` or resource URIs
   - `stateId`: Resolve "Todo" state for the team
5. **Set dependencies**: If ticket depends on others, use `mcp__linear__linear_update_issue` with dependency fields
6. **Return URL**: Always provide the ticket URL to the user

## Tool Reference

The Linear MCP server (`mcp__linear__`) exposes these tools:

| Tool | Purpose |
|------|---------|
| `linear_create_issue` | Create new issue |
| `linear_update_issue` | Update existing issue |
| `linear_search_issues` | Search/filter issues |
| `linear_get_user_issues` | Get issues for a user |
| `linear_add_comment` | Add comment to issue |

Resources available via URI patterns:
- `linear-issue:///{issueId}` - Issue details
- `linear-team:///{teamId}/issues` - Team issues
- `linear-user:///me` - Current user info
- `linear-organization:///teams` - All teams

## Example

### User Request
"Create a ticket for adding export to CSV functionality in the reports page"

### Created Ticket

**Title**: Add CSV Export to Reports Page

**Description**:
```markdown
## WHAT

Users need to export report data to CSV format for analysis in spreadsheet applications.

Currently there is no way to download report data - users must manually copy data.

## HOW

Add an "Export CSV" button to the reports page header that:
- Exports all visible columns
- Uses current filter/sort settings
- Downloads file with format: `report-{date}.csv`

## CRITERIA

- [ ] Export button visible on reports page
- [ ] CSV includes all displayed columns
- [ ] CSV respects current filters
- [ ] File downloads with correct naming convention
- [ ] Works for reports with up to 10,000 rows
```

## Quick Reference

| Field | Default | Notes |
|-------|---------|-------|
| assignee | "me" | Current user |
| team | "Tech" | Ask if unclear |
| state | "Todo" | Or "Backlog" for low priority |
| priority | None | 1=Urgent, 2=High, 3=Normal, 4=Low |
| cycle | None | Add to cycle if specified |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Missing WHAT section | Always describe the problem first |
| Vague CRITERIA | Use specific, testable acceptance criteria |
| No assignee | Default to "me" |
| Title too long | Keep under 70 characters |
| Missing context in WHAT | Include screenshots/links when relevant |
