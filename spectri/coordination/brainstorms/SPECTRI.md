# [BRAINSTORMS/] DESIGN EXPLORATION
<!-- target: spectri/coordination/brainstorms/ -->

Brainstorms capture design exploration before implementation. Every brainstorm produces a persistent document with context, questions investigated, approaches considered, and a final recommendation.

## When to Use

Create brainstorms when:
- Exploring options for a feature, design, or change
- Comparing approaches, weighing pros and cons
- Evaluating different directions before committing to implementation
- Clarifying requirements and constraints with the user

Brainstorms are required before ANY implementation work — no matter how simple the project appears. The design can be short (a few sentences) but MUST be presented and approved.

## Folder Structure

Each brainstorm lives in its own folder: `spectri/coordination/brainstorms/<topic>/BRAINSTORM.md`

The folder is a workspace — add supporting files as needed alongside BRAINSTORM.md.

## Brainstorm Lifecycle

- **Active** — Exploration in progress (`status: active` in frontmatter)
- **Resolved** — Decision made, design complete (`status: resolved` in frontmatter)

No resolve script exists — edit the `status` field directly in frontmatter when complete.

## Transition to Next Artifact

The brainstorm output determines the next action:

| Outcome | Next action |
|---------|-------------|
| Feature to build | `/spec.specify` to create a spec |
| Decision to record | `/spec.adr` to create an ADR |
| Further investigation | `spectri-research` skill |
| Prompt for another agent | `spectri-prompts` skill |
