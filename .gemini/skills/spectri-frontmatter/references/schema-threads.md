# Threads Schema

Must also include the common `metadata:` fields.

```yaml
title: "Thread title"
status: active                  # enum: active | resolved
context: spec-specific          # enum: spec-specific | general | constitution
spec: spec-slug                 # required for spec-specific context
metadata:
  date_created: "..."
  created_by_user: ostiimac
```

| Field | Required | Notes |
|-------|----------|-------|
| `title` | Yes | 3-7 words describing unfinished work |
| `status` | Yes | `active` or `resolved` |
| `context` | Yes | Determines folder routing |
| `spec` | Conditional | Required when context is `spec-specific` |

Mutations: `create-thread.sh`, `resolve-thread.sh`.
