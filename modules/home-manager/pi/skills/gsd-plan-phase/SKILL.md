---
name: gsd-plan-phase
description: "Create detailed execution plan for a phase. Reads ROADMAP.md, researches codebase, produces PLAN.md files."
metadata:
  preferred-model: claude-opus-4-6
---

# GSD: Plan Phase

Create executable plans (PLAN.md files) for a roadmap phase.

**Flow:** Research (if needed) -> Plan -> Verify -> Done

## Arguments

Phase number (integer or decimal like 2.1). Auto-detects next unplanned phase if not provided.

Flags:
- `--skip-research` - skip research, plan directly
- `--gaps` - gap closure mode (reads VERIFICATION.md)

## Process

### 1. Validate
- Check `.planning/` exists
- Parse phase number from arguments (normalize to zero-padded: 8 -> 08)
- Validate phase exists in ROADMAP.md
- Ensure phase directory exists (create if needed)
- Load CONTEXT.md if it exists (from `/gsd:discuss-phase`)

### 2. Research (unless skipped)
If research enabled in config and no existing RESEARCH.md:

Research how to implement the phase:
- What frameworks/libraries are needed
- What patterns work best
- What pitfalls to avoid
- How it integrates with existing code

Use Serena MCP for codebase analysis (symbol lookup, references, code overview).
Use Context7 MCP for framework-specific documentation.

Write findings to `{phase_dir}/{phase}-RESEARCH.md`.

If CONTEXT.md exists:
- **Decisions section** = locked choices, research these deeply
- **Claude's Discretion** = freedom areas, research options
- **Deferred Ideas** = out of scope, ignore

### 3. Plan
Read all context (STATE.md, ROADMAP.md, REQUIREMENTS.md, CONTEXT.md, RESEARCH.md).

Create PLAN.md files in phase directory. Each plan should have:

```yaml
---
plan: NN
name: plan-name
wave: 1
depends_on: []
files_modified: []
autonomous: true
---
```

Plans contain:
- Objective (what this plan achieves)
- Tasks in sequence (specific, actionable steps)
- Verification criteria (how to confirm it works)
- must_haves (derived from phase goal, for verification)

Group plans into waves for execution ordering:
- Wave 1: independent plans (can run in any order)
- Wave 2: depends on wave 1 results
- etc.

### 4. Verify Plans
Review each plan against the phase goal:
- Do tasks cover all requirements mapped to this phase?
- Are dependencies correctly identified?
- Are tasks specific enough to execute?
- Do must_haves match the phase success criteria?

If issues found, revise plans (max 3 iterations).

### 5. Present Results

```
Phase {X}: {Name} - {N} plan(s) in {M} wave(s)

| Wave | Plans | What it builds |
|------|-------|----------------|
| 1    | 01, 02 | [objectives] |
| 2    | 03     | [objective]  |

Next: execute the phase plans
```
