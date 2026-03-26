# RFCs Schema

Must also include the common `metadata:` fields.

```yaml
status: Under Discussion        # enum: Under Discussion | Accepted | Superseded | Withdrawn
type: architectural             # freeform
prerequisites: []               # list of prerequisite RFC/ADR IDs
related_adrs: []                # list of related ADR IDs
metadata:
  date_created: "..."
  date_updated: "..."
  created_by_user: ostiimac
```

| Field | Required | Notes |
|-------|----------|-------|
| `status` | Yes | Four valid values only |
| `type` | Yes | Freeform string |
| `prerequisites` | No | Empty list if none |
| `related_adrs` | No | Empty list if none |

Mutations: `create-rfc.sh`, `resolve-rfc.sh`.
