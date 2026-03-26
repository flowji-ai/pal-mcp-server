# LLM Plans Schema

Must also include the common `metadata:` fields.

```yaml
metadata:
  date_created: "..."
  created_by_user: ostiimac
```

LLM plans have minimal frontmatter. Additional fields are optional and vary by plan:

| Field | Required | Notes |
|-------|----------|-------|
| `title` | No | Plan title |
| `original` | No | Path to original source file |
| `source` | No | Path to originating prompt |

Mutations: `create-llm-plan.sh`, `resolve-llm-plan.sh`.
