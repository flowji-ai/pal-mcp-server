---
managed_by: spectri
description: "Generate an actionable, dependency-ordered tasks.md for the feature based on available design artifacts."
family: spectri-core
origin:
  source: github-spec-kit
  upstream_url: https://github.com/github/spec-kit/blob/main/templates/commands/tasks.md
  adaptations: "Renamed speckit→spectri, added checkpoint automation, simplified summary creation"
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
# Generate Task List

<!-- INJECT: post-frontmatter -->

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

> **AGENT DIRECTIVE**: You are executing this command workflow, NOT modifying this command file. Follow the "Implementation Steps" section below to execute the requested operation. Do NOT attempt to edit files in `src/command-bases/` or rebuild command infrastructure.


## Outline

1. **Setup**: Run `.spectri/scripts/shared/validate-prerequisites.sh --json` from repo root and parse FEATURE_DIR and AVAILABLE_DOCS list. All paths must be absolute. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

2. **Load design documents**: Read from FEATURE_DIR:
   - **Required**: plan.md (tech stack, libraries, structure), spec.md (user stories with priorities)
   - **Optional**: data-model.md (entities), contracts/ (API endpoints), research.md (decisions), quickstart.md (test scenarios)
   - Note: Not all projects have all documents. Generate tasks based on what's available.

3. **Execute task generation workflow**:
   - Load plan.md and extract tech stack, libraries, project structure
   - Load spec.md and extract user stories with their priorities (P1, P2, P3, etc.)
   - If data-model.md exists: Extract entities and map to user stories
   - If contracts/ exists: Map endpoints to user stories
   - If research.md exists: Extract decisions for setup tasks
   - Generate tasks organized by user story (see Task Generation Rules below)
   - Generate dependency graph showing user story completion order
   - Create parallel execution examples per user story
   - Validate task completeness (each user story has all needed tasks, independently testable)

4. **Generate tasks.md**: Use `.spectri/templates/spectri-core/tasks-template.md` as structure, fill with:
   - Correct feature name from plan.md
   - Phase 1: Setup tasks (project initialization)
   - Phase 2: Foundational tasks (blocking prerequisites for all user stories)
   - Phase 3+: One phase per user story (in priority order from spec.md)
   - Each phase includes: story goal, independent test criteria, tests (if requested), implementation tasks
   - Final Phase: Polish & cross-cutting concerns
   - All tasks must follow the strict checklist format (see Task Generation Rules below)
   - Clear file paths for each task
   - Dependencies section showing story completion order
   - Parallel execution examples per story
   - Implementation strategy section (MVP first, incremental delivery)
   - At each phase boundary, include two checkpoint tasks: [Checkpoint] Create implementation summary and [Checkpoint] Commit work + summary to Git

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

5. **Report**: Output path to generated tasks.md and summary:
   - Total task count
   - Task count per user story
   - Parallel opportunities identified
   - Independent test criteria for each story
   - Suggested MVP scope (typically just User Story 1)
   - Format validation: Confirm ALL tasks follow the checklist format (checkbox, ID, labels, file paths)

<!-- INJECT: post-execution -->

---

**MANDATORY COMPLETION STEPS** - Execute ALL before ending this command:

1. **Create implementation summary**:
   ```bash
   bash .spectri/scripts/spectri-trail/create-implementation-summary.sh \
     --spec "$SPEC_FOLDER" \
     --scope "tasks.md" \
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
  --update-doc "tasks.md" \
  --updated-by "$AGENT_SESSION_ID"
```

Context for task generation: $ARGUMENTS

The tasks.md should be immediately executable - each task must be specific enough that an LLM can complete it without additional context.

## Task Generation Rules

**CRITICAL**: Tasks MUST be organized by user story to enable independent implementation and testing.

**Tests are MANDATORY for code-producing specs** (Article III: Test-First Imperative):

- Generate test tasks for ANY spec with code-producing tech stack (Python, JavaScript, Go, Bash, etc.)
- SKIP test tasks ONLY for documentation-only specs (detect via plan.md Language field: "Markdown", "N/A", or documentation-focused)
- Tests MUST be written BEFORE implementation (true TDD - tests fail first, then implementation makes them pass)
- **Detection**: Check plan.md Technical Context "Language/Version" field to determine if code or documentation

**WHEN to skip tests**:
- Language is "Markdown" or "N/A" → Documentation-only spec, no tests needed
- Language is "YAML", "JSON", or pure config → Config-only spec, no tests needed
- Plan explicitly states "no code deliverables" → Skip tests

**WHEN tests are required**:
- Language is Python, JavaScript, TypeScript, Go, Bash, Rust, Java, C#, etc. → Tests MANDATORY
- Feature involves code implementation → Tests MANDATORY

### Checklist Format (REQUIRED)

Every task MUST strictly follow this format:

```text
- [ ] [TaskID] [P?] [Story?] Description with file path
```

**Format Components**:

1. **Checkbox**: ALWAYS start with `- [ ]` (markdown checkbox)
2. **Task ID**: Sequential number (T001, T002, T003...) in execution order
3. **[P] marker**: Include ONLY if task is parallelizable (different files, no dependencies on incomplete tasks)
4. **[Story] label**: REQUIRED for user story phase tasks only
   - Format: [US1], [US2], [US3], etc. (maps to user stories from spec.md)
   - Setup phase: NO story label
   - Foundational phase: NO story label
   - User Story phases: MUST have story label
   - Polish phase: NO story label
5. **[Checkpoint] label**: REQUIRED for checkpoint tasks at phase boundaries
   - Format: [Checkpoint] (appears after phase tasks)
   - Purpose: Explicitly track "create implementation summary" and "commit work" actions
   - Placement: At end of each phase, before checkpoint marker
6. **Description**: Clear action with exact file path

**Examples**:

- ✅ CORRECT: `- [ ] T001 Create project structure per implementation plan`
- ✅ CORRECT: `- [ ] T005 [P] Implement authentication middleware in src/middleware/auth.py`
- ✅ CORRECT: `- [ ] T012 [P] [US1] Create User model in src/models/user.py`
- ✅ CORRECT: `- [ ] T014 [US1] Implement UserService in src/services/user_service.py`
- ✅ CORRECT: `- [ ] T015 [Checkpoint] Create implementation summary documenting User Story 1 work`
- ✅ CORRECT: `- [ ] T016 [Checkpoint] Commit work + summary to Git`
- ❌ WRONG: `- [ ] Create User model` (missing ID and Story label)
- ❌ WRONG: `T001 [US1] Create model` (missing checkbox)
- ❌ WRONG: `- [ ] [US1] Create User model` (missing Task ID)
- ❌ WRONG: `- [ ] T001 [US1] Create model` (missing file path)

### Task Organization

1. **From User Stories (spec.md)** - PRIMARY ORGANIZATION:
   - Each user story (P1, P2, P3...) gets its own phase
   - Map all related components to their story:
     - **Tests** for that story (MANDATORY - written FIRST)
     - Models needed for that story
     - Services needed for that story
     - Endpoints/UI needed for that story
   - Mark story dependencies (most stories should be independent)

2. **From Contracts**:
   - Map each contract/endpoint → to the user story it serves
   - Each contract → contract test task [P] BEFORE implementation in that story's phase (test-first)

3. **From Data Model**:
   - Map each entity to the user story(ies) that need it
   - If entity serves multiple stories: Put in earliest story or Setup phase
   - Relationships → service layer tasks in appropriate story phase

4. **From Setup/Infrastructure**:
   - Shared infrastructure → Setup phase (Phase 1)
   - Foundational/blocking tasks → Foundational phase (Phase 2)
   - Story-specific setup → within that story's phase

### Phase Structure

- **Phase 1**: Setup (project initialization)
- **Phase 2**: Foundational (blocking prerequisites - MUST complete before user stories)
- **Phase 3+**: User Stories in priority order (P1, P2, P3...)
  - **CRITICAL - Test-First Ordering Within Each User Story Phase**:
    1. **Tests subsection FIRST** → All test tasks for this story (contract, integration, e2e, unit)
    2. **Implementation subsection AFTER** → Models, services, endpoints, integration
  - Implementation tasks DEPEND ON tests being written (not passing - that's what implementation does)
  - Each phase should be a complete, independently testable increment
- **Final Phase**: Polish & Cross-Cutting Concerns

**Test-First Ordering Pattern** (per user story phase):

```markdown
## Phase N: User Story X - [Title]

### Tests (MUST write first - verify they FAIL)

- [ ] T### [P] [USX] Contract test for [feature] in tests/contract/test_[name].py
- [ ] T### [P] [USX] Integration test for [workflow] in tests/integration/test_[name].py
- [ ] T### [P] [USX] Unit tests for [component] in tests/unit/test_[name].py

### Implementation (makes tests pass)

- [ ] T### [P] [USX] Create [Model] in src/models/[model].py (depends: tests written)
- [ ] T### [USX] Implement [Service] in src/services/[service].py (depends: tests written)
- [ ] T### [USX] Create [Endpoint] in src/api/[endpoint].py (depends: tests written)
```

**Dependency Semantics**:
- Implementation tasks depend on "tests written" (not "tests passing")
- This is TRUE TDD: write failing tests, THEN write code to make them pass (Red-Green-Refactor)
- Mark dependencies clearly: "(depends: T001, T002 written)" or "(depends: tests written)"
<!-- INJECT: post-finalization -->

## Finalization Checklist

Before completing this command, verify:

- [ ] **Implementation summary created**: `bash .spectri/scripts/spectri-trail/create-implementation-summary.sh --spec "$SPEC_FOLDER" --scope "[scope]"`
- [ ] **meta.json updated** (when applicable): `bash .spectri/scripts/shared/update-spec-meta.sh --spec "$SPEC_FOLDER" --updated-by "[session-id]"` (Only update meta.json when command modifies spec state, not during implementation phases)
- [ ] **Work committed to git**: Commit using appropriate commands
