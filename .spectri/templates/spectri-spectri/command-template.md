---
description: [COMMAND_DESCRIPTION]
handoffs:               # Optional: Include only if command has natural next steps
  - label: [NEXT_STEP_LABEL]
    agent: [NEXT_COMMAND_NAME]
    prompt: [DEFAULT_PROMPT_FOR_HANDOFF]
---

<!--
  COMMAND TYPE: [Thinking/Orchestration/Hybrid]

  Thinking: Agent decisions significantly impact outcomes; requires judgment
  Orchestration: Executes standardized workflows with minimal interpretation
  Hybrid: Mixes strategic thinking with mechanical execution
-->

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

Goal: [CLEAR_STATEMENT_OF_WHAT_COMMAND_ACCOMPLISHES]

<!--
  Include any of the following as applicable:
  - Prerequisites (commands that should run first)
  - Dependencies on other specs/features
  - Important warnings or constraints
-->

Execution steps:

<!--
  STEP STRUCTURE:

  N. **Step title in bold**: Brief description
     - Sub-step or detail
     - Conditional: **If X**: do Y
     - Error condition: If fails, ERROR "message"

  REQUIREMENTS PER STEP:
  - Bold title
  - Clear action description
  - Error conditions where failure possible
  - Validation checkpoint if output critical

  FOR THINKING COMMANDS, include:
  - Decision frameworks with criteria
  - Transformation examples (input -> output)
  - Anti-patterns to avoid
  - "Why" context for major decisions

  FOR ORCHESTRATION COMMANDS:
  - Clear procedural steps
  - "Why" context for major steps
  - When deviation might be appropriate
-->

1. **[Step 1 Title]**: [Description]
   - [Sub-step or detail]
   - **If [condition]**: [action]
   - If fails, ERROR "[error message]"

2. **[Step 2 Title]**: [Description]
   - [Sub-step or detail]
   - Validation: [checkpoint description]

3. **[Step 3 Title]**: [Description]
   - [Sub-step or detail]

<!--
  FOR THINKING COMMANDS - Include pedagogical patterns as applicable:

  DECISION FRAMEWORK (when command requires evaluation):
  | Factor | Weight | Criteria |
  |--------|--------|----------|
  | [Factor 1] | High | [What makes this good/bad] |
  | [Factor 2] | Medium | [What to look for] |

  TRANSFORMATION EXAMPLES (when command transforms input):
  - Input: "[example input]" -> Output: "[expected output]"
  - Input: "[another input]" -> Output: "[expected output]"

  ANTI-PATTERNS (when common mistakes exist):
  - Don't [bad practice] because [reason]
  - Avoid [pitfall] which causes [problem]

  TAXONOMY (when systematic analysis needed):
  - Category A: [description]
  - Category B: [description]
-->

N. **[Final Step Title]**: [Description]
   - Summary output format:
     ```markdown
     ## [Command] Complete

     **[Key Output]**: [value]
     **[Status]**: [PASS/FAIL]

     **Next Steps**:
     1. [Suggested follow-up]
     2. [Another option]
     ```

<!--
  BEHAVIOR RULES - Delete or customize as needed:

  - If user provides incomplete information, prompt for required fields
  - If [condition is ambiguous], ask user to clarify
  - For Thinking commands, always include pedagogical patterns guidance
  - Reference existing [artifacts] as examples when helpful
  - Never [safety constraint]
-->

---

## References

<!--
  Include relevant documentation paths. Delete if not applicable.
-->

- Governing Spec: `spectri/specs/04-deployed/[SPEC_NUMBER]/spec.md`
- Command Authoring: `src/spectri_cli/canonical/skills/spectri-dev/references/command-authoring.md`
