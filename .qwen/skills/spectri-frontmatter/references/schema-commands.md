# Commands Schema (Source)

Source commands in `src/command-bases/`. Deployed commands have `ships_with_product` and `managed_by` stripped.

```yaml
description: "Command description"
family: spectri-core            # command family grouping
origin:
  source: spectri
injections_applied: []
build_info:
  built_at: "..."
  manifest_version: "1.0.0"
metadata:
  date_created: "..."
  created_by_user: ostiimac
  ships_with_product: true      # build-time flag, stripped on deploy
  managed_by: spectri           # build-time flag, stripped on deploy
```

| Field | Required | Notes |
|-------|----------|-------|
| `description` | Yes | |
| `family` | Yes | Command family grouping |
| `origin.source` | Yes | |
| `build_info` | Yes | Populated by build system |
