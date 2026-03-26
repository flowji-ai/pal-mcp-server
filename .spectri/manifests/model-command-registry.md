---
Date Created: 2026-01-25T10:50:00+11:00
Date Updated: 2026-02-18T19:00:00+11:00
created_by: Claude Vermilion Pangolin 0734
updated_by: Claude Coral Axolotl 1855
---

# Command Model Registry

**Status: Suspended (ADR-0021)**

Model injection is currently disabled. All commands use the agent's session default model. The registry table is empty — the sync pipeline reads this file and injects nothing when no rows exist.

## Registry Table

| Command | Claude | OpenCode | Copilot | Gemini | Qwen |
|---------|--------|----------|---------|--------|------|

## Related

- ADR: `spectri/adr/0021-suspend-command-model-injection.md`
- Spec: `spectri/specs/04-deployed/024-command-model-selection/`
- Sync script: `src/spectri_cli/sync/commands.py`
