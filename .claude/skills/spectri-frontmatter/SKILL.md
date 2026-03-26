---
name: spectri-frontmatter
description: "Use when creating or updating YAML frontmatter on Spectri artefacts (issues, RFCs, ADRs, threads, prompts, research, reviews, brainstorms, LLM plans, specs, skills, commands)."
metadata:
  version: "1.0"
  date-created: "2026-03-05"
  date-updated: "2026-03-05"
  created-by: "claude-opus-4-6"
  managed-by: "spectri"
  ships-with-product: "true"
  spectri-pattern: "TODO"
---

# Spectri Frontmatter

Schema reference for all Spectri artefact frontmatter. All keys snake_case, all metadata values quoted strings. Generate timestamps with `bash .spectri/scripts/shared/get-timestamp.sh`.

## Common Fields

Every artefact type includes a `metadata:` block with these universal fields:

```yaml
metadata:
  date_created: "2026-03-05T10:00:00+11:00"   # ISO 8601 — required
  date_updated: "2026-03-05T10:00:00+11:00"   # omit for immutable artefacts
  created_by: "hostname-or-agent"               # run hostname — required
```

## Per-Artefact Schemas

Load the schema file for the artefact type you are working with:

| Artefact | Schema |
|----------|--------|
| Issues | `references/schema-issues.md` |
| RFCs | `references/schema-rfcs.md` |
| ADRs | `references/schema-adrs.md` |
| Threads | `references/schema-threads.md` |
| Prompts | `references/schema-prompts.md` |
| Research | `references/schema-research.md` |
| Reviews | `references/schema-reviews.md` |
| Brainstorms | `references/schema-brainstorms.md` |
| LLM Plans | `references/schema-llm-plans.md` |
| Specs | `references/schema-specs.md` |
| Skills | `references/schema-skills.md` |
| Commands | `references/schema-commands.md` |

## Mutation Rules

<CRITICAL>
MUST NOT hand-edit frontmatter directly on artefacts that have create/resolve scripts. Route all mutations through the appropriate script. Scripts enforce correct field values, enums, and timestamps.
</CRITICAL>

| Operation | Method |
|-----------|--------|
| Create issue | `.spectri/scripts/spectri-quality/create-issue.sh` |
| Resolve issue | `.spectri/scripts/spectri-quality/resolve-issue.sh` |
| Create thread | `.spectri/scripts/spectri-trail/create-thread.sh` |
| Resolve thread | `.spectri/scripts/spectri-trail/resolve-thread.sh` |
| Create LLM plan | `.spectri/scripts/spectri-trail/create-llm-plan.sh` |
| Resolve LLM plan | `.spectri/scripts/spectri-trail/resolve-llm-plan.sh` |
| Create prompt | `.spectri/scripts/spectri-trail/create-prompt.sh` |
| Resolve prompt | `.spectri/scripts/spectri-trail/resolve-prompt.sh` |
| Create ADR | `.spectri/scripts/spectri-trail/create-adr.sh` |
| Create RFC | `.spectri/scripts/spectri-trail/create-rfc.sh` |
| Resolve RFC | `.spectri/scripts/spectri-trail/resolve-rfc.sh` |
| Create research | `.spectri/scripts/spectri-trail/create-research.sh` |
| Create review | `.spectri/scripts/spectri-trail/create-review.sh` |
| Create brainstorm | `.spectri/scripts/spectri-trail/create-brainstorm.sh` |
| Update spec meta | `/spec.update-meta` |

If no script exists for the mutation you need, edit frontmatter directly but follow the schema exactly.

**Terminal state:** Frontmatter written or updated conforming to the per-artefact schema.
