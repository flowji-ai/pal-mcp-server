---
managed_by: spectri
description: "Create a retrospective spec for an already-implemented feature. Documents what EXISTS, not what SHOULD exist."
family: spectri-core
origin:
  source: github-spec-kit
  upstream_url: https://github.com/github/spec-kit/blob/main/templates/commands/document.md
  adaptations: "Renamed speckit→spectri, renamed document→retro, added discovery framework"
injections_applied:
  - user-input
  - frontmatter-update
  - summary-creation
  - meta-update
  - finalization-verification
build_info:
  built_at: 2026-03-26T10:24:08Z
  manifest_version: 1.1.0
---
# Create Retrospective Specification

<!-- INJECT: post-frontmatter -->

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Purpose

This command creates **retrospective specifications** for features that are already implemented but lack formal documentation. Unlike `/spec.specify` (which plans future work), this documents existing reality.

**Use when:**
- A system exists but was never formally specified
- You need to document what something actually does (not what it should do)
- Creating reference documentation for existing implementations

**Do NOT use when:**
- Planning new features (use `/spec.specify`)
- The implementation doesn't exist yet

## Workflow

### Phase 1: Investigation (MANDATORY)

Before writing any spec, you MUST investigate the actual implementation:

**Think of retrospective documentation as creating an inventory with boundaries.** When documenting existing systems, discovery is not just reading files—it's building understanding through structured exploration. Start broad (architecture, entry points, dependencies), then narrow (specific modules, edge cases, constraints). Look for the "why" behind implementation choices by reading commit history and comments. Critically, identify scope boundaries—what the system does NOT do. Always validate findings with the user before writing spec.md to avoid documenting assumptions instead of reality.

1. **Locate the implementation**:
   - Read all relevant source files
   - Check for existing documentation (AGENTS.md, README, comments)
   - Review any related scripts, configs, or tests

2. **Document what you find**:
   - What does this system actually do?
   - What are the inputs and outputs?
   - What are the dependencies?
   - What architectural decisions were made and why?
   - Are there any gaps or incomplete features?

3. **Multi-agent consensus investigation**:

   Spawn 5 independent sub-agents (using the Task tool with `subagent_type: Explore`) to investigate the implementation in parallel. Each sub-agent independently:
   - Locates and reads all relevant source files
   - Checks documentation (AGENTS.md, README, comments)
   - Reviews scripts, configs, and tests
   - Produces a structured findings report in this format:

   ```markdown
   ## Implementation Analysis: [System Name]

   ### What IS implemented:
   - [Feature 1]: [How it works]
   - [Feature 2]: [How it works]

   ### What is NOT implemented (gaps):
   - [Missing feature or incomplete aspect]

   ### Dependencies:
   - [Dependency 1]

   ### Architecture & Decisions:
   - [Key decision 1]: [Rationale]

   ### Uncertainty:
   - [Anything unclear from this agent's perspective]
   ```

   Each sub-agent prompt should include:
   > You are independently investigating [System Name] for retrospective documentation.
   > Locate and analyze the implementation. Check source files, docs, scripts, configs, tests.
   > Return your findings in the structured format. Do NOT coordinate with other agents.

   After all 5 sub-agents return:
   - Compare findings across all 5 reports
   - Identify **consensus items** (3+ agents agree)
   - Flag **disagreements** or unique findings from individual agents
   - For any disagreement: spawn a targeted sub-agent to investigate the specific point
   - Produce a **consolidated findings document** merging all consensus items and resolved disagreements

4. **Proceed to Phase 2** using the consolidated findings. No human confirmation gate — the multi-agent consensus serves as validation.

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

### Phase 2: Spec Creation

1. **Determine spec number**:
   If a spec number was provided (e.g., passed from `/spec-rebuild:stub-to-spec`), use that number directly.
   Otherwise, calculate the next available number:
   ```bash
   .spectri/scripts/shared/get-next-spec-number.sh
   ```
   This returns the next zero-padded 3-digit number (e.g., `056`).

2. **Generate short name** (2-4 words, kebab-case):
   - Extract meaningful keywords from the system name
   - Use noun format (e.g., "registry-rendering", "session-summaries")

3. **Create spec directory**:
   ```bash
   mkdir -p spectri/specs/<NUMBER>-<short-name>/checklists
   ```

4. **Create meta.json** for the retrospective spec:
   ```bash
   sed -e "s|\[ISO_TIMESTAMP\]|$(date -Iseconds)|g" \
       -e "s|\[AGENT_SESSION_ID\]|Claude Vermillion Axolotl 0858|g" \
       .spectri/templates/spectri-core/meta-template.json > "spectri/specs/<NUMBER>-<short-name>/meta.json"
   ```
   Replace session ID with your actual session identifier.
   Then set status to "deployed" and remove plan.md/tasks.md entries (retrospective specs don't use them):
   ```bash
   # Set deployed status
   .spectri/scripts/shared/update-spec-meta.sh \
     --spec "spectri/specs/<NUMBER>-<short-name>" \
     --status "deployed"
   # Remove plan.md and tasks.md document entries (not applicable to retrospective specs)
   jq 'del(.documents["plan.md"], .documents["tasks.md"])' \
     "spectri/specs/<NUMBER>-<short-name>/meta.json" > /tmp/meta-tmp.json && \
     mv /tmp/meta-tmp.json "spectri/specs/<NUMBER>-<short-name>/meta.json"
   ```

5. **Write the retrospective spec**:

   **Scaffold the spec file using the script**:
   ```bash
   .spectri/scripts/spectri-core/create-spec.sh --scaffold-only \
     --number <NUMBER> --short-name "<short-name>" \
     --feature-name "<Feature Name>" \
     --session-id "<Your Session ID>" \
     "<feature description>"
   ```
   This creates `spectri/specs/<NUMBER>-<short-name>/spec.md` with the template structure and all frontmatter placeholders replaced.

   **Then edit the scaffolded file**, populating each section with investigation findings. Do NOT delete any headings or rewrite the file from scratch.

   **Required template structure**:
   - The scaffolded file follows `.spectri/templates/spectri-core/spec-template.md` format
   - You MUST preserve all headings and section structure
   - Do NOT write technical documentation - write user-story-driven specifications

   **REQUIRED**: Before writing any user stories, load and apply the `spectri-user-story-gherkin` skill. This skill provides the five principles (Substance Over Mechanics, Quality Over Existence, Single Story Ownership, Integration Thinking, Concrete Validation), Gherkin anti-patterns, INVEST checks, and pre-submission quality criteria that MUST govern every story you write. If the skill is not already in context, read it from `.claude/skills/spectri-user-story-gherkin/SKILL.md` (or the equivalent path for your agent platform).

   **Mandatory sections from template**:
   1. **User Scenarios & Testing** (mandatory)
      - Prioritized user stories (P1, P2, P3, etc.)
      - Each story needs: description, "Why this priority", "Independent Test"
      - Acceptance Scenarios in **Given/When/Then** format
      - Edge cases

   2. **Requirements** (mandatory)
      - Functional requirements (FR-001, FR-002, etc.)
      - Key entities (if feature involves data)

   3. **Success Criteria** (mandatory)
      - Measurable outcomes (SC-001, SC-002, etc.)

   **What NOT to write**:
   - ✗ Technical architecture documentation
   - ✗ System interfaces and workflows
   - ✗ Implementation details
   - ✗ API documentation
   - ✗ File paths, CLI flags, or marker syntax in acceptance scenarios (describe outcomes, not mechanisms - implementation detail belongs in design.md)

   **What TO write**:
   - ✓ User journeys with Given/When/Then acceptance criteria
   - ✓ Functional requirements from user perspective
   - ✓ Measurable success criteria

   **CRITICAL - Outcome-focused acceptance scenarios**:
   Acceptance scenarios MUST describe observable outcomes from the user's perspective, NOT implementation mechanisms. The test: if removing a file path, flag name, or format name from a scenario makes it meaningless, the scenario is testing implementation rather than behavior.

   - ✗ BAD: "Given canonical commands exist in `.spectri/canonical/commands/`, When synced to Qwen, Then the command is converted to TOML format"
   - ✓ GOOD: "Given a canonical command exists, When synced to an agent that uses a different format, Then the command is converted to the agent's native format"

   - ✗ BAD: "When the developer runs the skill sync with `--dry-run`, Then changes are shown"
   - ✓ GOOD: "When the developer previews changes without applying them, Then proposed changes are shown without modifying any files"

   File paths, format names, flag names, and script names belong in design.md (architecture) or FRs (requirements), never in Given/When/Then scenarios.

   Write spec to: `spectri/specs/<NUMBER>-<short-name>/spec.md`

6. **Write the retrospective design document** (if applicable):

   **When to create design.md**: Create this document when the feature involves architectural decisions, workflow patterns, or technical trade-offs worth documenting. Skip for simple features with straightforward implementation.

   **Scaffold the design file using the script**:
   ```bash
   .spectri/scripts/spectri-core/create-design.sh \
     --output "spectri/specs/<NUMBER>-<short-name>/design.md" \
     --feature-name "<Feature Name>" \
     --session-id "<Your Session ID>"
   ```
   This creates the design.md with template structure and frontmatter placeholders replaced.

   **Then edit the scaffolded file**, populating each section. Do NOT delete any headings or rewrite from scratch.

   **Focus on**:
   - ✓ Why architectural choices were made (not just what they are)
   - ✓ How the system workflow operates
   - ✓ Trade-offs and their rationale
   - ✓ Context that would help a new developer understand the system

   **Do NOT include**:
   - ✗ User stories (those belong in spec.md)
   - ✗ Implementation task lists (those belong in tasks.md)
   - ✗ Code-level documentation (that belongs in code comments)

   Write design to: `spectri/specs/<NUMBER>-<short-name>/design.md`

### Phase 3: Validation

1. **Create documentation checklist** at `spectri/specs/<NUMBER>-<short-name>/checklists/documentation.md`

   **Read the checklist template FIRST**:
   ```bash
   cat .spectri/templates/spectri-core/checklist-template.md
   ```

2. **Verify each checklist item** against the spec and design documents. Review each item individually — only mark `[x]` after confirming the item is satisfied in the actual documents. If an item fails, leave it unchecked and add a note explaining what's missing.

3. **Spec quality validation**: Review the spec against quality criteria before finalising. For each check, fix issues inline (max 2 self-correction iterations):

   a. **User story quality** (per `spectri-user-story-gherkin` skill):
      - No implementation details in acceptance scenarios (file paths, CLI flags, format names, script names)
      - Scenarios describe observable outcomes, not mechanisms
      - Each story passes INVEST criteria (Independent, Negotiable, Valuable, Estimable, Small, Testable)
      - No Gherkin anti-patterns (vague outcomes, testing implementation, compound Given/When/Then)

   b. **Requirements quality**:
      - Every functional requirement is testable and unambiguous
      - Each FR maps to at least one acceptance scenario
      - No implementation details leak into requirements language

   c. **Success criteria quality**:
      - All criteria are measurable (specific metrics: time, percentage, count)
      - Technology-agnostic (no frameworks, languages, tools)
      - Verifiable without knowing implementation details

   d. **Retro-specific accuracy check**:
      - Every user story traces to something that actually exists in the implementation
      - No aspirational content masquerading as current behaviour
      - Gaps between spec and reality are noted explicitly, not papered over

<!-- INJECT: post-execution -->

---

**MANDATORY COMPLETION STEPS** - Execute ALL before ending this command:

1. **Create implementation summary**:
   ```bash
   bash .spectri/scripts/spectri-trail/create-implementation-summary.sh \
     --spec "$SPEC_FOLDER" \
     --scope "retrospective spec" \
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

## Key Differences from /spec.spectri

| Aspect | /spec.spectri | /spec.retro |
|--------|---------------|-------------|
| Purpose | Plan future work | Document existing work |
| Status | Draft | Implemented |
| Sections | User Stories, Requirements | User Stories, Requirements + Design (architecture, decisions) |
| Focus | What SHOULD exist | What DOES exist |
| Investigation | Optional research | MANDATORY code review |
| Validation | Checklist for completeness | Checklist for accuracy |

## Constraints

- **NEVER** document features that don't exist
- **NEVER** skip the investigation phase
- **ALWAYS** verify at least one feature works as documented
- **ALWAYS** use multi-agent consensus to validate findings before creating the spec
- **DO NOT** add aspirational content (future improvements are optional, clearly marked)
<!-- INJECT: post-finalization -->

## Finalization Checklist

Before completing this command, verify:

- [ ] **Implementation summary created**: `bash .spectri/scripts/spectri-trail/create-implementation-summary.sh --spec "$SPEC_FOLDER" --scope "[scope]"`
- [ ] **meta.json updated** (when applicable): `bash .spectri/scripts/shared/update-spec-meta.sh --spec "$SPEC_FOLDER" --updated-by "[session-id]"` (Only update meta.json when command modifies spec state, not during implementation phases)
- [ ] **Work committed to git**: Commit using appropriate commands
