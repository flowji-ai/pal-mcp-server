# [RFC/] REQUEST FOR COMMENTS
<!-- target: spectri/rfc/ -->

RFCs are pre-decision exploration documents for discussing new architectures, workflow changes, or major features before commitment. Nothing represents confirmed direction until status changes to "Implemented."

## When to Use

Create RFCs for:
- New system architectures or restructures
- Workflow changes affecting how agents work
- Major features requiring multiple implementation paths
- Uncertain direction requiring team discussion

**Requirements**: RFCs MUST explore at least two approaches. A single-solution RFC is an implementation guide, not an exploration document. NEVER reference non-existent spec numbers — use descriptive references for future work ("the planned auth system", not "spec 051"). Document type hierarchy: RFC (explore) → ADR (decide) → Spec (define) → Plan (implement).

Use ADRs for already-decided technical choices. Use threads for spec-specific continuation context.

## File Naming

Date-based with descriptive slug: `RFC-YYYY-MM-DD-slug.md`

## Required Structure

### Frontmatter
```yaml
---
Date Created: YYYY-MM-DDTHH:MM:SS+11:00
Date Updated: YYYY-MM-DDTHH:MM:SS+11:00
Status: Under Discussion | Converging | In Progress | Implemented | Rejected | Superseded
Type: System Architecture | Workflow | Feature | Process Change
Priority: High | Medium | Low
Prerequisites: []
Related ADRs: []
Related RFCs: []
Implementation: path/to/implementation-plan.md
---
```

**Frontmatter Notes:**
- `Implementation` field is optional — points to implementation plan when RFC reaches "In Progress"
- `Type: Process Change` is used for RFC-2026-01-31 (implementation summary template changes)
- `status: In Progress` and `status: Implemented` are used in actual practice

### Body Sections
1. **Context** — Background and current state
2. **Problem Statement** — Current limitations and pain points
3. **Proposed Directions** — Options being considered (numbered)
4. **Decision Criteria** — Factors for evaluating options
5. **Open Questions** — Unresolved issues needing discussion
6. **Prerequisites** — Work or decisions required before implementation
7. **Related Documents** — Specs, ADRs, research, RFCs
8. **Dated Discussion Sections** — Append new sections at bottom as discussion evolves
9. **Status History** — Table tracking status transitions
10. **Author & Contributors** (at end) — Who created, discussion date, who contributed

### Body Section Notes:
- Status History table shows full lifecycle: Under Discussion → Converging → In Progress → Implemented
- RFCs that are completed live in `spectri/rfc/resolved/` subfolder
- Final section includes author, discussion date, and contributors fields

## Dated Discussion Sections

Never delete previous content. Add new dated sections at bottom:

```markdown
## YYYY-MM-DD: Brief Description

[Summary of what was discussed, decisions made, what remains open]
```

This preserves evolution and prevents loss of reasoning.

## Status Lifecycle

- **Under Discussion** — Initial exploration, multiple options
- **Converging** — Discussion narrowed to preferred approach
- **In Progress** — Decision made, implementation in progress
- **Implemented** — Work completed, ADRs generated, moved to resolved/ folder
- **Rejected** — Proposal declined, preserved for context
- **Superseded** — Replaced by another RFC (theoretical, not used in practice)

**IMPORTANT:** "Implemented" is the terminal status per `resolve-rfc.sh` code. RFCs stay in active folder until implementation is complete, then move to `resolved/` folder.

**Staleness:** RFCs in "Under Discussion" for 60+ days without activity should be reviewed — advance, reject, or add a dated section explaining why they remain open.

## RFC Location

- **Active RFCs**: `spectri/rfc/`
- **Resolved RFCs**: `spectri/rfc/resolved/`

When an RFC reaches `Implemented` status, move it to `resolved/` subfolder.

## RFC vs ADR

RFCs explore. ADRs decide.

When an RFC is implemented:
- Create ADRs for significant decisions
- Update RFC status to "Implemented" with decision date
- Reference ADRs in RFC's "Related ADRs" field
