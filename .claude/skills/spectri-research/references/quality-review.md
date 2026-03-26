# Research Quality Review

A pre-commit review of the research document. Each reviewer simulates being the decision-maker who will act on these research findings — they need accurate, well-sourced, and actionable information.

## When This Applies

After completing the research and populating the document, before committing. Only applies when saving a file — chat answers skip this gate.

## Review Philosophy

> Simulate being the consumer of this artifact. Imagine you are the decision-maker who will act on these research findings. You need to trust the accuracy of the information, understand the trade-offs, and know what action to take. Walk through every section and ask: "Could I make a decision based on this?"

Each reviewer independently applies this discipline to their assigned scope.

## Review Scopes

### Scope 1 — Answer quality

Check whether findings address the defined research questions:

- Do findings directly answer the questions that were defined?
- Are recommendations actionable — is the next step clear (adopt, defer, reject, monitor)?
- Are trade-offs between options well explained?
- Are limitations of the research acknowledged?

### Scope 2 — Evidence quality

Check whether claims are substantiated:

- Are sources cited for factual claims?
- Are claims verifiable — could the reader check the sources?
- Are there unsupported conclusions or speculative assertions?
- Is the evidence current and relevant?

### Scope 3 — Relevance

Check for content that does not serve the decision-maker:

- Are there tangential findings that don't serve the defined questions?
- Is there padding or filler content?
- Is information proportional to its importance for the decision?
- Does every section contribute to answering the research questions?

## Agent-Specific Instructions

### Claude Code

Launch 3 sub-agents in parallel: 2 Claude sub-agents + 1 Qwen sub-agent (via PAL MCP server).

| Sub-agent | Scope | Model |
|-----------|-------|-------|
| 1 | Answer quality | Claude (native sub-agent) |
| 2 | Evidence quality | Claude (native sub-agent) |
| 3 | Relevance | Qwen (via PAL `chat` tool) |

**PAL fallback:** If PAL is unavailable, run Sub-agent 3 as a Claude sub-agent instead. Log the fallback.

For the Qwen sub-agent via PAL, use the `chat` tool with the review scope as the prompt and include the research content inline.

### OpenCode (GLM)

Launch 3 GLM sub-agents in parallel, one per scope.

| Sub-agent | Scope | Model |
|-----------|-------|-------|
| 1 | Answer quality | GLM (native sub-agent) |
| 2 | Evidence quality | GLM (native sub-agent) |
| 3 | Relevance | GLM (native sub-agent) |

### Other Agents

Launch 3 sub-agents using whatever mechanism is available. All 3 scopes must be covered. If the agent cannot launch sub-agents, execute the 3 review scopes sequentially in the main context.

## Providing Context to Sub-agents

Each sub-agent needs:

1. The full research file content
2. The scope-specific prompt (from the relevant scope section above)
3. The review philosophy statement (the simulation discipline)

## Handling Review Feedback

After all 3 sub-agents return:

1. **Agree and fix** — revise the research content before committing.
2. **Disagree and explain** — document why the feedback does not apply.
3. **Escalate** — if the feedback reveals a fundamental problem, ask the user before proceeding.

Do not commit the research until all review feedback is addressed.
