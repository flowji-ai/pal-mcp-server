---
Date Created: {{DATE_ISO}}
Date Updated: {{DATE_ISO}}
Title: {{TITLE}}
Source: {{SOURCE}}
---

# Plan: {{TITLE}}

## Context

[What situation requires this plan]

## Approach

[The implementation strategy]

## Steps

1. [Step 1]
2. [Step 2]
3. [Step 3]
4. **Plan completion review** — When all previous steps are complete, launch 3 sub-agents to verify: (a) each step's outcome matches its stated goal, (b) the execution log is complete with verification evidence, (c) changes across steps are consistent with each other. Address all feedback before resolving.

   **Agent-specific instructions:**
   - **Claude Code:** 2 Claude sub-agents + 1 Qwen sub-agent via PAL MCP server. PAL fallback: if PAL is unavailable, run all 3 as Claude sub-agents and log the fallback.
   - **OpenCode:** 3 GLM sub-agents.
   - **Other agents:** Use available sub-agent mechanism, or execute the 3 review scopes sequentially.

## Open Questions

- [Question 1]

## Execution Log
