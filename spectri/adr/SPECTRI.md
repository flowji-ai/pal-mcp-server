# [ADR/] ARCHITECTURE DECISION RECORDS
<!-- target: spectri/adr/ -->

ADRs capture significant architectural choices with rationale, consequences, and alternatives. They provide continuity across agent sessions and team members.

## When to Use

Create ADRs for:
- Cross-cutting technical decisions affecting multiple components
- Tool/library/framework choices with long-term impact
- Workflow changes that alter how system works
- Architectural patterns or structures

Use minor decisions within comments or implementation summaries.

## File Naming

Sequential numbering with descriptive slug: `####-slug.md` (0001-9999)

Note: Slug portion can be omitted for short titles.

## Required Structure

### Frontmatter
```yaml
---
# ADR Identification
id: ADR-####
title: Decision Title

# Status Tracking
status: Accepted | Rejected | Superseded | Obsolete
date: YYYY-MM-DD

# Context Linking
rfc: path/to/rfc.md
feature: NNN-feature-name
branch: branch-name
spec: relative/path/to/spec.md
plan: relative/path/to/plan.md

# Metadata
created_by: Agent Name (session-id)
updated_by: Agent Name (session-id)
---
```

**Frontmatter Notes:**
- `rfc` field references related RFC that generated this ADR
- Older files may use `source_rfc:` — should be updated to `rfc:`
- `created_by` may appear as `Agent: [name]` in newer files — both forms are valid

### Body Sections
1. **Context** — Problem or situation requiring decision
2. **Decision** — Chosen approach (concise, actionable)
3. **Consequences** — Positive (benefits) and Negative (drawbacks)
4. **Alternatives Considered** — Options evaluated and why rejected
5. **Implementation Notes** — Completion status, affected components, links to implementation plans
6. **Amended By** — Track when decisions were modified (partial amendments)
7. **References** — Related specs, RFCs, ADRs, external docs

**Body Section Notes:**
- "Implementation Notes" section documents completion status when ADR requires implementation work
- "Amended By" section (optional) tracks partial reversals or clarifications of original decision
- Final section may be named either "References" or "Related Decisions" depending on content

## Status Lifecycle

**Actual practice:** All ADRs in Spectri use `status: Accepted` only. Other statuses (Draft, Rejected, Superseded, Obsolete) exist in template but are not used in practice.

**Template statuses (for completeness):**
- **Accepted** — Implemented or committed (only status in actual use)
- **Rejected** — Decision declined (theoretical, not used in practice)
- **Superseded** — Replaced by newer ADR (theoretical, not used in practice)
- **Obsolete** — No longer relevant (system changed) (theoretical, not used in practice)

## Relationship to RFCs

RFCs explore options pre-decision. ADRs document final decisions. RFCs generate ADRs when accepted.

When an RFC reaches "Implemented" status and ADRs are created:
- Update RFC status to "Implemented" with decision date
- Reference ADRs in RFC's "Related ADRs" field
