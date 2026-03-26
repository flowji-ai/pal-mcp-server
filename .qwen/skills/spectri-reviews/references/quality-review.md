# Review Quality Review

A pre-commit review of the review document. Each reviewer simulates being the reader who will use this review to make decisions — they need actionable, evidence-backed findings.

## When This Applies

After creating and populating a review file, before committing. Only applies when a file is being persisted — chat-only reviews skip this gate.

## Review Philosophy

> Simulate being the consumer of this artifact. Imagine you are the reader who will use this review to make decisions. You need findings that are specific, backed by evidence, and actionable. Walk through every section and ask: "Could I act on this finding right now?"

Each reviewer independently applies this discipline to their assigned scope.

## Review Scopes

### Scope 1 — Insight value

Check whether findings are worth the reader's time:

- Are findings actionable — does each one lead to a clear next step?
- Are recommendations specific enough to implement?
- Is there padding — findings that state the obvious or add no value?
- Are findings prioritised by impact?

### Scope 2 — Evidence quality

Check whether claims are substantiated:

- Are claims backed by file paths and line references?
- Are there unsupported conclusions or vague assertions?
- Is the evidence sufficient to convince a skeptical reader?
- Are trade-offs acknowledged when recommending changes?

### Scope 3 — Completeness

Check whether the review covers its stated scope:

- Does the review address everything its type implies (architecture, code quality, spec, etc.)?
- Are there obvious areas within the stated scope that are missing?
- Are limitations of the review acknowledged?

## Agent-Specific Instructions

### Claude Code

Launch 3 sub-agents in parallel: 2 Claude sub-agents + 1 Qwen sub-agent (via PAL MCP server).

| Sub-agent | Scope | Model |
|-----------|-------|-------|
| 1 | Insight value | Claude (native sub-agent) |
| 2 | Evidence quality | Claude (native sub-agent) |
| 3 | Completeness | Qwen (via PAL `chat` tool) |

**PAL fallback:** If PAL is unavailable, run Sub-agent 3 as a Claude sub-agent instead. Log the fallback.

For the Qwen sub-agent via PAL, use the `chat` tool with the review scope as the prompt and include the review content inline.

### OpenCode (GLM)

Launch 3 GLM sub-agents in parallel, one per scope.

| Sub-agent | Scope | Model |
|-----------|-------|-------|
| 1 | Insight value | GLM (native sub-agent) |
| 2 | Evidence quality | GLM (native sub-agent) |
| 3 | Completeness | GLM (native sub-agent) |

### Other Agents

Launch 3 sub-agents using whatever mechanism is available. All 3 scopes must be covered. If the agent cannot launch sub-agents, execute the 3 review scopes sequentially in the main context.

## Providing Context to Sub-agents

Each sub-agent needs:

1. The full review file content
2. The scope-specific prompt (from the relevant scope section above)
3. The review philosophy statement (the simulation discipline)

## Handling Review Feedback

After all 3 sub-agents return:

1. **Agree and fix** — revise the review content before committing.
2. **Disagree and explain** — document why the feedback does not apply.
3. **Escalate** — if the feedback reveals a fundamental problem, ask the user before proceeding.

Do not commit the review until all review feedback is addressed.
