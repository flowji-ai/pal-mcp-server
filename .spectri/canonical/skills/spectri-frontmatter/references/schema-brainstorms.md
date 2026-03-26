# Brainstorms Schema

Must also include the common `metadata:` fields.

```yaml
topic: "brainstorm topic"
status: active                  # enum: active | resolved
metadata:
  date_created: "..."
  date_updated: "..."
  created_by_user: ostiimac
```

| Field | Required | Notes |
|-------|----------|-------|
| `topic` | Yes | Short description of what's being explored |
| `status` | Yes | `active` while exploring, `resolved` when design decisions are made |

Mutations: `create-brainstorm.sh`.
