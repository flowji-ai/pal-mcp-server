# [ROOT] SPECTRI PROJECT
<!-- target: ./ -->

## Agent Directives

- **Follow the Tooling-First Mandate.** Before performing any task, check for existing tooling in this order: (1) Skill — auto-applied guidance matching the task context, (2) Command — explicit `/spec.*` invocation, (3) Script — automation in `.spectri/scripts/`, (4) Manual — only if none of the above exist (document why). Never create artifacts manually when a `/spec.*` command exists. Commands handle template structure, metadata, validation, and git commits.
- **Commit after every artifact.** Every `/spec.*` command ends with a finalization checklist that includes committing. Do not leave work uncommitted.
- **Every commit is a complete bundle.** Walk the commit bundle checklist in the relevant workflow skill (spectri-code-change, spectri-resolve-issue, or spectri-implement-task) before every commit. At minimum: stage the change + spec update (if spec must reflect reality) + resolved issue with `## Resolution` filled in (if resolving) + `/spec.summary`. Run tests if code changed.
- **Never hardcode counts, quantities, or enumerations in documentation.** Reference the source instead. Write "the articles in constitution.md" not "17 Articles". Write "the stages in spectri/specs/" not "5 stages". When the source changes, all references remain correct automatically.
- **Never fabricate timestamps.** Always call `bash .spectri/scripts/shared/get-timestamp.sh` (`--date` for `YYYY-MM-DD` only; no flag for full ISO 8601).
- **MUST NOT manually edit meta.json — use `/spec.update-meta` exclusively.**
- **Before advancing any spec to `deployed`, verify spec.md documents current behaviour — not planned, not aspirational.** The spec MUST describe what the code does right now. Check all tasks are complete and tests pass.
- **Deployed specs are living documents.** When a deployed feature changes, update its spec in the same commit as the code change. Never create a new spec to replace an existing deployed one — that produces spec sprawl. Only `05-archived/` specs are read-only.

## Spec-Driven Development

Before writing any code, identify the governing spec:

1. Check `spectri/specs/04-deployed/` for a deployed spec covering the feature you are modifying
2. Also check `02-implementing/` for in-progress specs
3. If multiple specs are affected, list all — each needs its obligations checked independently

If the change adds or alters observable behaviour, the spec MUST be updated in the same commit as the code change. Stage the spec update before running `/spec.summary` — summaries are immutable snapshots of the state at commit time.

If no spec exists for the feature, note it and proceed. Do not block current work. Consider `/spec.retro` afterward for significant unspecified features. For pure infrastructure with no user-facing feature, state "no governing spec" and why in your commit summary.

## Code Change Protocol

Every code change follows one of three paths. Identify which applies before writing code.

**With a tracked issue:** Use the `spectri-resolve-issue` skill. Read the issue file first. Classify (simple vs behaviour change). Execute. Fill `## Resolution`. Commit everything together.

**Without a tracked issue or task:** Use the `spectri-code-change` skill. Classify (simple vs behaviour change). Identify governing spec. Follow the commit path for your classification.

**From tasks.md:** Use the `spectri-implement-task` skill. Read the task, check dependencies, implement, commit the bundle.

> Committing code alone — without spec update, tests, and implementation summary — is the most common agent failure pattern. Every code change commit MUST include all obligations for its classification.

> "I don't need a skill for this" — if you are changing code, you need the work cycle. No exceptions.

## Canonical Command System

**CRITICAL**: Command files in `.claude/commands/`, `.qwen/commands/`, etc. are deployed from `.spectri/canonical/commands/`.

**Never modify files directly in agent command folders.** All changes must be made in `.spectri/canonical/commands/` (the source of truth), then synced to agent directories.

**How to sync:** Run `spectri sync-canonical` from the project root. Use `--dry-run` to preview changes. The Spectri CLI must be installed — if it is not, install it first (`pipx install spectri` or `uv tool install spectri`).

**When to run `spectri sync-canonical`:**
- After `spectri init` (required — init deploys to `.spectri/canonical/` but does not populate agent directories)
- After pulling Spectri updates and running `spectri update` (update runs sync automatically, but manual sync is useful after git operations)
- After editing templates in `.spectri/canonical/commands/` or `.spectri/canonical/skills/`

**What it syncs:** Commands, skills, and context files from `.spectri/canonical/` to all agent directories (`.claude/`, `.qwen/`, `.gemini/`, `.opencode/`). Commands may be format-converted (e.g., markdown to TOML for Qwen/Gemini). Skills are copied as-is. Context files (AGENTS.md → QWEN.md, GEMINI.md, etc.) are synced to non-Claude agents.

**Related commands:** `spectri sync-commands` syncs commands and skills only. `spectri sync-context` syncs context files only. `spectri sync-canonical` runs both.

## Core Principles

The following principles are defined in `spectri/constitution.md`: Work Cycle, Specification-First Development, Test-First Imperative, Specs Reflect Reality, Commit-Per-Spec-Folder Rule.

### Phases vs Stages

**Stages** are physical folder locations (`00-backlog/` through `05-archived/`). **Phases** are logical workflow states derived from document completion in `meta.json`. A spec in `01-drafting/` can be in "planning" or "tasking" phase.

### Check Threads Before Starting Work

Before starting work, check `spectri/coordination/threads/` for existing continuation context and handoff notes.

### Architecture Decisions

When discussing architectural changes or significant decisions, consider creating an RFC (`/spec.rfc`) to explore options before committing to an ADR.

## Components

| Type | Path |
|------|------|
| Specs | `spectri/specs/` |
| Issues | `spectri/issues/` |
| ADRs | `spectri/adr/` |
| RFCs | `spectri/rfc/` |
| Research | `spectri/research/` |
| Reviews | `spectri/coordination/reviews/` |
| Constitution | `spectri/constitution.md` |
| Threads | `spectri/coordination/threads/` |
| Prompts | `spectri/coordination/prompts/` |
| LLM Plans | `spectri/coordination/llm-plans/` |
| Brainstorms | `spectri/coordination/brainstorms/` |
