# Prompt Quality Review

A pre-commit review of the prompt document. Each reviewer simulates being the agent receiving this prompt who must execute the task immediately — they have never seen this session, this codebase, or this conversation before.

## When This Applies

After writing the prompt content and before committing. This review evaluates the **prompt document itself** — whether it contains enough context for a zero-context agent to execute the task.

## Review Philosophy

> Simulate being the consumer of this artifact. Imagine you are picking it up cold — you are an agent who has just been handed this prompt and must begin work immediately. Walk through every section and ask: "Could I execute this task right now?"

Each reviewer independently applies this discipline to their assigned scope.

## Review Scopes

### Scope 1 — Executability

Simulate being the receiving agent. Check:

- Are all required inputs specified (file paths, specs, issues)?
- Is the expected output clearly defined?
- Are constraints and boundaries explicit?
- Are instructions unambiguous — could they be interpreted multiple ways?
- Are skill or command references present where needed?
- Could you start work immediately, or would you need to ask clarifying questions first?

### Scope 2 — Relevance

Check for content that does not serve the receiving agent:

- Is there unnecessary background context that doesn't inform the task?
- Is there padding or filler content?
- Are any sections excessively verbose when brevity would suffice?
- Does every piece of information contribute to task execution?

### Scope 3 — Completeness

Check whether the prompt enables immediate execution:

- Could the agent start work immediately without asking questions?
- What questions would the agent need answered first?
- Are there implicit assumptions that should be made explicit?
- Is the scope boundary clear — what is in and out of scope?

## Agent-Specific Instructions

### Claude Code

Launch 3 sub-agents in parallel: 2 Claude sub-agents + 1 Qwen sub-agent (via PAL MCP server).

| Sub-agent | Scope | Model |
|-----------|-------|-------|
| 1 | Executability | Claude (native sub-agent) |
| 2 | Relevance | Claude (native sub-agent) |
| 3 | Completeness | Qwen (via PAL `chat` tool) |

**PAL fallback:** If PAL is unavailable, run Sub-agent 3 as a Claude sub-agent instead. Log the fallback.

For the Qwen sub-agent via PAL, use the `chat` tool with the review scope as the prompt and include the prompt content inline.

### OpenCode (GLM)

Launch 3 GLM sub-agents in parallel, one per scope.

| Sub-agent | Scope | Model |
|-----------|-------|-------|
| 1 | Executability | GLM (native sub-agent) |
| 2 | Relevance | GLM (native sub-agent) |
| 3 | Completeness | GLM (native sub-agent) |

### Other Agents

Launch 3 sub-agents using whatever mechanism is available. All 3 scopes must be covered. If the agent cannot launch sub-agents, execute the 3 review scopes sequentially in the main context.

## Providing Context to Sub-agents

Each sub-agent needs:

1. The full prompt file content
2. The scope-specific prompt (from the relevant scope section above)
3. The review philosophy statement (the simulation discipline)

## Handling Review Feedback

After all 3 sub-agents return:

1. **Agree and fix** — revise the prompt content before committing.
2. **Disagree and explain** — document why the feedback does not apply.
3. **Escalate** — if the feedback reveals a fundamental problem, ask the user before proceeding.

Do not commit the prompt until all review feedback is addressed.
