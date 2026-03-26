# [PROMPTS/] AGENT HANDOFF PROMPTS
<!-- target: spectri/coordination/prompts/ -->

Persistent handoff prompts that coordinate work across agent sessions. A prompt captures a task in enough detail that any agent can pick it up and execute it without prior context.

## Prompt Lifecycle

- **Created** — Agent writes prompt file describing task, inputs, constraints, and expected outputs
- **Accepted** — Receiving agent reads and confirms understanding before starting
- **Implemented** — Work done, prompt moved to `resolved/`

Use the `spectri-threads` skill for continuation context (in-flight state). Use prompts here for discrete, self-contained tasks handed to another agent.

## File Naming

`YYYY-MM-DD-[slug].md` — kebab-case slug describing the task.
