---
name: write-outline
description: Use when creating, updating, or managing Outline wiki documents, collections, and comments. Handles document creation, edits, moves, and archival.
---

# Write Outline

## When to Use

Use this skill when:
- User shares an Outline URL to edit or update (e.g., `https://app.getoutline.com/doc/some-title-abc123`)
- User asks to create a new document or page in Outline
- User wants to update or edit an existing Outline document
- User asks to organize docs (move, archive, delete)
- User wants to add comments to a document
- User asks to create a new collection
- Converting notes, ADRs, or meeting minutes into Outline docs

**IMPORTANT**: You have direct access to Outline via MCP tools. If a user shares an Outline URL, extract the document slug from the URL path and use `mcp__outline__get_document` to fetch it before editing. Never say you cannot access Outline URLs.

## Tool Reference

All tools are prefixed with `mcp__outline__`.

### Document Tools

| Tool | Required Params | Optional Params | Purpose |
|------|----------------|-----------------|---------|
| `create_document` | `title`, `text`, `collectionId` | `parentDocumentId`, `publish`, `template` | Create new doc |
| `update_document` | `documentId` | `title`, `text`, `publish`, `done` | Edit existing doc |
| `move_document` | `id` | `collectionId`, `parentDocumentId` | Move doc to different location |
| `archive_document` | `id` | | Archive a doc |
| `delete_document` | `id` | | Permanently delete a doc |
| `create_template_from_document` | `id` | | Turn doc into reusable template |

### Collection Tools

| Tool | Required Params | Optional Params | Purpose |
|------|----------------|-----------------|---------|
| `create_collection` | `name` | `description`, `permission`, `color`, `private` | Create new collection |
| `update_collection` | `id` | `name`, `description`, `permission`, `color` | Edit collection |

### Comment Tools

| Tool | Required Params | Optional Params | Purpose |
|------|----------------|-----------------|---------|
| `create_comment` | `documentId`, `text` | `parentCommentId` | Add comment to doc |
| `update_comment` | `id` | `text` | Edit comment |
| `delete_comment` | `id` | | Remove comment |

## Workflows

### Create a New Document

1. **Resolve collection**: Use `mcp__outline__list_collections` to find the target collection ID. Ask user if unclear.
2. **Create document**: Use `mcp__outline__create_document` with:
   - `title`: Clear, descriptive title
   - `text`: Content in markdown format
   - `collectionId`: Target collection
   - `publish`: `true` unless user wants a draft
3. **Confirm**: Return the document title and URL to the user

### Update from URL

When user shares an Outline URL like `https://app.getoutline.com/doc/some-title-abc123` to edit:

1. **Extract slug**: The document ID is the last segment after `/doc/`. Example: `some-title-abc123`
2. **Fetch document**: Use `mcp__outline__get_document` with the slug as `id`
3. **Follow Update workflow below** with the fetched document

URL patterns:
- `https://app.getoutline.com/doc/<slug>` - document page
- `https://<team>.getoutline.com/doc/<slug>` - custom domain

### Update an Existing Document

1. **Find document**: Use `mcp__outline__search_documents` or `mcp__outline__get_document` to locate it
2. **Read current content**: Fetch full doc with `mcp__outline__get_document` to understand existing structure
3. **Update**: Use `mcp__outline__update_document` with only the changed fields
4. **Confirm**: Show what was changed

### Organize Documents

- **Move**: `mcp__outline__move_document` with target `collectionId` or `parentDocumentId`
- **Archive**: `mcp__outline__archive_document` - reversible, doc is hidden but not deleted
- **Delete**: `mcp__outline__delete_document` - permanent, confirm with user first

### Create a Collection

1. Use `mcp__outline__create_collection` with:
   - `name`: Collection name
   - `description`: What this collection is for
   - `permission`: `read_write` (default) or `read`
2. Return collection name and ID

## Default Behavior

- **Publish**: `true` by default - set to `false` for drafts
- **Permission**: `read_write` for new collections unless specified
- **Format**: All content (`text`) is markdown

## Content Guidelines

When creating documents, format content as clean markdown:
- Use headings (`##`, `###`) for structure
- Use bullet lists for items
- Use code blocks with language tags for code
- Use tables where data is tabular
- Keep paragraphs concise

## Safety Rules

| Action | Rule |
|--------|------|
| Delete document | Always confirm with user first |
| Delete comment | Always confirm with user first |
| Overwrite text | Show diff or summary of changes before updating |
| Archive | Safe to do without confirmation (reversible) |
| Create/Update | Safe to proceed |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Creating doc without collection | Always resolve `collectionId` first |
| Overwriting full doc on partial edit | Only pass changed fields to `update_document` |
| Not publishing | Set `publish: true` unless user explicitly wants draft |
| Missing collection context | List collections first so user can choose |
