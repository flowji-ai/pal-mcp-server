# Brainstorm Quality Review

A pre-commit review of the brainstorm document. Each reviewer simulates being the agent who must implement the chosen direction — they need a clear recommendation with well-explained trade-offs.

## When This Applies

After creating and populating the brainstorm document, before committing. This review evaluates the **brainstorm document itself** — whether it captures the exploration and decision clearly enough for implementation.

## Review Philosophy

> Simulate being the consumer of this artifact. Imagine you are the agent who must implement the chosen direction. You have never seen this conversation or the exploration that led to the decision. Walk through every section and ask: "Do I understand what was decided and why?"

Each reviewer independently applies this discipline to their assigned scope.

## Review Scopes

### Scope 1 — Decision clarity

Check whether the recommendation is clear and well-supported:

- Is the chosen direction unambiguous?
- Are trade-offs between alternatives well explained?
- Is the rationale for the chosen direction sufficient — would you be convinced?
- Are rejected alternatives documented with reasons for rejection?

### Scope 2 — Completeness

Check whether the exploration was thorough:

- Were enough alternatives explored (at least 2-3)?
- Are constraints documented?
- Are assumptions stated explicitly?
- Are success criteria defined for the chosen direction?

### Scope 3 — Relevance

Check for content that does not serve the implementing agent:

- Is there padding or filler content?
- Are there tangential sections that don't inform the decision?
- Is the document proportional to the complexity of the decision?

## Agent-Specific Instructions

### Claude Code

Launch 3 sub-agents in parallel: 2 Claude sub-agents + 1 Qwen sub-agent (via PAL MCP server).

| Sub-agent | Scope | Model |
|-----------|-------|-------|
| 1 | Decision clarity | Claude (native sub-agent) |
| 2 | Completeness | Claude (native sub-agent) |
| 3 | Relevance | Qwen (via PAL `chat` tool) |

**PAL fallback:** If PAL is unavailable, run Sub-agent 3 as a Claude sub-agent instead. Log the fallback.

For the Qwen sub-agent via PAL, use the `chat` tool with the review scope as the prompt and include the brainstorm content inline.

### OpenCode (GLM)

Launch 3 GLM sub-agents in parallel, one per scope.

| Sub-agent | Scope | Model |
|-----------|-------|-------|
| 1 | Decision clarity | GLM (native sub-agent) |
| 2 | Completeness | GLM (native sub-agent) |
| 3 | Relevance | GLM (native sub-agent) |

### Other Agents

Launch 3 sub-agents using whatever mechanism is available. All 3 scopes must be covered. If the agent cannot launch sub-agents, execute the 3 review scopes sequentially in the main context.

## Providing Context to Sub-agents

Each sub-agent needs:

1. The full brainstorm file content
2. The scope-specific prompt (from the relevant scope section above)
3. The review philosophy statement (the simulation discipline)

## Handling Review Feedback

After all 3 sub-agents return:

1. **Agree and fix** — revise the brainstorm content before committing.
2. **Disagree and explain** — document why the feedback does not apply.
3. **Escalate** — if the feedback reveals a fundamental problem, ask the user before proceeding.

Do not commit the brainstorm until all review feedback is addressed.
