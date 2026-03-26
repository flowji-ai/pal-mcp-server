# Review Template

```yaml
---
type: architecture              # see type list in SKILL.md
status: complete                # draft | complete | partial
metadata:
  date_created: "ISO-8601"
  date_updated: "ISO-8601"
  created_by: "hostname"
---
```

## Body Structure by Type

Each review type has a distinct body structure. Consult `spectri/coordination/reviews/SPECTRI.md` for the authoritative per-type structures.

### Default structure (all types)

```markdown
# [Title]

## Summary
Scope and key findings at a glance.

## Findings
Detailed observations, grouped logically.

## Recommendations
Actionable next steps.
```

### Type-specific additions

| Type | Additional sections |
|------|-------------------|
| `architecture` | Current Architecture Map, Pain Points, Refactoring Proposals |
| `code-quality` | Current State, Findings (numbered), Quick Wins |
| `onboarding` | AGENTS.md Gaps, Spec Clarity Issues, Breakage Risk ranking |
| `comparative-analysis` | Purpose, Methodology, Key Insights |
| `pre-implementation-gate` | TBDs, Design Gaps, Actionability assessment |

### Optional: Triage Status

Add when the review produces actionable issues:

```markdown
## Triage Status
### Issues Created
### Already Tracked
### Resolved or Disproven
```

File naming: `YYYY-MM-DD-[topic]-review.md` (date-based) or `[topic]-review.md` (evergreen).
