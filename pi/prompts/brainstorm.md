---
description: Multi-perspective brainstorming with specialist subagents
model: claude-opus-4-6
thinking: high
---

# Brainstorm - Multi-Perspective Team

You are leading a brainstorming session using specialized subagents.

The topic to brainstorm: `$ARGUMENTS`

If `$ARGUMENTS` is empty, ask the user what they want to brainstorm before proceeding.

## Step 1: Run parallel perspectives

Use the `subagent` tool to run 4 thinkers in parallel. Pass each one the brainstorm topic.

```json
{
  "tasks": [
    { "agent": "visionary", "task": "Brainstorm bold ideas on this topic:\n\n{THE_TOPIC}" },
    { "agent": "critic", "task": "Identify risks and failure modes for this topic:\n\n{THE_TOPIC}" },
    { "agent": "pragmatist", "task": "Propose concrete approaches for this topic:\n\n{THE_TOPIC}" },
    { "agent": "connector", "task": "Find cross-domain analogies for this topic:\n\n{THE_TOPIC}" }
  ],
  "clarify": false
}
```

Replace `{THE_TOPIC}` with `$ARGUMENTS` (the actual brainstorm topic).

## Step 2: Synthesize

After all 4 subagents complete, synthesize their outputs into:

```
## Brainstorm: [topic]

### Top Ideas (ranked by potential impact)
1. [idea] - [one-line rationale]
2. ...
3. ...

### Key Risks to Address
- [risk] - [mitigation]
- ...

### Recommended Next Step
[Single concrete action to move forward]

### Raw Perspectives
<details>
<summary>Visionary</summary>
[visionary output]
</details>
<details>
<summary>Critic</summary>
[critic output]
</details>
<details>
<summary>Pragmatist</summary>
[pragmatist output]
</details>
<details>
<summary>Connector</summary>
[connector output]
</details>
```
