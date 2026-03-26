---
managed_by: spectri
description: "Execute the implementation planning workflow using the plan template to generate design artifacts."
family: spectri-core
origin:
  source: github-spec-kit
  upstream_url: https://github.com/github/spec-kit/blob/main/templates/commands/plan.md
  adaptations: "Renamed speckit→spectri, added branchless mode support, added checkpoint automation"
injections_applied:
  - user-input
  - frontmatter-update
  - summary-creation
  - meta-update
  - finalization-verification
build_info:
  built_at: 2026-03-26T01:25:58Z
  manifest_version: 1.1.0
---
# Create Implementation Plan

<!-- INJECT: post-frontmatter -->

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

> **AGENT DIRECTIVE**: You are executing this command workflow, NOT modifying this command file. Follow the "Implementation Steps" section below to execute the requested operation. Do NOT attempt to edit files in `src/command-bases/` or rebuild command infrastructure.


## Outline

<!-- SPECTRI:v1:BRANCHLESS-MODE-SUPPORT START: spec=002-branchless-first-workflow -->
1. **Setup**: Determine the spec folder and run setup script.

   a. **Check for spec argument**: If user provided a spec folder name (e.g., `011-global-custom-agents`), use it directly with `--spec` flag.

   b. **Check current branch**: Run `git rev-parse --abbrev-ref HEAD` to get current branch.
      - If branch matches pattern `NNN-feature-name`, use branch-based detection (no `--spec` needed)
      - If on `main` or other non-feature branch, proceed to step c

   c. **Branchless mode - find spec folder**:
      - List recent specs: `find spectri/specs/0[1-5]-*/ -maxdepth 1 -type d -name '[0-9][0-9][0-9]-*' 2>/dev/null | xargs ls -dt 2>/dev/null | head -5`
      - If only one spec exists, use it automatically
      - If multiple specs exist, ask user which spec to plan for
      - Pass chosen spec to setup script with `--spec` flag

   d. **Run setup script**:
      - With branch: `.spectri/scripts/spectri-core/create-plan-scaffold.sh --json`
      - Branchless: `.spectri/scripts/spectri-core/create-plan-scaffold.sh --json --spec <spec-folder>`

   Parse JSON for FEATURE_SPEC, IMPL_PLAN, SPECS_DIR, BRANCH. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").
<!-- SPECTRI:v1:BRANCHLESS-MODE-SUPPORT END -->

2. **Load context**: Read FEATURE_SPEC and `spectri/constitution.md`. Load IMPL_PLAN template (already copied).

2.5. **Phase Checkpoint** (skip if `--skip-checkpoint` flag present):

   **a. Check for skip flags**:
   - If `$ARGUMENTS` contains `--skip-checkpoint`: Skip this entire Phase Checkpoint section and proceed to step 3
   - If `.spectri/config.json` exists and has `plan.skip_phase_checkpoint: true`: Skip unless `--with-checkpoint` flag is present
   - If skipping, log message: "Phase checkpoint skipped via [flag/config]"

   **b. Extract implementation phases from spec**:

   Analyze FEATURE_SPEC to identify high-level implementation phases using this strategy:

   1. **Phase extraction strategy**:
      - Read User Stories section and identify P1 (priority 1) user stories
      - Each P1 user story often maps to a major phase or component
      - Examine Functional Requirements (FR-###) and group related ones
      - Identify dependencies to determine phase ordering

   2. **Phase grouping logic**:
      - Group related Functional Requirements into cohesive phases
      - Common grouping patterns:
        * Setup/Infrastructure (prerequisites, environment, database schema)
        * Core Logic (main business logic, algorithms, data processing)
        * Integration (API endpoints, external services, authentication)
        * Testing & Validation (test coverage, edge cases, documentation)
        * Polish (error handling, performance optimization, UX refinements)

   3. **Phase ordering logic**:
      - Order phases by dependencies: foundation → features → polish
      - Setup/infrastructure phases come first
      - Core logic before integration
      - Testing and polish come last

   4. **Flexible phase count logic**:
      - Calculate target phase count based on spec size:
        * Small implementations (1-2 user stories, <10 FRs): 3-5 phases
        * Medium implementations (3-5 user stories, 10-20 FRs): 5-10 phases
        * Large implementations (6+ user stories, 20+ FRs): 10-15 phases
      - **No hard limit**: If spec genuinely needs more phases, allow it
      - Better to have clear phases than artificially constrain

   5. **Phase naming conventions**:
      - Generate 2-4 word action-oriented names for each phase
      - Examples: "Setup Infrastructure", "Create API Endpoints", "Integrate Authentication"
      - Make names specific enough to understand scope
      - Use consistent verb patterns (Setup, Create, Implement, Integrate, Test)

   **c. Ambiguity detection** (proactive, before presenting phases):
   - If cannot extract at least 2 distinct phases from spec: Suggest running `/spec.clarify` first
   - Message: "Spec may be too ambiguous to extract meaningful phases. Consider running `/spec.clarify` first to resolve ambiguities."
   - If spec is sufficiently clear, proceed to next step

   **d. Check for existing plan.md with phases**:
   - If IMPL_PLAN already exists and contains an "Approved Implementation Phases" section:
   - Use AskUserQuestion tool to ask: "Existing phases found in plan.md. How would you like to proceed?"
   - Options:
     * "Regenerate phases" - Generate new phases and overwrite
     * "Reuse existing phases" - Keep existing phases and proceed to detailed planning
     * "Abort planning" - Stop the command
   - Handle response accordingly before proceeding

   **e. Present phases for user approval**:

   Format phase presentation as a clear table:

   ```markdown
   ## Implementation Phase Overview

   Based on [spec-name]/spec.md, here are the proposed implementation phases:

   | Phase | Name | Description |
   |-------|------|-------------|
   | 1 | [Phase Name] | [One-line description of what this phase accomplishes] |
   | 2 | [Phase Name] | [One-line description] |
   | 3 | [Phase Name] | [One-line description] |
   | ... | ... | ... |
   ```

   Use AskUserQuestion tool with structured options:
   ```json
   {
     "questions": [{
       "question": "Do you approve these implementation phases?",
       "header": "Phases",
       "options": [
         {
           "label": "Approve and proceed",
           "description": "Phases look correct, continue with detailed planning"
         },
         {
           "label": "Request changes",
           "description": "Modify specific phases before proceeding"
         },
         {
           "label": "Reject approach",
           "description": "Fundamentally disagree with direction"
         }
       ],
       "multiSelect": false
     }]
   }
   ```

   **f. Handle user response**:

   - **If "Approve and proceed"**:
     * Display message: "✅ Phases approved. Proceeding with detailed planning..."
     * Record approved phases in IMPL_PLAN under new section "Approved Implementation Phases"
     * Section format:
       ```markdown
       ## Approved Implementation Phases

       *Approved during planning checkpoint on [DATE]*

       1. **[Phase Name]**: [One-line description]
       2. **[Phase Name]**: [One-line description]
       ...

       ---
       ```
     * Insert this section after "## Summary" and before "## Technical Context"
     * Proceed to step 3 (Execute plan workflow)

   - **If "Request changes"**:
     * Ask for specific feedback: "Please describe which phases to modify and how:"
     * Capture user feedback as free-form text input
     * Parse feedback to identify which phases need changes
     * Implement phase modifications:
       - Adjust phase count (add/remove/split phases)
       - Modify phase names based on feedback
       - Update phase descriptions
       - Re-order phases if requested
     * Track revision count (initialize to 1, increment on each revision)
     * Re-present revised phases with iteration indicator: "Revised phases (iteration [N]/3):"
     * Return to step e (Present phases) with updated phases
     * **Iteration limit**: After 3 revision cycles without approval, suggest:
       "After 3 revision cycles, the spec may have underlying ambiguities. Consider running `/spec.clarify` to resolve these issues before continuing with planning."
       Offer options: "Run /spec.clarify now" / "Continue anyway" / "Cancel planning"

   - **If "Reject approach"**:
     * Display message: "❌ Phase approach rejected."
     * Use AskUserQuestion to offer options:
       ```json
       {
         "questions": [{
           "question": "How would you like to proceed?",
           "header": "Next Steps",
           "options": [
             {
               "label": "Provide alternative approach",
               "description": "Describe a different phase structure"
             },
             {
               "label": "Run /spec.clarify",
               "description": "Resolve spec ambiguities first"
             },
             {
               "label": "Cancel planning",
               "description": "Stop the planning command"
             }
           ],
           "multiSelect": false
         }]
       }
       ```
     * Handle response:
       - "Provide alternative approach": Ask for alternative, revise phases completely, re-present
       - "Run /spec.clarify": Stop planning command with message: "Please run `/spec.clarify` first, then re-run `/spec.plan`"
       - "Cancel planning": Stop planning command with message: "Planning cancelled by user"

   - **Partial approval handling**:
     * If user response indicates uncertainty about specific phases (e.g., "Phases 1-3 good, unsure about 4-5")
     * Ask clarifying questions about uncertain phases: "What concerns do you have about Phase [N]?"
     * Capture concerns and revise uncertain phases based on clarification
     * Re-present all phases (not just revised ones)
     * Return to step e (Present phases)

3. **Execute plan workflow**: Follow the structure in IMPL_PLAN template to:
   - Fill Technical Context (mark unknowns as "NEEDS CLARIFICATION")
   - Fill Constitution Check section: Read `spectri/constitution.md` **completely**. Create a table row for EVERY article and principle. Do not assume the count — the constitution grows over time. Missing articles is a critical plan defect.
   - **Fill Testing Principles section** (see Testing Principles guidance below)
   - **Fill Project Structure section**: Before listing file locations, verify the project's source-of-truth convention by checking where existing scripts and templates live. If the project has both a source directory (e.g., `src/`) and a deployment directory (e.g., `.spectri/`), list new files in the source directory and note the deployment path separately. Check for manifest files (e.g., `commands.json`, `model-command-registry.md`) that need entries for new commands.
   - Evaluate gates (ERROR if violations unjustified)
   - Phase 0: Generate research.md (resolve all NEEDS CLARIFICATION)
   - Phase 1: Generate data-model.md, contracts/, quickstart.md
   - Phase 1: Update agent context by running the agent script
   - Re-evaluate Constitution Check post-design

3.5. **ADR Suggestion Checkpoint** (after Phase 1 design completion):

   **Purpose**: Identify significant architectural decisions from the completed plan and suggest ADR creation to document them.

   **a. Check for skip condition**:
   - If plan.md Technical Context section is empty or contains only "NEEDS CLARIFICATION": Skip ADR suggestion
   - If no architectural decisions were made: Skip ADR suggestion
   - Log: "Skipping ADR suggestion: no decisions to evaluate"

   **b. Extract architectural decisions**:
   Execute decision extraction script:
   ```bash
   REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
   "$REPO_ROOT/.spectri/scripts/spectri-core/extract-decisions.sh" --plan "$IMPL_PLAN" > /tmp/decisions.json 2>&1
   ```

   If extraction fails (no Technical Context found): Log "No architectural decisions found for ADR evaluation" and continue to step 4.

   **c. Apply clustering and significance testing**:
   Execute ADR suggestion script:
   ```bash
   "$REPO_ROOT/.spectri/scripts/spectri-core/suggest-adrs.sh" --decisions /tmp/decisions.json > /tmp/adr-suggestions.json 2>&1
   ```

   If no significant decisions found: Log "No decisions meet ADR significance criteria" and continue to step 4.

   **d. Present ADR suggestions to user**:
   Parse suggestions and present in formatted table:

   ```markdown
   ## ADR Suggestion

   Based on architectural decisions in your plan, the following ADRs are suggested:

   | # | Title | Decisions | Significance |
   |---|-------|-----------|--------------|
   | 1 | [Title] | [Decision 1], [Decision 2] | [Justification] |
   | ... | ... | ... | ... |

   **3-Criteria Significance Test**:
   ✓ Impact: Affects multiple components or future work
   ✓ Tradeoffs: Involves meaningful pros/cons
   ✓ Questioning: Will be questioned by future developers/agents
   ```

   Use AskUserQuestion tool:
   ```json
   {
     "questions": [{
       "question": "Would you like to create ADRs for these architectural decisions?",
       "header": "ADRs",
       "options": [
         {
           "label": "Create all suggested ADRs",
           "description": "Document all significant decisions"
         },
         {
           "label": "Skip ADR creation",
           "description": "Continue without creating ADRs"
         },
         {
           "label": "Select specific ADRs",
           "description": "Choose which ADRs to create"
         }
       ],
       "multiSelect": false
     }]
   }
   ```

   **e. Handle user response**:

   - **If "Create all suggested ADRs"**:
     * Execute batch creation:
       ```bash
       "$REPO_ROOT/.spectri/scripts/spectri-core/create-adrs-from-suggestions.sh" --suggestions /tmp/adr-suggestions.json --json
       ```
     * Parse result and display created ADRs
     * Log: "✅ Created [N] ADRs in spectri/adr/"
     * For each created ADR, add reference to plan.md References section
     * Proceed to step 4

   - **If "Skip ADR creation"**:
     * Log: "ADR creation skipped by user"
     * Proceed to step 4

   - **If "Select specific ADRs"**:
     * Present checkboxes for each suggested ADR
     * Use AskUserQuestion with multiSelect: true
     * Create only selected ADRs
     * Log: "✅ Created [N] of [M] suggested ADRs"
     * Proceed to step 4

   **f. Error handling**:
   - Script not found: Log warning and continue (non-blocking)
   - Script execution failed: Log warning with error message and continue
   - ADR creation failed: Log warning for each failed ADR but continue with others

4. **Stop and report**: Command ends after Phase 2 planning. Report branch, IMPL_PLAN path, and generated artifacts.

5. **Update document metadata**: After plan.md is created or updated, track it in meta.json:
   ```bash
   .spectri/scripts/shared/update-spec-meta.sh \
     --spec "$SPECS_DIR" \
     --update-doc "plan.md" \
     --updated-by "Claude Vermillion Axolotl 0858"
   ```
   Replace the session identifier with your actual session ID.

<!-- INJECT: post-execution -->

---

**MANDATORY COMPLETION STEPS** - Execute ALL before ending this command:

1. **Create implementation summary**:
   ```bash
   bash .spectri/scripts/spectri-trail/create-implementation-summary.sh \
     --spec "$SPEC_FOLDER" \
     --scope "plan.md" \
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
  --update-doc "plan.md" \
  --updated-by "$AGENT_SESSION_ID"
```

## Testing Principles Guidance

**CRITICAL**: All code-producing specs MUST include a Testing Principles section in plan.md that mandates TDD workflow (Article III: Test-First Imperative).

### When to Include Testing Principles

**Include Testing Principles if**:
- Language/Version in Technical Context is a programming language (Python, JavaScript, Bash, Go, etc.)
- Feature involves code implementation (not just documentation or design)

**Skip Testing Principles if**:
- Language is "Markdown", "N/A", or documentation-focused
- Feature is purely design/planning (no code deliverables)

### Testing Principles Section Content

Insert this section in plan.md AFTER "Technical Context" and BEFORE "Project Structure":

```markdown
## Testing Principles

**TDD Mandate** (Article III: Test-First Imperative):

This feature MUST follow test-driven development workflow:
1. Write tests FIRST (contract → integration → e2e → unit)
2. Verify tests FAIL (Red phase)
3. Implement code to make tests pass (Green phase)
4. Refactor as needed

**Test Framework Selection**:

Based on the technology stack chosen in Technical Context:
- **[Language]**: [Test framework] for unit tests, [Integration framework] for integration tests
- **Test Organization**: tests/unit/, tests/integration/, tests/e2e/
- **Coverage Requirements**: Minimum 80% code coverage for business logic

**Existing Pattern Detection** (do this FIRST):
- Before choosing a framework, check `tests/` for existing test files
- Match the project's established test framework and naming conventions
- If existing tests use pytest with subprocess for bash scripts, use that — not bats-core
- If no existing tests exist, select from the examples below

**Examples by Tech Stack** (use only when no existing pattern exists):
- Python: pytest for unit/integration, pytest-subprocess for bash script testing
- JavaScript/TypeScript: Jest or Vitest for unit, Playwright or Cypress for e2e
- Go: testing package for unit, testify for assertions
- Bash: pytest with subprocess (preferred) or bats-core for script testing

**Test File Naming Conventions**:
- Unit tests: test_[module_name].py or [module_name].test.ts
- Integration tests: test_integration_[feature].py
- Contract tests: test_contract_[api_name].py

**Reference**: See spectri/specs/AGENTS.md Development Practices > Testing for TDD workflow details.
```

### Pedagogical Approach

When generating the Testing Principles section:

**Explain WHY** (not just what):
- Tests written first prevent "implementation-driven design"
- Red-green-refactor creates tight feedback loops
- Contract tests define interfaces before implementation exists
- Integration tests prove components work together in real environments

**Provide DECISION FRAMEWORKS**:
- If feature has external APIs → contract tests required
- If feature has user workflows → integration tests required
- If feature has complex logic → unit tests required
- All features need at least one test type

**Include ANTI-PATTERNS**:
- ❌ Writing tests after implementation (not TDD)
- ❌ Mocking everything (integration-first testing principle violated)
- ❌ Skipping tests for "simple" code (creates technical debt)
- ❌ Tests that don't fail when implementation is removed (weak tests)

## Phases

### Phase 0: Outline & Research

1. **Extract unknowns from Technical Context** above:
   - For each NEEDS CLARIFICATION → research task
   - For each dependency → best practices task
   - For each integration → patterns task

2. **Generate and dispatch research agents**:

   ```text
   For each unknown in Technical Context:
     Task: "Research {unknown} for {feature context}"
   For each technology choice:
     Task: "Find best practices for {tech} in {domain}"
   ```

3. **Consolidate findings** in `research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]

**Output**: research.md with all NEEDS CLARIFICATION resolved

### Phase 1: Design & Contracts

**Prerequisites:** `research.md` complete

1. **Extract entities from feature spec** → `data-model.md`:
   - Entity name, fields, relationships
   - Validation rules from requirements
   - State transitions if applicable

2. **Generate API contracts** from functional requirements:
   - For each user action → endpoint
   - Use standard REST/GraphQL patterns
   - Output OpenAPI/GraphQL schema to `/contracts/`

3. **Agent context update**:
   - Run `.spectri/scripts/spectri-core/update-agent-context.sh claude`
   - These scripts detect which AI agent is in use
   - Update the appropriate agent-specific context file
   - Add only new technology from current plan
   - Preserve manual additions between markers

**Output**: data-model.md, /contracts/*, quickstart.md, agent-specific file

## Key rules

- Use absolute paths
- ERROR on gate failures or unresolved clarifications

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
<!-- INJECT: post-finalization -->

## Finalization Checklist

Before completing this command, verify:

- [ ] **Implementation summary created**: `bash .spectri/scripts/spectri-trail/create-implementation-summary.sh --spec "$SPEC_FOLDER" --scope "[scope]"`
- [ ] **meta.json updated** (when applicable): `bash .spectri/scripts/shared/update-spec-meta.sh --spec "$SPEC_FOLDER" --updated-by "[session-id]"` (Only update meta.json when command modifies spec state, not during implementation phases)
- [ ] **Work committed to git**: Commit using appropriate commands
