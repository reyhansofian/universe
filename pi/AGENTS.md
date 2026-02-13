<subagent>
Always prefer the strongest available model for subagent tasks.
Use Opus when available, defer to Sonnet otherwise.
</subagent>

<follow-on-command>
Your context window is becoming too full. Create a brief prompt for yourself that can inform
you in a few words of the essential data needed for you to continue this task in a new session.
Do not perform the task - only return the prompt that will provide
the necessary context for you to carry it out in a new session.
</follow-on-command>

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
