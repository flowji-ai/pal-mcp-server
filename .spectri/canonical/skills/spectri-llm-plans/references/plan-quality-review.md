# Plan Quality Review

A pre-implementation review of the plan document, conducted before saving or executing. Each reviewer simulates being the implementing agent — walking through every step imagining they must execute it with zero codebase context.

## When This Applies

Before running the create script (creating workflow) or before proceeding to implementation (migrating workflow). This review evaluates the **plan document itself**, not the code it will produce.

## Review Philosophy

> Simulate being the consumer of this artifact. Imagine you are picking it up cold — you have never seen this codebase, this conversation, or this plan before. Walk through every step and ask: "Could I execute this right now?"

Each reviewer independently applies this discipline to their assigned scope.

## Review Scopes

Every quality review covers these 3 scopes, regardless of which agent runs it. How the sub-agents are launched varies by agent — see the agent-specific sections below.

### Scope 1 — Implementability

Simulate being the implementing agent. For each step, check:

- Are there gaps in context that would force the agent to guess?
- Are instructions ambiguous — could they be interpreted multiple ways?
- Are skill or command references present where needed?
- Does each step have defined success criteria (how does the agent know the step is done)?
- Are dependencies between steps stated explicitly?
- Are file paths or artifact references specific enough to locate?

### Scope 2 — Relevance and focus

Check for content that does not serve the implementing agent:

- Is there irrelevant background that does not inform any step?
- Are any steps excessively detailed beyond what an agent needs to act?
- Is there padding or filler content?
- Does any content duplicate what the referenced skill already covers?
- Is the scope boundary clear — does the plan say what it does NOT cover?

### Scope 3 — Feasibility and ordering

Check the plan's structure as an execution sequence:

- Are steps ordered correctly? Could any step fail because a prerequisite hasn't been completed?
- Are there missing prerequisite steps that the plan assumes are already done?
- Are any steps infeasible given the described context?
- Does every step have verification criteria (how to confirm it worked)?
- Are there circular dependencies between steps?

## Agent-Specific Instructions

### Claude Code

Launch 3 sub-agents in parallel. Model diversity is preferred: 2 Claude sub-agents + 1 Qwen sub-agent (via PAL MCP server).

| Sub-agent | Scope | Model |
|-----------|-------|-------|
| 1 | Implementability | Claude (native sub-agent) |
| 2 | Relevance and focus | Claude (native sub-agent) |
| 3 | Feasibility and ordering | Qwen (via PAL `chat` tool) |

**PAL fallback:** If PAL is unavailable (MCP server not running, connection error, or Qwen model not listed), run Sub-agent 3 as a Claude sub-agent instead. Log the fallback in the execution notes. Model diversity improves review quality but must not block plan creation.

For the Qwen sub-agent via PAL, use the `chat` tool with the review scope as the prompt and include the relevant file contents inline — PAL sub-agents cannot read local files directly.

### OpenCode (GLM)

Launch 3 GLM sub-agents in parallel, one per scope. OpenCode does not have PAL access, so all 3 sub-agents run as GLM.

| Sub-agent | Scope | Model |
|-----------|-------|-------|
| 1 | Implementability | GLM (native sub-agent) |
| 2 | Relevance and focus | GLM (native sub-agent) |
| 3 | Feasibility and ordering | GLM (native sub-agent) |

### Other Agents

If the creating agent is not Claude Code or OpenCode, launch 3 sub-agents using whatever sub-agent mechanism is available. All 3 scopes must be covered. If the agent cannot launch sub-agents, execute the 3 review scopes sequentially in the main context.

## Providing Context to Sub-agents

Each sub-agent needs:

1. The full plan file content
2. The scope-specific prompt (from the relevant scope section above)
3. The review philosophy statement (the simulation discipline)

## Handling Review Feedback

After all 3 sub-agents return:

1. **Agree and fix** — revise the plan content before proceeding. The plan is not yet saved, so edits are in the working draft.
2. **Disagree and explain** — document why the feedback does not apply. Include this reasoning in the plan's context or notes section if it informs the implementing agent.
3. **Escalate** — if the feedback reveals a fundamental problem with the plan's approach, ask the user before proceeding.

Do not proceed to the create script until all review feedback is addressed.
