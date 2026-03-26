# Research Schema

Must also include the common `metadata:` fields.

```yaml
type: architectural             # freeform: architectural | tooling | pattern | integration | custom
status: complete                # enum: complete | in-progress | stub
metadata:
  date_created: "..."
  date_updated: "..."
  created_by_user: ostiimac
```

| Field | Required | Notes |
|-------|----------|-------|
| `type` | Yes | Common values listed above, custom values allowed |
| `status` | Yes | Three valid values |

Mutations: `create-research.sh`. No resolve script — research has no resolve lifecycle.
