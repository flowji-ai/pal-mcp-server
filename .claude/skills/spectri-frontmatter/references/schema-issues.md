# Issues Schema

Must also include the common `metadata:` fields.

```yaml
status: open                    # enum: open | resolved
priority: medium                # enum: critical | high | medium | low
created_by_user: ostiimac       # human user who created the issue
opened: 2026-02-22              # YYYY-MM-DD
related_specs: []               # list of spec numbers
related_tests: []               # list of test file paths
related_files: []               # list of related file paths
metadata:
  date_created: "2026-02-22T17:00:00+11:00"
  created_by: "hostname"
```

| Field | Required | Notes |
|-------|----------|-------|
| `status` | Yes | Only `open` or `resolved` |
| `priority` | Yes | |
| `created_by_user` | Yes | Human user, not agent |
| `opened` | Yes | Date-only format |
| `related_specs` | No | Empty list if none |
| `related_tests` | No | Empty list if none |
| `related_files` | No | Empty list if none |

Mutations: `create-issue.sh`, `resolve-issue.sh`. MUST NOT hand-edit status or dates.
