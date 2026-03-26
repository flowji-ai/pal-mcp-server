# Skills Schema (Source)

Source skills in `src/spectri_cli/canonical/skills/`. Deployed skills have `ships_with_product` and `managed_by` stripped.

```yaml
name: skill-name                # required — matches folder name
description: "Use when ..."     # required — trigger condition
compatibility: Requires Claude Code  # if using Claude-only frontmatter fields
metadata:
  version: "1.0"               # major.minor quoted string
  date-created: "2026-03-05"   # YYYY-MM-DD
  date-updated: "2026-03-05"   # YYYY-MM-DD
  created-by: "hostname"       # run hostname
  ships-with-product: true     # build-time flag, stripped on deploy
  managed-by: spectri          # build-time flag, stripped on deploy
```

| Field | Required | Notes |
|-------|----------|-------|
| `name` | Yes | Must match folder name, kebab-case, max 64 chars |
| `description` | Yes | Must start with "Use when" |
| `compatibility` | Conditional | Required if using Claude-only fields |
| `metadata.version` | Yes | Quoted string |
| `metadata.date-created` | Yes | |
| `metadata.created-by` | Yes | |

Audit fields (added after first audit):

| Field | Notes |
|-------|-------|
| `metadata.date-audited` | YYYY-MM-DD |
| `metadata.audited-by` | hostname |
