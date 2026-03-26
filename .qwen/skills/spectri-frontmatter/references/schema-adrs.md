# ADRs Schema

Must also include the common `metadata:` fields.

```yaml
id: ADR-NNNN                    # sequential ID
title: "Decision title"
status: Proposed                # enum: Proposed | Accepted | Superseded | Deprecated
feature: spec-slug              # related spec slug
spec: ../../specs/.../spec.md   # relative path to spec
plan: ../../specs/.../plan.md   # relative path to plan
metadata:
  date_created: "..."
  created_by_user: ostiimac
```

| Field | Required | Notes |
|-------|----------|-------|
| `id` | Yes | `ADR-NNNN` format |
| `title` | Yes | |
| `status` | Yes | Four valid values only |
| `feature` | No | Spec slug if tied to a feature |
| `spec` | No | Relative path |
| `plan` | No | Relative path |

Mutations: `create-adr.sh`.
