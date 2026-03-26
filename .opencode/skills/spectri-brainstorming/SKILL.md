---
name: spectri-brainstorming
description: "Use when the user asks to brainstorm, explore options, think through an idea, compare approaches, weigh up alternatives, consider pros and cons, or evaluate different directions for a feature, design, or change."
metadata:
  version: "1.0"
  date-created: "2026-03-05"
  date-updated: "2026-03-05"
  created-by: "claude-opus-4-6"
  managed-by: "spectri"
  ships-with-product: "true"
  spectri-pattern: "TODO"
---

# Spectri Brainstorming

Every brainstorm produces a persistent document — a folder with `BRAINSTORM.md` plus any supporting material gathered during exploration.

<HARD-GATE>
MUST NOT invoke any implementation skill, write any code, or take any implementation action until the brainstorm process is complete and the user has approved a direction. This applies to EVERY project regardless of perceived simplicity.
</HARD-GATE>

## Anti-Pattern: "This Is Too Simple To Need A Design"

Every project goes through this process. A config change, a single-function utility, a TODO list — all of them. "Simple" projects are where unexamined assumptions cause the most wasted work. The design can be short (a few sentences for truly simple projects), but you MUST present it and get approval.

## Steps

<IMPORTANT>
**Before starting work on the steps below:**

1. Read the detailed instructions for each step in the sections that follow
2. Create a TodoWrite item for every step in this list

**MUST NOT modify this file to check off steps.**
</IMPORTANT>

- [ ] 1. Explore project context
- [ ] 2. Ask clarifying questions
- [ ] 3. Propose 2-3 approaches
- [ ] 4. Present and validate design
- [ ] 5. Create brainstorm document
- [ ] 6. Quality review
- [ ] 7. Commit brainstorm document
- [ ] 8. Transition to next artefact

### Step 1: Explore project context

Check the current project state — files, docs, recent commits. Understand what exists before proposing changes.

### Step 2: Ask clarifying questions

Ask questions one at a time to understand purpose, constraints, and success criteria. Prefer multiple choice when possible. Only one question per message — if a topic needs more exploration, break it into multiple questions.

### Step 3: Propose approaches

Present 2-3 different approaches with trade-offs. Lead with your recommendation and explain why. Use mermaid diagrams where they help clarify thinking.

### Step 4: Present and validate design

Present the design section by section. Scale each section to its complexity — a few sentences if straightforward, up to 200-300 words if nuanced. Ask after each section whether it looks right.

Cover: architecture, components, data flow, error handling, testing.

### Step 5: Create brainstorm document

```bash
bash .spectri/scripts/spectri-trail/create-brainstorm.sh --topic "topic-slug" --title "Title"
```

The script creates `spectri/coordination/brainstorms/<topic>/BRAINSTORM.md` with frontmatter and stages it. Fill in the document with the exploration results — context, questions investigated, approaches considered, recommendation, and final decision.

The folder is a workspace — add supporting files as needed.

### Step 6: Quality review

Launch 3 sub-agents to review the brainstorm document before committing. See `references/quality-review.md` for review scopes (decision clarity, completeness, relevance) and agent-specific instructions.

Each reviewer simulates being the agent who must implement the chosen direction.

<HARD-GATE>
Do not commit the brainstorm until all review feedback is addressed. Loop on feedback: agree and fix, disagree and explain, or escalate to the user.
</HARD-GATE>

### Step 7: Commit brainstorm document

Stage and commit the brainstorm document.

### Step 8: Transition

The brainstorm output determines the next step:

| Outcome | Next action |
|---------|-------------|
| Feature to build | `/spec.specify` to create a spec |
| Decision to record | `/spec.adr` to create an ADR |
| Further investigation | `spectri-research` skill |
| Prompt for another agent | `spectri-prompts` skill |

No resolve script exists for brainstorms. Edit the `status` field directly in frontmatter to `resolved` when the design decision is final.

If transitioning to code work, use the `spectri-code-change` skill for commit bundle obligations.

## Key Principles

- **One question at a time** — don't overwhelm with multiple questions
- **Multiple choice preferred** — easier to answer than open-ended when possible
- **YAGNI ruthlessly** — remove unnecessary features from all designs
- **Explore alternatives** — always propose 2-3 approaches before settling
- **Incremental validation** — present design, get approval before moving on
- **Be flexible** — go back and clarify when something doesn't make sense

**Terminal state:** Brainstorm document committed with approved direction, or design decision transitioned to the appropriate next artefact.
