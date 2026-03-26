# [SPECS/] SPECS FOLDER
<!-- target: spectri/specs/ -->

## Stage Lifecycle

Specs move through numbered stage folders:
- `00-backlog/` - Pre-specification ideas (notes or briefs, no `spec.md`)
- `01-drafting/` - Initial specification
- `02-implementing/` - Implementation in progress
- `03-blocked/` - Blocked on dependencies
- `04-deployed/` - Feature deployed
- `05-archived/` - Legacy/retired

### Backlog Stage

`00-backlog/` holds ideas not yet ready for formal specification. Items use two document types:
- **`notes.md`** — Freeform capture. No template, no structure. Raw observations, brain dumps, meta-notes.
- **`brief.md`** — Structured enough to spec from. Light template with problem statement and directional requirements.

**Hard constraint**: No `spec.md` may exist in `00-backlog/`. `spec.md` only appears after promotion to `01-drafting/`.

**Promotion**: Run `/spec.specify` against a backlog item to promote it. The command moves the folder to `01-drafting/` via `git mv`, creates `spec.md`, and uses the existing notes/brief as input context. The original document stays in the folder as historical context.

**Branching**: By default, `/spec.specify` creates specs on the current branch — no feature branch is created. Use `--with-branch` only when you plan to implement immediately.

## Stage Management

When you move a spec to its next stage (e.g., draft → deployed), run `update-spec-meta.sh` to update metadata and move the folder automatically.

## Work Cycle

Every unit of work follows: Execute → Document → Update Meta → Commit. No skipping steps.

Implementation summaries are required for both documentation updates and code changes.

## Spec Anatomy

Each spec folder contains:
- `spec.md` - Feature specification
- `meta.json` - Metadata and status
- `implementation-summaries/` - Work documentation

## Deployed Specs Are Living Documents

**CRITICAL**: "Deployed" indicates WHERE a feature is (production), not WHETHER the spec is editable.

When a deployed feature changes, UPDATE its existing spec. Do NOT create new specs for the same feature. Only archived specs are read-only.

## Implementation Summaries

Implementation summaries are immutable audit trails. Once created, never edit them. To document additional work, create a NEW summary.

## Before Modifying Specs

Check `spectri/coordination/threads/<spec-number>*/` for continuation context and `spectri/specs/<spec-number>/AGENTS.md` for spec-specific notes before starting work.
