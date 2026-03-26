# Prompts Schema

Must also include the common `metadata:` fields.

```yaml
status: pending                 # enum: pending | in-progress | complete
metadata:
  date_created: "..."
  created_by_user: ostiimac
```

| Field | Required | Notes |
|-------|----------|-------|
| `status` | Yes | Tracks lifecycle: pending → in-progress → complete |

Mutations: `create-prompt.sh`, `resolve-prompt.sh`.
