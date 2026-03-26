---
managed_by: spectri
description: "Execute the implementation plan by processing and executing all tasks defined in tasks.md"
family: spectri-core
origin:
  source: github-spec-kit
  upstream_url: https://github.com/github/spec-kit/blob/main/templates/commands/implement.md
  adaptations: "Renamed speckit→spectri, merged implement-phase functionality, simplified checkpoint"
injections_applied:
  - user-input
  - frontmatter-update
  - summary-creation
  - finalization-verification
build_info:
  built_at: 2026-03-26T01:25:59Z
  manifest_version: 1.1.0
---
# Execute Implementation Plan

<!-- INJECT: post-frontmatter -->

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Usage

- `/spec.implement` — Run all phases (full implementation)
- `/spec.implement <phase-number>` — Run only the specified phase (e.g., `/spec.implement 3`)

Use single-phase mode for incremental implementation or when working with lower-capability agents that struggle with large task lists.

## Outline

1. Run `.spectri/scripts/shared/validate-prerequisites.sh --json --require-tasks --include-tasks` from repo root and parse FEATURE_DIR and AVAILABLE_DOCS list. All paths must be absolute. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

2. **Determine execution mode**:
   - Check if $ARGUMENTS contains a number
   - **If numeric argument**: Single-phase mode — execute only that phase
   - **If no argument or non-numeric**: Full implementation mode — execute all phases
   - **If phase doesn't exist**: Display error and available phases, then STOP

3. **Check checklists status** (if FEATURE_DIR/checklists/ exists):
   - Scan all checklist files in the checklists/ directory
   - For each checklist, count:
     - Total items: All lines matching `- [ ]` or `- [X]` or `- [x]`
     - Completed items: Lines matching `- [X]` or `- [x]`
     - Incomplete items: Lines matching `- [ ]`
   - Create a status table:

     ```text
     | Checklist | Total | Completed | Incomplete | Status |
     |-----------|-------|-----------|------------|--------|
     | ux.md     | 12    | 12        | 0          | ✓ PASS |
     | test.md   | 8     | 5         | 3          | ✗ FAIL |
     | security.md | 6   | 6         | 0          | ✓ PASS |
     ```

   - Calculate overall status:
     - **PASS**: All checklists have 0 incomplete items
     - **FAIL**: One or more checklists have incomplete items

   - **If any checklist is incomplete**:
     - Display the table with incomplete item counts
     - **STOP** and ask: "Some checklists are incomplete. Do you want to proceed with implementation anyway? (yes/no)"
     - Wait for user response before continuing
     - If user says "no" or "wait" or "stop", halt execution
     - If user says "yes" or "proceed" or "continue", proceed to step 4

   - **If all checklists are complete**:
     - Display the table showing all checklists passed
     - Automatically proceed to step 4

4. **Update meta.json status** to `in-progress`:
   - Run the update utility:
     ```bash
     .spectri/scripts/shared/update-spec-meta.sh --spec FEATURE_DIR --status in-progress
     ```

5. Load and analyze the implementation context:
   - **REQUIRED**: Read tasks.md for the complete task list and execution plan
   - **REQUIRED**: Read plan.md for tech stack, architecture, and file structure
   - **IF EXISTS**: Read data-model.md for entities and relationships
   - **IF EXISTS**: Read contracts/ for API specifications and test requirements
   - **IF EXISTS**: Read research.md for technical decisions and constraints
   - **IF EXISTS**: Read quickstart.md for integration scenarios

6. **Project Setup Verification**:
   - **REQUIRED**: Create/verify ignore files based on actual project setup:

   **Detection & Creation Logic**:
   - Check if the following command succeeds to determine if the repository is a git repo (create/verify .gitignore if so):

     ```sh
     git rev-parse --git-dir 2>/dev/null
     ```

   - Check if Dockerfile* exists or Docker in plan.md → create/verify .dockerignore
   - Check if .eslintrc* exists → create/verify .eslintignore
   - Check if eslint.config.* exists → ensure the config's `ignores` entries cover required patterns
   - Check if .prettierrc* exists → create/verify .prettierignore
   - Check if .npmrc or package.json exists → create/verify .npmignore (if publishing)
   - Check if terraform files (*.tf) exist → create/verify .terraformignore
   - Check if .helmignore needed (helm charts present) → create/verify .helmignore

   **If ignore file already exists**: Verify it contains essential patterns, append missing critical patterns only
   **If ignore file missing**: Create with full pattern set for detected technology

   **Common Patterns by Technology** (from plan.md tech stack):
   - **Node.js/JavaScript/TypeScript**: `node_modules/`, `dist/`, `build/`, `*.log`, `.env*`
   - **Python**: `__pycache__/`, `*.pyc`, `.venv/`, `venv/`, `dist/`, `*.egg-info/`
   - **Java**: `target/`, `*.class`, `*.jar`, `.gradle/`, `build/`
   - **C#/.NET**: `bin/`, `obj/`, `*.user`, `*.suo`, `packages/`
   - **Go**: `*.exe`, `*.test`, `vendor/`, `*.out`
   - **Ruby**: `.bundle/`, `log/`, `tmp/`, `*.gem`, `vendor/bundle/`
   - **PHP**: `vendor/`, `*.log`, `*.cache`, `*.env`
   - **Rust**: `target/`, `debug/`, `release/`, `*.rs.bk`, `*.rlib`, `*.prof*`, `.idea/`, `*.log`, `.env*`
   - **Kotlin**: `build/`, `out/`, `.gradle/`, `.idea/`, `*.class`, `*.jar`, `*.iml`, `*.log`, `.env*`
   - **C++**: `build/`, `bin/`, `obj/`, `out/`, `*.o`, `*.so`, `*.a`, `*.exe`, `*.dll`, `.idea/`, `*.log`, `.env*`
   - **C**: `build/`, `bin/`, `obj/`, `out/`, `*.o`, `*.a`, `*.so`, `*.exe`, `Makefile`, `config.log`, `.idea/`, `*.log`, `.env*`
   - **Swift**: `.build/`, `DerivedData/`, `*.swiftpm/`, `Packages/`
   - **R**: `.Rproj.user/`, `.Rhistory`, `.RData`, `.Ruserdata`, `*.Rproj`, `packrat/`, `renv/`
   - **Universal**: `.DS_Store`, `Thumbs.db`, `*.tmp`, `*.swp`, `.vscode/`, `.idea/`

   **Tool-Specific Patterns**:
   - **Docker**: `node_modules/`, `.git/`, `Dockerfile*`, `.dockerignore`, `*.log*`, `.env*`, `coverage/`
   - **ESLint**: `node_modules/`, `dist/`, `build/`, `coverage/`, `*.min.js`
   - **Prettier**: `node_modules/`, `dist/`, `build/`, `coverage/`, `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`
   - **Terraform**: `.terraform/`, `*.tfstate*`, `*.tfvars`, `.terraform.lock.hcl`
   - **Kubernetes/k8s**: `*.secret.yaml`, `secrets/`, `.kube/`, `kubeconfig*`, `*.key`, `*.crt`

7. Parse tasks.md structure and extract:
   - **Task phases**: Setup, Tests, Core, Integration, Polish
   - **Task dependencies**: Sequential vs parallel execution rules
   - **Task details**: ID, description, file paths, parallel markers [P]
   - **Execution flow**: Order and dependency requirements

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

8. **Execute tasks based on mode**:

   ### Single-Phase Mode (when phase number provided)

   **Extract tasks for specified phase** using the phase detection algorithm:
   - Use grep/sed to extract only tasks belonging to the specified phase
   - The algorithm looks for `## Phase N:` headers in tasks.md
   - Extract tasks between current phase and next phase (or to end of file for final phase)

   **Algorithm**:
   ```bash
   # Input: PHASE_NUM (the phase to extract)
   # Input: TASKS_FILE (path to tasks.md file)

   # Find line numbers for current and next phase
   CURRENT_LINE=$(grep -n "^## Phase $PHASE_NUM:" "$TASKS_FILE" | cut -d: -f1)

   if [ -z "$CURRENT_LINE" ]; then
     echo "Error: Phase $PHASE_NUM not found in $TASKS_FILE" >&2
     exit 1
   fi

   NEXT_LINE=$(grep -n "^## Phase $((PHASE_NUM + 1)):" "$TASKS_FILE" | cut -d: -f1)

   if [ -n "$NEXT_LINE" ]; then
     # Extract between current and next phase
     sed -n "${CURRENT_LINE},$(($NEXT_LINE - 1))p" "$TASKS_FILE" | grep "^- \["
   else
     # Final phase - extract from current line to end of file
     sed -n "${CURRENT_LINE},$ p" "$TASKS_FILE" | grep "^- \["
   fi
   ```

   ### Full Implementation Mode (default)

   Execute implementation following the task plan with explicit instructions from research.md:
   - **Phase-by-phase execution**: Complete each phase before moving to the next
   - **Respect dependencies**: Run sequential tasks in order, parallel tasks [P] can run together
   - **Follow TDD approach**: Execute test tasks before their corresponding implementation tasks
   - **File-based coordination**: Tasks affecting the same files must run sequentially
   - **Validation checkpoints**: Verify each phase completion before proceeding

9. **For EACH task (in specified phase or all phases):**
   - Read full task description: `- [ ] T### [P?] [US1] Description with file path`
   - If task says 'Create X', create that file/directory: `mkdir -p path/to && touch path/to/file`
   - If task says 'Write test_Y()', write that test function with imports, assertions, and verify it runs
   - If task says 'Implement Z', write the actual code/logic specified
   - Verify your work (run tests, check files exist, validate output)
   - ONLY THEN mark task complete: change `- [ ]` to `- [X]` in tasks.md
   - If ANY task fails: STOP, report blocking issue with task ID, do not proceed

10. Implementation execution rules:
    - **Setup first**: Initialize project structure, dependencies, configuration
    - **Tests before code**: If you need to write tests for contracts, entities, and integration scenarios
    - **Core development**: Implement models, services, CLI commands, endpoints
    - **Integration work**: Database connections, middleware, logging, external services
    - **Polish and validation**: Unit tests, performance optimization, documentation

11. Progress tracking and error handling:
    - Report progress after each completed task
    - Halt execution if any non-parallel task fails
    - For parallel tasks [P], continue with successful tasks, report failed ones
    - Provide clear error messages with context for debugging
    - Suggest next steps if implementation cannot proceed
    - **MANDATORY**: For completed tasks, make sure to mark the task off as [X] in the tasks file.
    - **MANDATORY**: Create implementation summary describing actual work done (files changed, code written)
    - **MANDATORY**: Commit changes to git with summary before proceeding

12. **Completion handling based on mode**:

    ### Single-Phase Mode

    - Display summary of completed tasks in this phase
    - Suggest next command: `/spec.implement <N+1>` for next phase
    - **DO NOT update status to "deployed"** — keep as `in-progress`
    - **DO NOT move spec** to `spectri/specs/04-deployed/` folder
    - Allow user to continue with additional phases or complete with full implementation

    ### Full Implementation Mode

    Completion validation:
    - Verify all required tasks are completed
    - Check that implemented features match the original specification
    - Validate that tests pass and coverage meets requirements
    - Confirm the implementation follows the technical plan
    - Report final status with summary of completed work

    **Update meta.json and deploy spec**:
    - **If all tasks are complete**:
      - Update `meta.json` and move to deployed folder via script:
        ```bash
        .spectri/scripts/shared/update-spec-meta.sh --spec FEATURE_DIR --status deployed
        ```
        (The script automatically moves the spec from `specs/0[1-3]-*/NNN-*/` to `spectri/specs/04-deployed/NNN-*/`)
      - Report final location: `spectri/specs/04-deployed/SPEC_NAME/`
    - **If some tasks remain incomplete**:
      - Ensure status remains `in-progress` (no action needed)
      - Report which tasks remain

<!-- INJECT: post-execution -->

---

**MANDATORY COMPLETION STEPS** - Execute ALL before ending this command:

1. **Create implementation summary**:
   ```bash
   bash .spectri/scripts/spectri-trail/create-implementation-summary.sh \
     --spec "$SPEC_FOLDER" \
     --scope "implementation" \
     --session-id "$AGENT_SESSION_ID" \
     --agent-name "$AGENT_NAME" \
     --session-start "$SESSION_START"
   ```

2. **Commit all changes**:
   `git add . && git commit -m "feat(spec-NNN): [description]"`

Do NOT skip these steps. The summary script also updates meta.json automatically.

Note: This command assumes a complete task breakdown exists in tasks.md. If tasks are incomplete or missing, suggest running `/spec.tasks` first to regenerate the task list.
<!-- INJECT: post-finalization -->

## Finalization Checklist

Before completing this command, verify:

- [ ] **Implementation summary created**: `bash .spectri/scripts/spectri-trail/create-implementation-summary.sh --spec "$SPEC_FOLDER" --scope "[scope]"`
- [ ] **meta.json updated** (when applicable): `bash .spectri/scripts/shared/update-spec-meta.sh --spec "$SPEC_FOLDER" --updated-by "[session-id]"` (Only update meta.json when command modifies spec state, not during implementation phases)
- [ ] **Work committed to git**: Commit using appropriate commands
