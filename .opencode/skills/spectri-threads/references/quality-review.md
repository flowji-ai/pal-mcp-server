# Thread Quality Review

A pre-commit review of the thread document. Each reviewer simulates being an agent picking up this thread cold to resume the work — they have never seen this session, this codebase, or this conversation before.

## When This Applies

After populating the thread content and before committing. This review evaluates the **thread document itself** — whether it contains enough context for zero-context resumption.

## Review Philosophy

> Simulate being the consumer of this artifact. Imagine you are picking it up cold — you are an agent assigned to resume this work. You have never seen the session that created this thread. Walk through every section and ask: "Could I resume this work right now?"

Each reviewer independently applies this discipline to their assigned scope.

## Review Scopes

### Scope 1 — Resumability

Simulate being the resuming agent. Check:

- Is there enough context about what was being attempted for a cold start?
- Are next actions specific enough to execute without guessing?
- Are commit hashes included for completed work?
- Is the boundary between completed and unfinished work clear?
- Are file paths and artifact references specific enough to locate?
- Could you understand the current state without reading the full git history?

### Scope 2 — Relevance

Check for content that does not serve the resuming agent:

- Is there irrelevant content from the current session that doesn't inform resumption?
- Are there tangential topics that distract from the core unfinished work?
- Are any sections excessively verbose when a brief summary would suffice?
- Does the thread focus on what REMAINS, not what HAPPENED?

### Scope 3 — Actionability

Check whether the thread enables immediate action:

- Are next actions specific enough to start working immediately?
- Are open questions answerable — or do they need the original session's context to understand?
- Are pending decisions stated with enough context to make the decision?
- Is the TODO section actionable?

## Agent-Specific Instructions

### Claude Code

Launch 3 sub-agents in parallel: 2 Claude sub-agents + 1 Qwen sub-agent (via PAL MCP server).

| Sub-agent | Scope | Model |
|-----------|-------|-------|
| 1 | Resumability | Claude (native sub-agent) |
| 2 | Relevance | Claude (native sub-agent) |
| 3 | Actionability | Qwen (via PAL `chat` tool) |

**PAL fallback:** If PAL is unavailable, run Sub-agent 3 as a Claude sub-agent instead. Log the fallback.

For the Qwen sub-agent via PAL, use the `chat` tool with the review scope as the prompt and include the thread content inline.

### OpenCode (GLM)

Launch 3 GLM sub-agents in parallel, one per scope.

| Sub-agent | Scope | Model |
|-----------|-------|-------|
| 1 | Resumability | GLM (native sub-agent) |
| 2 | Relevance | GLM (native sub-agent) |
| 3 | Actionability | GLM (native sub-agent) |

### Other Agents

Launch 3 sub-agents using whatever mechanism is available. All 3 scopes must be covered. If the agent cannot launch sub-agents, execute the 3 review scopes sequentially in the main context.

## Providing Context to Sub-agents

Each sub-agent needs:

1. The full thread file content
2. The scope-specific prompt (from the relevant scope section above)
3. The review philosophy statement (the simulation discipline)

## Handling Review Feedback

After all 3 sub-agents return:

1. **Agree and fix** — revise the thread content before committing.
2. **Disagree and explain** — document why the feedback does not apply.
3. **Escalate** — if the feedback reveals a fundamental problem, ask the user before proceeding.

Do not commit the thread until all review feedback is addressed.
