---
name: spectri-todos
description: "Use when asked to add a TODO, or when triaging, reordering, or cleaning up items in TODO.md."
metadata:
  version: "1.0"
  date-created: "2026-03-05"
  date-updated: "2026-03-05"
  created-by: "claude-opus-4-6"
  managed-by: "spectri"
  ships-with-product: "true"
  spectri-pattern: "TODO"
---

# Spectri TODOs

Quick capture and organisation of TODO items in `spectri/TODO.md`. TODOs are informal — no frontmatter, no lifecycle, no formal artefact status.

## Adding a TODO

When the user says "add that as a TODO" or similar:

1. Ask for priority:
   - `!!` = Priority One (urgent)
   - `!` = Priority Two (important)
   - unmarked = Other Tasks
2. Edit `spectri/TODO.md` directly — add the item to the correct section as a checkbox: `- [ ] !! Item text`

No script needed. Direct file edit.

## Triaging and Reordering

When asked to clean up, triage, or reorder TODOs:

```bash
bash .spectri/scripts/spectri-trail/reorder-todos.sh
```

The script moves checked items to a Completed section and sorts active items into priority sections by marker. Use `--dry-run` to preview changes.

## Escalation

During triage, some items may deserve more formal tracking:

| If the item is... | Route to |
|-------------------|----------|
| Substantive work needing investigation | `/spec.issue` |
| A pre-decision exploration | `/spec.rfc` |
| A discrete task for another agent | `spectri-prompts` skill |
| A feature needing specification | `/spec.specify` |

Escalation is a suggestion during triage, not automatic. The user decides.

**Terminal state:** TODO added to the correct priority section, or TODO list reordered and triaged.
