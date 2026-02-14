<subagent>
Always prefer the strongest available model for subagent tasks.
Use Opus when available, defer to Sonnet otherwise.
</subagent>

<teams>
After all delegated team tasks are completed, always shut down the teammates
and clean up the team. Call teams({ action: "member_shutdown", all: true })
then /team cleanup --force.
</teams>

<follow-on-command>
Your context window is becoming too full. Create a brief prompt for yourself that can inform
you in a few words of the essential data needed for you to continue this task in a new session.
Do not perform the task - only return the prompt that will provide
the necessary context for you to carry it out in a new session.
</follow-on-command>

<jj>
Detect whether a repository is jj-managed (look for .jj/ directory) before
running VCS commands. Use jj for jj-managed repos, git for pure-git repos.

For jj-managed repos, use jj as the primary VCS tool:
- Status: `jj status` / `jj st`
- Log: `jj log`
- Diff: `jj diff`
- Commit: `jj commit -m "type: message"` (one-liner, conventional commit)
- Describe current change: `jj describe -m "type: message"`
- New change: `jj new`
- Squash: `jj squash`
- Bookmarks: `jj bookmark create/set/move`

Commit messages must be a single-line conventional commit (feat:, fix:,
chore:, refactor:, docs:, test:, etc.) under 72 characters. No body or
footer unless explicitly requested.

Do not run `jj git push` unless the user explicitly asks. This matches the
no-push-unless-asked convention.

Bookmark naming: if the work originates from a Linear ticket, use the branch
name provided by Linear. Otherwise, use any reasonable descriptive name.

When colocated with git (.git/ also present), prefer jj commands over git.
Do not mix jj and git commands in the same repo unless necessary.
</jj>

<markdown-search>
Use qmd for searching markdown content. Do not use grep/ripgrep on indexed collections.

Commands:
- qmd search "query" - BM25 full-text search (fast, keyword matching)
- qmd vsearch "query" - vector similarity search (semantic understanding)
- qmd query "query" - combined search with LLM re-ranking (best quality)
- qmd ls <collection> - list files in collection
- qmd status - show all collections

Options: -n <num> for result count, --full for full documents, -c <collection> to filter

Collection naming: <project>_<type>
Standard types: plans, artifacts, adr, specs, docs

Before searching markdown, run `qmd status` to identify relevant collections.
</markdown-search>
