# [LLM-PLANS/] LLM PLANS
<!-- target: spectri/coordination/llm-plans/ -->

## Plan Location

New plans are created at root level: `spectri/coordination/llm-plans/YYYY-MM-DD-{agent}-{slug}.md`

The `--agent` flag determines the agent prefix in the filename (e.g., `claude`, `gemini`). Use the `create-llm-plan.sh` script or the `spectri-llm-plans` skill to create plans.

### Agent Subfolders

Agent subfolders (`claude-plans/`, `gemini-plans/`, etc.) exist for raw native plan archives — plans copied verbatim from `~/.claude/plans/` or `.opencode/plans/` before rewriting. Rewritten directional plans go to root `llm-plans/`, not agent subfolders.

### Resolution

Root-level plans resolve to `llm-plans/resolved/`. Legacy plans in agent subfolders resolve to `{agent}-plans/resolved/`.

## Prompts Folder

Prompts for agents live in `spectri/coordination/prompts/`. When referencing prompts in plan frontmatter, use relative path from memory root.
