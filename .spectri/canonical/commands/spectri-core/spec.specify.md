---
managed_by: spectri
description: "Create or update the feature specification from a natural language feature description."
family: spectri-core
origin:
  source: github-spec-kit
  upstream_url: https://github.com/github/spec-kit/blob/main/templates/commands/specify.md
  adaptations: "Renamed speckit→spectri, added branchless mode support, added checkpoint automation"
injections_applied:
  - user-input
  - frontmatter-update
  - summary-creation
  - meta-update
  - finalization-verification
build_info:
  built_at: 2026-03-26T10:24:04Z
  manifest_version: 1.1.0
---
# Create Feature Specification

<!-- INJECT: post-frontmatter -->

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

> **AGENT DIRECTIVE**: You are executing this command workflow, NOT modifying this command file. Follow the "Implementation Steps" section below to execute the requested operation. Do NOT attempt to edit files in `src/command-bases/` or rebuild command infrastructure.


## Purpose

Create a technology-agnostic specification from a natural language feature description.

**Default behavior (Interactive Mode)**: Present user stories one at a time for approval, reducing cognitive overload and catching misunderstandings early in the spec creation process.

**Batch Mode**: Use `--batch` flag to generate complete spec in one pass (original behavior) for experienced users who know exactly what they want.

**Discovery Mode (Default in Interactive)**: Before generating stories, the agent conducts a conversational walkthrough to elicit trigger, interaction flow, output, actors, and lifecycle. Bypassed with `--skip-discovery` or automatically skipped when the initial description already contains all required elements.

**Key learning**: Interactive approval enables iterative refinement. Users can approve, revise, or reject each story, and revise earlier stories with automatic conflict detection. This prevents the common problem of users being overwhelmed by complete specs and not reading them carefully.

## Outline

The text the user typed after `/spec.specify` in the triggering message **is** the feature description. Assume you always have it available in this conversation even if `$ARGUMENTS` appears literally below. Do not ask the user to repeat it unless they provided an empty command.

<!-- SPECTRI:v1:INTERACTIVE-MODE START: spec=039-interactive-workflow-design -->
**Interactive Mode (Default)**: Present user stories one at a time for approval, reducing cognitive overload and catching misunderstandings early.

**Batch Mode (Escape Hatch)**: Use `--batch` flag to generate complete spec in one pass (original behavior). Good for experienced users who know exactly what they want.

**Check for `--batch` flag**: If the arguments contain `--batch`, skip interactive mode and generate the complete spec at once. Remove the flag from the feature description before processing.
<!-- SPECTRI:v1:INTERACTIVE-MODE END -->

<!-- SPECTRI:v1:BRANCHLESS-MODE-SUPPORT START: spec=002-branchless-first-workflow -->
**Default behavior**: Specs are created on the current branch without creating a feature branch. This is the common case when capturing specs for future work.

**Check for `--with-branch` flag**: If the arguments contain `--with-branch`, create a feature branch (steps 1-2 below). Use this only when you plan to implement immediately. Remove the flag from the feature description before processing.

Given that feature description, do this:

<!-- SPECTRI:v1:BACKLOG-PROMOTION START: spec=backlog-stage -->
0. **Check for backlog item promotion**:

   Before creating a new spec, check if the user is pointing at an existing backlog item. A backlog item is identified by:
   - A spec number or folder name that resolves to `spectri/specs/00-backlog/NNN-slug/`
   - An explicit path to a folder in `00-backlog/`

   **Detection**: Search `spectri/specs/00-backlog/` for a matching folder:
   ```bash
   # By number (e.g., "042")
   find spectri/specs/00-backlog/ -maxdepth 1 -type d -name "${SPEC_NUM}*" 2>/dev/null
   # By name (e.g., "042-my-feature")
   ls -d spectri/specs/00-backlog/${SPEC_NAME} 2>/dev/null
   ```

   **If a backlog item is found**, execute the promotion path:

   a. Read the existing `notes.md` or `brief.md` content from the backlog folder. This content becomes input context for the specification process — use it to inform story generation and functional requirements.

   b. Move the folder from `00-backlog/` to `01-drafting/` using `git mv` to preserve history:
      ```bash
      git mv spectri/specs/00-backlog/NNN-slug spectri/specs/01-drafting/NNN-slug
      ```

   c. Create `spec.md` in the promoted folder using the spec template:
      ```bash
      cp .spectri/templates/spectri-core/spec-template.md spectri/specs/01-drafting/NNN-slug/spec.md
      ```
      Replace frontmatter placeholders (ISO_TIMESTAMP, AGENT_SESSION_ID, FEATURE NAME, ###-feature-name).

   d. Create `implementation-summaries/` and `assets/` subdirectories if they don't exist:
      ```bash
      mkdir -p spectri/specs/01-drafting/NNN-slug/implementation-summaries
      touch spectri/specs/01-drafting/NNN-slug/implementation-summaries/.gitkeep
      mkdir -p spectri/specs/01-drafting/NNN-slug/assets
      touch spectri/specs/01-drafting/NNN-slug/assets/.gitkeep
      ```

   e. The original `notes.md` or `brief.md` stays in the folder as historical context — do NOT delete it.

   f. Set SPEC_FILE to `spectri/specs/01-drafting/NNN-slug/spec.md` and FEATURE_DIR accordingly.

   g. Stage the moved files: `git add spectri/specs/01-drafting/NNN-slug/`

   h. Continue to step 3 (skip steps 1-2 since the folder already exists with a number).

   **If no backlog item is found**, proceed to step 1 (normal spec creation).
<!-- SPECTRI:v1:BACKLOG-PROMOTION END -->

1. **(Default) Calculate spec number without branch creation**:

   a. Generate a concise short name (2-4 words):
      - Analyze the feature description and extract the most meaningful keywords
      - Use action-noun format when possible (e.g., "add-user-auth", "fix-payment-bug")
      - Preserve technical terms and acronyms (OAuth2, API, JWT, etc.)
      - Keep it concise but descriptive enough to understand the feature at a glance

   b. Get the next available spec number using the centralized script:
      ```bash
      .spectri/scripts/shared/get-next-spec-number.sh
      ```
      This returns a zero-padded 3-digit number (e.g., `056`).

   d. **Scaffold the spec using the script**:
      ```bash
      .spectri/scripts/spectri-core/create-spec.sh --scaffold-only \
        --number <NUMBER> --short-name "<short-name>" \
        --feature-name "<Feature Name>" \
        --session-id "<Your Session ID>" \
        "<feature description>"
      ```
      This creates the spec directory, subdirectories, and `spec.md` from the template with all frontmatter placeholders replaced.

      **Optional contracts/ subfolder**: If user specified `--contracts` flag:
      ```bash
      mkdir -p spectri/specs/<NUMBER>-<short-name>/contracts
      touch spectri/specs/<NUMBER>-<short-name>/contracts/.gitkeep
      ```

   e. **Create meta.json** for folder-level metadata:
      - Load `.spectri/templates/spectri-core/meta-template.json`
      - Use `jq` or `sed` to replace placeholders safely:
        ```bash
        sed -e "s|\[ISO_TIMESTAMP\]|$(date -Iseconds)|g" \
            -e "s|\[AGENT_SESSION_ID\]|Your Session ID|g" \
            .spectri/templates/spectri-core/meta-template.json > "spectri/specs/<NUMBER>-<short-name>/meta.json"
        ```
      - Ensure the file is valid JSON after creation.

   f. Set SPEC_FILE to `spectri/specs/<NUMBER>-<short-name>/spec.md`

   g. Continue to step 3
<!-- SPECTRI:v1:BRANCHLESS-MODE-SUPPORT END -->

2. **(--with-branch mode only) Create feature branch**:

   Skip this step unless `--with-branch` was specified.

   a. Generate a concise short name (2-4 words) using rules from step 1a

   b. First, fetch all remote branches to ensure we have the latest information:
      ```bash
      git fetch --all --prune
      ```

   c. Find the highest feature number across all sources for the short-name:
      - Remote branches: `git ls-remote --heads origin | grep -E 'refs/heads/[0-9]+-<short-name>$'`
      - Local branches: `git branch | grep -E '^[* ]*[0-9]+-<short-name>$'`
      - Specs directories: Check for directories matching pattern in `spectri/specs/0[0-5]-*/[0-9][0-9][0-9]-<short-name>`

   d. Determine the next available number:
      - Extract all numbers from all three sources
      - Find the highest number N
      - Use N+1 for the new branch number

   e. Run the script `.spectri/scripts/spectri-core/create-spec.sh --json "$ARGUMENTS"` with the calculated number and short-name:
      - Pass `--number N+1` and `--short-name "your-short-name"` along with the feature description
      - Bash example: `.spectri/scripts/spectri-core/create-spec.sh --json "$ARGUMENTS" --json --number 5 --short-name "user-auth" "Add user authentication"`
      - PowerShell example: `.spectri/scripts/spectri-core/create-spec.sh --json "$ARGUMENTS" -Json -Number 5 -ShortName "user-auth" "Add user authentication"`

   **IMPORTANT**:
   - Check all three sources (remote branches, local branches, specs directories) to find the highest number
   - Only match branches/directories with the exact short-name pattern
   - If no existing branches/directories found with this short-name, start with number 1
   - You must only ever run this script once per feature
   - The JSON is provided in the terminal as output - always refer to it to get the actual content you're looking for
   - The JSON output will contain BRANCH_NAME and SPEC_FILE paths
   - For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot")

3. Load `.spectri/templates/spectri-core/spec-template.md` to understand required sections. Also read `spectri/constitution.md` if it exists — the constitution provides governance rules (especially Article III: Test-First Imperative) that should guide how user stories and functional requirements are structured.

<!-- SPECTRI:v1:INTERACTIVE-MODE-DETECTION START: spec=039-interactive-workflow-design -->
3a. **Mode Detection and Routing**:

   **Parse arguments to determine mode**:
   - Extract `--batch` flag from arguments (case-insensitive match)
   - Extract `--with-branch` flag from arguments
   - Extract `--contracts` flag from arguments (creates contracts/ subfolder for API specs)
   - Extract `--skip-discovery` flag from arguments (bypasses discovery walkthrough, proceeds directly to story generation)
   - Remove all flags from feature description before processing
   - If `--batch` is present: USE BATCH MODE (proceed to step 4-batch) — no discovery
   - If `--batch` is NOT present AND `--skip-discovery` is NOT present: USE INTERACTIVE MODE with discovery (proceed to step 4-interactive — Phase 0 runs first)
   - If `--batch` is NOT present AND `--skip-discovery` IS present: USE INTERACTIVE MODE without discovery (proceed to step 4-interactive — skip Phase 0, begin at Phase 1)

   **Check for existing draft session** (interactive mode only):
   - Look for `.draft-stories.md` in FEATURE_DIR
   - If draft file exists:
     - Read frontmatter to get `Last Updated` timestamp and `Status`
     - Calculate age: `current_time - last_updated`
     - If age < 24 hours: Ask "Found in-progress session from [TIME_AGO]. Resume? (yes/no)"
     - If age >= 24 hours: Ask "Found abandoned session from [TIME_AGO]. Resume or start fresh? (resume/fresh)"
     - If user chooses "resume":
       - Load approved stories from draft file
       - Load `Current Story` number to continue from
       - Skip to step 4-interactive substep "Interactive Story Generation Loop" at Current Story
     - If user chooses "fresh" or "no":
       - Delete existing draft file
       - Proceed to step 4-interactive from beginning
   - If no draft file exists: Proceed to step 4-interactive from beginning

<!-- SPECTRI:v1:INTERACTIVE-MODE-DETECTION END -->

4-interactive. **INTERACTIVE MODE - User Story Approval Workflow**:

   <!-- SPECTRI:v1:INTERACTIVE-STORY-GENERATION START: spec=039-interactive-workflow-design -->

   <!-- SPECTRI:v1:DISCOVERY-WALKTHROUGH START: spec=011-specify-module, rfc=RFC-2026-02-17 -->

   **Phase 0: Discovery Walkthrough**

   **Skip this phase entirely if**: `--skip-discovery` was set OR `--batch` was set. Jump directly to Phase 1.

   **REQUIRED**: Load `references/feature-discovery-guide.md` from the `spectri-user-story-gherkin` skill before beginning. This provides the full step-by-step procedure, question wording, and probing patterns.

   1. Create `feature-discovery.md` in FEATURE_DIR:
      ```bash
      .spectri/scripts/spectri-core/create-feature-discovery.sh \
        --output "FEATURE_DIR/feature-discovery.md" \
        --feature-name "<Feature Name>" \
        --session-id "<Your Session ID>"
      ```

   2. Conduct discovery following the guide. Write findings to `feature-discovery.md` after each step — do not wait until the end. Carry the completed document forward into Phase 1 as enriched context for story generation.

   <!-- SPECTRI:v1:DISCOVERY-WALKTHROUGH END -->

   **Phase 1: Initialize Session**

   **WHY INTERACTIVE MODE**: Users often don't read complete specs carefully, leading to misunderstood requirements. By presenting one story at a time and waiting for explicit approval, we ensure each requirement is reviewed and understood before proceeding.

   1. Parse user description from Input
      - If empty: ERROR "No feature description provided. Please provide a description of the feature you want to specify."
   2. Extract key concepts from description
      - Identify: actors, actions, data, constraints
   3. Initialize session state:
      - Create empty list: `approved_stories = []`
      - Set counter: `current_story_number = 1`
      - Determine estimated total stories (3-7 based on feature complexity)

   **TEACHING POINT**: Don't generate all stories upfront. Generate ONE story, wait for approval, then generate the next. This reduces cognitive load and enables course correction early.

   **Phase 2: Interactive Story Generation Loop**

   **REQUIRED**: Before generating any user stories, load and apply the `spectri-user-story-gherkin` skill. This skill provides the five principles (Substance Over Mechanics, Quality Over Existence, Single Story Ownership, Integration Thinking, Concrete Validation), Gherkin anti-patterns, INVEST checks, and pre-submission quality criteria that MUST govern every story you write. If the skill is not already in context, read it from `.claude/skills/spectri-user-story-gherkin/SKILL.md` (or the equivalent path for your agent platform).

   For each user story (starting at `current_story_number`):

   1. **Generate ONE user story** based on feature description and previously approved stories:
      - Title: Short, descriptive (e.g., "Add Items to Cart")
      - Priority: P1 (critical), P2 (important), P3 (nice-to-have)
      - Description: What the user wants to accomplish and why
      - Independent Test: How to verify this story works standalone
      - Acceptance Scenarios: 3-5 Given/When/Then scenarios (testable, specific)

   2. **Present the story to user**:
      ```
      ## User Story [N] - [Title] (Priority: [P1/P2/P3])

      [Full story description]

      **Why this priority**: [Justification]

      **Independent Test**: [Test description]

      **Acceptance Scenarios**:
      1. **Given** [context], **When** [action], **Then** [outcome]
      2. **Given** [context], **When** [action], **Then** [outcome]
      [... 3-5 scenarios total ...]

      ---

      **Your response**: approve, reject, or provide revision feedback
      ```

   3. **STOP AND WAIT for user response** - Do not proceed until user provides input

   **CRITICAL**: This is the core of interactive mode. You MUST wait for user input before generating the next story. Do NOT generate multiple stories in one response. One story → wait → next story.

   4. **Parse user response** (case-insensitive, flexible):

   **TEACHING POINT**: Be flexible with response parsing. Users may say "yes", "approve", "lgtm", or just "ok". Match intent, not exact syntax. When uncertain, ask for clarification rather than guessing.

      **Approval patterns** (proceed to next story):
      - "approve", "a", "yes", "y", "ok", "good", "lgtm", "looks good", "✓", "accept"
      - Any affirmative response indicating acceptance

      **Rejection patterns** (skip story, proceed to next):
      - "reject", "skip", "no", "n", "remove", "delete", "pass"
      - Any negative response indicating removal

      **Revision patterns** (update current story, re-present):
      - "revise: [feedback]", "change: [feedback]", "update: [feedback]", "modify: [feedback]"
      - Any response containing modification instructions

      **Back-revision patterns** (edit earlier approved story):
      - "go back to story [N]", "revise story [N]", "change story [N]", "edit story [N]"
      - "back to [N]", "fix story [N]"

      **Ambiguous response** (ask for clarification):
      - If response doesn't match any pattern above
      - Reply: "I didn't understand your response. Please respond with one of:
        - 'approve' to accept this story
        - 'revise: [your changes]' to modify it
        - 'reject' to skip this story
        - 'go back to story [N]' to edit an earlier story"
      - WAIT for clarified response, then re-parse

   5. **Handle response**:

      **If APPROVED**:
      - Add story to `approved_stories` list
      - Save to draft file (see Draft File Management below)
      - Confirm: "✅ Story [N] approved."
      - Increment `current_story_number`
      - If more stories needed: Return to step 1 (generate next story)
      - If all stories complete: Proceed to "Phase 3: Finalize Spec"

      **If REJECTED**:
      - Do NOT add to `approved_stories`
      - Confirm: "⏭️ Story [N] skipped."
      - Increment `current_story_number`
      - If more stories needed: Return to step 1 (generate next story)
      - If all stories complete: Proceed to "Phase 3: Finalize Spec"

      **If REVISION REQUESTED** (current story):
      - Update story based on user feedback
      - Re-present the revised story: "## User Story [N] - [Title] [REVISED]"
      - Return to step 3 (WAIT for response again)
      - Do NOT increment `current_story_number` until approved or rejected

      **If BACK-REVISION REQUESTED** (earlier story):
      - Identify target story number [M] from user response
      - If M is not in approved_stories: "Story [M] doesn't exist. Current approved stories: [list]"
      - Update Story M based on user feedback
      - **Trigger re-analysis** (see Story Revision Re-analysis below)
      - After re-analysis complete, return to current story [N]

   **Draft File Management** (save after each approval):

   Create/update `FEATURE_DIR/.draft-stories.md`:

   ```markdown
   ---
   Date Created: [ISO_TIMESTAMP]
   Last Updated: [ISO_TIMESTAMP]
   Feature: [feature description]
   Current Story: [current_story_number]
   Status: in_progress
   ---

   # Draft User Stories

   ## Story 1 - [Title] (Status: approved)
   [Full story content with all sections]

   ## Story 2 - [Title] (Status: approved)
   [Full story content with all sections]

   ## Story [N] - [Title] (Status: pending)
   [Current story awaiting approval]
   ```

   **Story Revision Re-analysis** (when back-revising Story M while on Story N):

   **WHY RE-ANALYSIS**: When users revise an earlier story, later stories may contradict it. Example: Story 2 says "admin authentication", but Story 4 assumes "OAuth login". If user changes Story 2 to "OAuth", Story 4 needs review. This prevents internal contradictions.

   1. Display: "Updating Story [M] and re-analyzing Stories [M+1] to [N-1] for consistency..."
   2. For each story from M+1 to N-1:

   **TEACHING POINT**: Don't auto-fix conflicts. Present them to the user with suggested resolutions. The user knows their domain better than you - they should make the final call on how to resolve conflicts.
      - Extract key entities from revised Story M (actors, actions, data, flows)
      - Check if current story references any of Story M's entities
      - If references found:
        - Identify potential conflicts (dependency, scope, priority)
        - Generate conflict report:
          ```
          ⚠️ Story [X] may be affected by changes to Story [M]:

          **Conflict**: [Description of inconsistency]

          **Suggested Resolution**: [How to fix Story X]

          **Updated Story [X]**: [Revised version]

          Approve this change? (yes/no/modify)
          ```
        - WAIT for user response
        - If "yes": Update Story X in approved_stories
        - If "no": Keep Story X unchanged
        - If "modify": Ask for user's version, then update
   3. After all affected stories processed, confirm: "✅ Re-analysis complete. Continuing from Story [N]."
   4. Return to presenting Story N

   **Phase 3: Finalize Spec**

   When all stories are generated and approved:

   1. Compile complete spec.md from approved_stories and feature description
   2. Follow existing spec generation rules from step 4-batch (FRs, Success Criteria, etc.)
   3. Write spec.md to FEATURE_DIR
   4. Delete draft file: `rm FEATURE_DIR/.draft-stories.md`
   5. Proceed to step 5 (validation)

   <!-- SPECTRI:v1:INTERACTIVE-STORY-GENERATION END -->

4-batch. **BATCH MODE - Original Complete Generation**:

   <!-- SPECTRI:v1:BATCH-MODE-PRESERVED START: spec=039-interactive-workflow-design -->
   This is the original behavior - generate complete spec in one pass without pausing.
   <!-- SPECTRI:v1:BATCH-MODE-PRESERVED END -->

   **REQUIRED**: Before generating any user stories, load and apply the `spectri-user-story-gherkin` skill. This skill provides the five principles (Substance Over Mechanics, Quality Over Existence, Single Story Ownership, Integration Thinking, Concrete Validation), Gherkin anti-patterns, INVEST checks, and pre-submission quality criteria that MUST govern every story you write. If the skill is not already in context, read it from `.claude/skills/spectri-user-story-gherkin/SKILL.md` (or the equivalent path for your agent platform).

   Follow this execution flow:

    1. Parse user description from Input
       If empty: ERROR "No feature description provided"
    2. Extract key concepts from description
       Identify: actors, actions, data, constraints
    3. For unclear aspects:
       - Make informed guesses based on context and industry standards
       - Only mark with [NEEDS CLARIFICATION: specific question] if:
         - The choice significantly impacts feature scope or user experience
         - Multiple reasonable interpretations exist with different implications
         - No reasonable default exists
       - **LIMIT: Maximum 3 [NEEDS CLARIFICATION] markers total**
       - Prioritize clarifications by impact: scope > security/privacy > user experience > technical details
    4. Fill User Scenarios & Testing section
       If no clear user flow: ERROR "Cannot determine user scenarios"

       **CRITICAL - Testable Acceptance Scenarios (Article III: Test-First Imperative)**:

       WHY this matters: Tests drive implementation. Vague scenarios lead to vague code. Clear, testable scenarios enable TDD workflow where tests are written first and implementation makes them pass.

       Each user story MUST include acceptance scenarios in Given/When/Then format:
       - **Given** [precondition/context]: What state exists before the action
       - **When** [action/trigger]: What the user or system does
       - **Then** [expected outcome]: What measurable result occurs

       Good vs Bad Examples:

       ❌ **BAD** (vague, untestable):
       - "User should be able to log in"
       - "System handles errors gracefully"
       - "Performance is acceptable"

       ✅ **GOOD** (specific, testable):
       - **Given** user has valid credentials, **When** user submits login form, **Then** user sees dashboard within 2 seconds
       - **Given** user enters invalid password 3 times, **When** 4th attempt fails, **Then** account locks for 30 minutes and user receives email notification
       - **Given** 1000 concurrent users, **When** all submit search queries, **Then** 95% receive results within 1 second

       Think like a tester writing tests BEFORE code exists: What exact behavior proves this feature works?

    5. Generate Functional Requirements
       Each requirement must be testable and unambiguous
       Every FR must map to at least one measurable acceptance scenario
       Use reasonable defaults for unspecified details (document assumptions in Assumptions section)

       **Validation Check**: For each FR, ask "Could I write a failing test for this right now?"
       If answer is "no" or "maybe", the requirement is too vague - make it specific and measurable.

    6. Define Success Criteria
       Create measurable, technology-agnostic outcomes
       Include both quantitative metrics (time, performance, volume) and qualitative measures (user satisfaction, task completion)
       Each criterion must be verifiable without implementation details
    7. Identify Key Entities (if data involved)
    8. Return: SUCCESS (spec ready for planning)

5. Edit the already-scaffolded spec.md at SPEC_FILE, populating each section with concrete details derived from the feature description (arguments). Do NOT delete any headings or rewrite the file from scratch — preserve the template structure.

<!-- INJECT: post-header -->

## Frontmatter Update

After creating or modifying documents, update the YAML frontmatter:

- **Date Created**: Set on new documents (ISO 8601 with timezone)
- **Date Updated**: Update on every modification
- **created_by** / **updated_by**: Use `$AGENT_SESSION_ID` format

Example:
```yaml
---
Date Created: 2026-01-14T15:30:00+11:00
Date Updated: 2026-01-14T16:45:00+11:00
created_by: Claude Cerulean Pangolin 1420
updated_by: Claude Vermillion Axolotl 1645
---
```

6. **Specification Quality Validation**: After writing the initial spec, validate it against quality criteria:

   a. **Create Spec Quality Checklist**: Generate a checklist file at `FEATURE_DIR/checklists/requirements.md` using the checklist template structure with these validation items:

      ```markdown
      # Specification Quality Checklist: [FEATURE NAME]

      **Purpose**: Validate specification completeness and quality before proceeding to planning
      **Created**: [DATE]
      **Feature**: [Link to spec.md]

      ## Content Quality

      - [ ] No implementation details (languages, frameworks, APIs)
      - [ ] Focused on user value and business needs
      - [ ] Written for non-technical stakeholders
      - [ ] All mandatory sections completed

      ## Requirement Completeness

      - [ ] No [NEEDS CLARIFICATION] markers remain
      - [ ] Requirements are testable and unambiguous
      - [ ] All acceptance scenarios use Given/When/Then format
      - [ ] All functional requirements include measurable acceptance criteria
      - [ ] Each acceptance scenario is specific enough to write a test for
      - [ ] Success criteria are measurable
      - [ ] Success criteria are technology-agnostic (no implementation details)
      - [ ] All acceptance scenarios are defined
      - [ ] Edge cases are identified
      - [ ] Scope is clearly bounded
      - [ ] Dependencies and assumptions identified

      ## Feature Readiness

      - [ ] All functional requirements have clear acceptance criteria
      - [ ] User scenarios cover primary flows
      - [ ] Feature meets measurable outcomes defined in Success Criteria
      - [ ] No implementation details leak into specification

      ## Notes

      - Items marked incomplete require spec updates before `/spectri.clarify` or `/spectri.plan`
      ```

   b. **Run Validation Check**: Review the spec against each checklist item:
      - For each item, determine if it passes or fails
      - Document specific issues found (quote relevant spec sections)

   c. **Handle Validation Results**:

      - **If all items pass**: Mark checklist complete and proceed to step 6

      - **If items fail (excluding [NEEDS CLARIFICATION])**:
        1. List the failing items and specific issues
        2. Update the spec to address each issue
        3. Re-run validation until all items pass (max 3 iterations)
        4. If still failing after 3 iterations, document remaining issues in checklist notes and warn user

      - **If [NEEDS CLARIFICATION] markers remain**:
        1. Extract all [NEEDS CLARIFICATION: ...] markers from the spec
        2. **LIMIT CHECK**: If more than 3 markers exist, keep only the 3 most critical (by scope/security/UX impact) and make informed guesses for the rest
        3. For each clarification needed (max 3), present options to user in this format:

           ```markdown
           ## Question [N]: [Topic]

           **Context**: [Quote relevant spec section]

           **What we need to know**: [Specific question from NEEDS CLARIFICATION marker]

           **Suggested Answers**:

           | Option | Answer | Implications |
           |--------|--------|--------------|
           | A      | [First suggested answer] | [What this means for the feature] |
           | B      | [Second suggested answer] | [What this means for the feature] |
           | C      | [Third suggested answer] | [What this means for the feature] |
           | Custom | Provide your own answer | [Explain how to provide custom input] |

           **Your choice**: _[Wait for user response]_
           ```

        4. **CRITICAL - Table Formatting**: Ensure markdown tables are properly formatted:
           - Use consistent spacing with pipes aligned
           - Each cell should have spaces around content: `| Content |` not `|Content|`
           - Header separator must have at least 3 dashes: `|--------|`
           - Test that the table renders correctly in markdown preview
        5. Number questions sequentially (Q1, Q2, Q3 - max 3 total)
        6. Present all questions together before waiting for responses
        7. Wait for user to respond with their choices for all questions (e.g., "Q1: A, Q2: Custom - [details], Q3: B")
        8. Update the spec by replacing each [NEEDS CLARIFICATION] marker with the user's selected or provided answer
        9. Re-run validation after all clarifications are resolved

   d. **Update Checklist**: After each validation iteration, update the checklist file with current pass/fail status

7. Report completion with spec file path, checklist results, and readiness for the next phase (`/spectri.clarify` or `/spectri.plan`). If `--with-branch` was used, also report the branch name.

<!-- INJECT: post-execution -->

---

**MANDATORY COMPLETION STEPS** - Execute ALL before ending this command:

1. **Create implementation summary**:
   ```bash
   bash .spectri/scripts/spectri-trail/create-implementation-summary.sh \
     --spec "$SPEC_FOLDER" \
     --scope "spec.md" \
     --session-id "$AGENT_SESSION_ID" \
     --agent-name "$AGENT_NAME" \
     --session-start "$SESSION_START"
   ```

2. **Commit all changes**:
   `git add . && git commit -m "feat(spec-NNN): [description]"`

Do NOT skip these steps. The summary script also updates meta.json automatically.

## Update meta.json

After document creation, update the spec's meta.json:

```bash
.spectri/scripts/shared/update-spec-meta.sh \
  --spec "$SPEC_FOLDER" \
  --update-doc "spec.md" \
  --updated-by "$AGENT_SESSION_ID"
```

## General Guidelines

## Quick Guidelines

- Focus on **WHAT** users need and **WHY**.
- Avoid HOW to implement (no tech stack, APIs, code structure).
- Written for business stakeholders, not developers.
- DO NOT create any checklists that are embedded in the spec. That will be a separate command.

### Section Requirements

- **Mandatory sections**: Must be completed for every feature
- **Optional sections**: Include only when relevant to the feature
- When a section doesn't apply, remove it entirely (don't leave as "N/A")

### For AI Generation

When creating this spec from a user prompt:

1. **Make informed guesses**: Use context, industry standards, and common patterns to fill gaps
2. **Document assumptions**: Record reasonable defaults in the Assumptions section
3. **Limit clarifications**: Maximum 3 [NEEDS CLARIFICATION] markers - use only for critical decisions that:
   - Significantly impact feature scope or user experience
   - Have multiple reasonable interpretations with different implications
   - Lack any reasonable default
4. **Prioritize clarifications**: scope > security/privacy > user experience > technical details
5. **Think like a tester**: Every vague requirement should fail the "testable and unambiguous" checklist item
6. **Common areas needing clarification** (only if no reasonable default exists):
   - Feature scope and boundaries (include/exclude specific use cases)
   - User types and permissions (if multiple conflicting interpretations possible)
   - Security/compliance requirements (when legally/financially significant)

**Examples of reasonable defaults** (don't ask about these):

- Data retention: Industry-standard practices for the domain
- Performance targets: Standard web/mobile app expectations unless specified
- Error handling: User-friendly messages with appropriate fallbacks
- Authentication method: Standard session-based or OAuth2 for web apps
- Integration patterns: RESTful APIs unless specified otherwise

### Success Criteria Guidelines

Success criteria must be:

1. **Measurable**: Include specific metrics (time, percentage, count, rate)
2. **Technology-agnostic**: No mention of frameworks, languages, databases, or tools
3. **User-focused**: Describe outcomes from user/business perspective, not system internals
4. **Verifiable**: Can be tested/validated without knowing implementation details

**Good examples**:

- "Users can complete checkout in under 3 minutes"
- "System supports 10,000 concurrent users"
- "95% of searches return results in under 1 second"
- "Task completion rate improves by 40%"

**Bad examples** (implementation-focused):

- "API response time is under 200ms" (too technical, use "Users see results instantly")
- "Database can handle 1000 TPS" (implementation detail, use user-facing metric)
- "React components render efficiently" (framework-specific)
- "Redis cache hit rate above 80%" (technology-specific)
<!-- INJECT: post-finalization -->

## Finalization Checklist

Before completing this command, verify:

- [ ] **Implementation summary created**: `bash .spectri/scripts/spectri-trail/create-implementation-summary.sh --spec "$SPEC_FOLDER" --scope "[scope]"`
- [ ] **meta.json updated** (when applicable): `bash .spectri/scripts/shared/update-spec-meta.sh --spec "$SPEC_FOLDER" --updated-by "[session-id]"` (Only update meta.json when command modifies spec state, not during implementation phases)
- [ ] **Work committed to git**: Commit using appropriate commands
