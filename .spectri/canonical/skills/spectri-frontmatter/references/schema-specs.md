# Specs Schema

Applies to `spec.md`, `plan.md`, and `tasks.md` within spec folders.

Must also include the common `metadata:` fields.

```yaml
metadata:
  date_created: "..."
  date_updated: "..."
  created_by_user: ostiimac
```

Spec frontmatter is minimal — most metadata lives in `meta.json` within the spec folder.

Mutations: `/spec.update-meta` for meta.json fields. Direct edit for spec/plan/tasks frontmatter following the schema above.
