---
name: read-outline
description: Use when reading, searching, or browsing Outline wiki documents and collections. Supports search, browse by collection, and natural language Q&A.
---

# Read Outline

## When to Use

Use this skill when:
- User shares an Outline URL (e.g., `https://app.getoutline.com/doc/some-title-abc123`)
- User asks to find or read a document from Outline wiki
- User asks "what do we have documented about X"
- User wants to browse collections or list documents
- User needs to reference internal documentation during coding

**IMPORTANT**: You have direct access to Outline via MCP tools. Never say you cannot access Outline URLs. Extract the document slug from the URL and use `get_document` to fetch it.

## Tool Reference

All tools are prefixed with `mcp__outline__`. These are the read-relevant tools:

| Tool | Parameters | Purpose |
|------|-----------|---------|
| `search_documents` | `query`, `collectionId?`, `limit?` | Full-text keyword search |
| `ask_documents` | `query`, `collectionId?`, `documentId?`, `statusFilter?` | Natural language Q&A (requires AI answers enabled in workspace) |
| `get_document` | `id` (UUID or urlId) | Fetch single document with full content |
| `list_documents` | `collectionId?`, `limit?`, `offset?`, `sort?`, `direction?`, `userId?`, `parentDocumentId?` | List/filter documents |
| `list_collections` | `limit?` | List all collections |
| `get_collection` | `id` | Get collection details |
| `list_comments` | `documentId?`, `collectionId?`, `includeAnchorText?`, `limit?` | Get comments on a document |

## Workflows

### Read from URL

When user shares an Outline URL like `https://app.getoutline.com/doc/performance-degradation-abc123`:

1. **Extract the slug**: The document ID is the last segment of the URL path after `/doc/`. Example: `performance-degradation-abc123`
2. **Fetch document**: Use `mcp__outline__get_document` with `id` set to the slug (e.g., `performance-degradation-abc123`)
3. **Present content**: Parse and display the document using the output format below

URL patterns:
- `https://app.getoutline.com/doc/<slug>` - document page
- `https://app.getoutline.com/collection/<id>` - collection page
- `https://<team>.getoutline.com/doc/<slug>` - custom domain

### Search for a Topic

1. Use `mcp__outline__search_documents` with the user's query
2. Present results as a summary list with titles and snippets
3. If user wants to read one, fetch full content with `mcp__outline__get_document`

### Browse a Collection

1. Use `mcp__outline__list_collections` to show available collections
2. Use `mcp__outline__list_documents` with `collectionId` to list docs in chosen collection
3. Fetch specific docs with `mcp__outline__get_document` as needed

### Ask a Question

1. Use `mcp__outline__ask_documents` with the natural language query
2. Present the answer with source document references
3. Offer to fetch full source documents if user wants more detail

### Read a Specific Document

1. Use `mcp__outline__get_document` with the document ID or URL slug
2. Parse the markdown content
3. If document has comments, fetch with `mcp__outline__list_comments`
4. Present clean summary or full content based on user request

## Output Format

### Search Results
```
Found N documents for "query":

1. **Document Title** (Collection Name)
   Last updated: 2 days ago
   > Relevant snippet from search result...

2. **Document Title** (Collection Name)
   Last updated: 1 week ago
   > Relevant snippet...
```

### Document Read
```
### Document Title
**Collection**: Name | **Updated**: date | **Author**: name

[Document content - summarized or full based on request]

#### Comments (if any)
- @author (date): Comment text
```

### Collection Browse
```
### Collection Name
N documents | Last updated: date

- Document Title (updated date)
- Document Title (updated date)
- Document Title (updated date)
```

## Tips

- Use `search_documents` for keyword matching, `ask_documents` for semantic questions
- `get_document` accepts both UUID and URL slug as the `id` parameter
- When listing documents, default `sort` to "updatedAt" with direction "DESC" for most recent first
- Limit results to 10 by default to keep output manageable

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Dumping raw JSON to user | Parse and present clean formatted output |
| Not specifying collection | Ask user or list collections first |
| Fetching all docs at once | Use pagination with limit/offset |
| Ignoring comments | Check for comments on important docs |
