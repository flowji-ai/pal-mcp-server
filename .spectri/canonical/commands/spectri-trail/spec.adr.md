---
managed_by: spectri
description: "Create Architecture Decision Record (ADR) to document significant architectural decisions"
family: spectri-trail
origin:
  source: spectri
injections_applied:
  - user-input
  - finalization-verification
build_info:
  built_at: 2026-03-26T10:24:07Z
  manifest_version: 1.1.0
---
# Create Architecture Decision Record

**Command**: `/spec.adr`
**Purpose**: Create Architecture Decision Record (ADR) to document significant architectural decisions
**Usage**: `/spec.adr --title "Decision Title"` or `/spec.adr` (interactive mode)

---

## What This Command Does

Creates a new Architecture Decision Record (ADR) in `spectri/adr/` to document a significant architectural decision with:
- Sequential ID (auto-generated: 0001, 0002, etc.)
- Structured template (Decision, Context, Consequences, Alternatives, References)
- Decision clustering support (group related choices)
- YAML frontmatter with metadata and context links

ADRs answer "why did we choose X?" for future agents and developers without requiring meetings or tribal knowledge.

---

<!-- INJECT: post-frontmatter -->

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

> **AGENT DIRECTIVE**: You are executing this command workflow, NOT modifying this command file. Follow the "Implementation Steps" section below to execute the requested operation. Do NOT attempt to edit files in `src/command-bases/` or rebuild command infrastructure.


## When to Use This Command

Use `/spec.adr` when:
- ✅ Making architectural decisions outside planning workflow
- ✅ Documenting past decisions that weren't captured during planning
- ✅ Recording decisions that meet **all 3 significance criteria**:
  1. **Impact**: Affects multiple components or future work
  2. **Tradeoffs**: Involves weighing meaningful pros/cons
  3. **Questioning**: Will be questioned by future developers/agents

**Note**: During planning workflow (`/spec.plan`), ADRs are suggested automatically. This command is for manual ADR creation outside that workflow.

---

## Usage

### Interactive Mode (Recommended)

```
/spec.adr
```

Agent will prompt you for:
1. Decision title (will be slugified for filename)
2. Whether to pre-populate context from current spec (if applicable)

### Direct Mode

```
/spec.adr --title "Backend Technology Stack Selection"
```

Creates ADR immediately with specified title.

---

## Implementation Steps

Follow these steps when executing this command:

### 1. Gather Input

**If no --title provided** (interactive mode):
- Ask user: "What architectural decision would you like to document?"
- Wait for user to provide decision title
- Example: "Backend Stack: FastAPI + PostgreSQL + Redis"

**If --title provided**:
- Use provided title directly

### 2. Apply Significance Test (Optional but Recommended)

Ask user to confirm this decision meets **all 3 criteria**:

```
📝 ADR Significance Test

This decision should be documented if it meets ALL three criteria:

1. ✓ Impact: Does it affect multiple components or future architectural work?
2. ✓ Tradeoffs: Are there meaningful pros/cons or alternatives considered?
3. ✓ Questioning: Will future developers wonder "why did we choose this?"

Does this decision meet all 3 criteria? (y/n)
```

- If **no**: Suggest skipping ADR creation. Exit gracefully.
- If **yes**: Proceed to step 3.

### 3. Detect Current Context

Check if user is currently working on a spec:
- Look for environment variables or current working directory patterns
- Check if `PWD` contains `spectri/specs/NNN-feature-name/`
- If detected, note feature for pre-population

### 4. Create ADR File

Execute ADR creation script:

```bash
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
RESULT=$("$REPO_ROOT/.spectri/scripts/spectri-trail/create-adr.sh" --title "$TITLE" --json")
```

Parse JSON result:
- `id`: Sequential ADR number (e.g., "0001")
- `path`: Absolute path to created ADR file
- `slug`: Slugified filename
- `title`: Decision title

### 5. Pre-populate Template (if applicable)

If current spec context detected, update ADR frontmatter:

```bash
# Update feature context in frontmatter
sed -i "s|feature: {NNN-feature-name}|feature: $CURRENT_FEATURE|" "$ADR_PATH"
sed -i "s|spec: {link to spec.md}|spec: ../../spectri/specs/$CURRENT_FEATURE/spec.md|" "$ADR_PATH"
sed -i "s|plan: {link to plan.md}|plan: ../../spectri/specs/$CURRENT_FEATURE/plan.md|" "$ADR_PATH"
```

Update metadata:
```bash
sed -i "s|created_by: {agent or user}|created_by: $AGENT_SESSION_ID|" "$ADR_PATH"
sed -i "s|updated_by: {agent or user}|updated_by: $AGENT_SESSION_ID|" "$ADR_PATH"
sed -i "s|date: {YYYY-MM-DD}|date: $(date +%Y-%m-%d)|" "$ADR_PATH"
sed -i "s|id: ADR-{NNNN}|id: ADR-$ADR_ID|" "$ADR_PATH"
sed -i "s|title: {Decision Cluster Title}|title: $TITLE|" "$ADR_PATH"
```

### 6. Provide Next Steps Guidance

Display success message with guidance:

```
✅ ADR-$ADR_ID created successfully!

   File: $ADR_PATH
   Title: $TITLE

📝 Next Steps:

1. Edit the ADR file to fill in:
   - Decision section: Describe what was chosen and why (use decision clustering)
   - Context section: Problem statement, requirements, constraints
   - Consequences section: Positive and negative outcomes expected
   - Alternatives section: Options considered and rejection reasons
   - References section: Links to related specs, plans, ADRs

2. Decision Clustering Tips:
   - Group related choices together (e.g., "Backend Stack: FastAPI + PostgreSQL + Redis")
   - Typical cluster size: 3-5 related decisions
   - Use change-together heuristic: Would changing X require changing Y?

3. Update Status:
   - Leave as "Proposed" while discussing
   - Change to "Accepted" after decision is final and implemented
   - Use "Superseded" if decision is later replaced (reference new ADR)

4. Commit ADR:
   git add $ADR_PATH
   git commit -m "docs: Add ADR-$ADR_ID for $TITLE"

📚 For guidance on writing ADRs, see: spectri/specs/04-deployed/028-adr-module/spec.md
```

### 6.5. Constitution Integration (for Accepted ADRs)

**Purpose**: When an architectural decision establishes a new governance principle, update the project constitution with a reference to the ADR.

**a. Check ADR status**:
- Read the created ADR file's frontmatter to check the `status` field
- If status is NOT "Accepted": Skip constitution integration (it's still being discussed)
- If status is "Accepted": Proceed with constitution check

**b. Constitution impact prompt**:

Use AskUserQuestion tool to prompt:
```json
{
  "questions": [{
    "question": "Does this ADR establish or change a project constitution principle?",
    "header": "Constitution",
    "options": [
      {
        "label": "Yes, update constitution",
        "description": "This decision establishes a new operational principle or changes existing governance"
      },
      {
        "label": "No, skip constitution update",
        "description": "This is a technical decision only, no governance impact"
      }
    ],
    "multiSelect": false
  }]
}
```

**c. If user selects "Yes, update constitution"**:

1. **Locate constitution file**:
   ```bash
   CONSTITUTION_PATH="$REPO_ROOT/spectri/constitution.md"
   ```

2. **Check if constitution exists**:
   - If file doesn't exist: Create basic constitution structure first
   - If file exists: Read current principles

3. **Overlap detection**:
   - Extract key terms from ADR decision (technology names, patterns, principles)
   - Search constitution for similar terms
   - If overlap detected, display:
     ```
     ⚠️ Potential overlap detected with existing principle:
     "[Existing principle text]"

     Options:
     1. Update existing principle to reference ADR-$ADR_ID
     2. Add as new principle (may create redundancy)
     3. Skip constitution update
     ```

4. **Guide constitution update**:
   - Suggest principle text based on ADR decision
   - Include ADR reference: "See ADR-$ADR_ID for full rationale"
   - Example format:
     ```markdown
     ### Principle: [Principle Name]

     [Principle description derived from ADR decision]

     **Rationale**: See [ADR-$ADR_ID: $TITLE](spectri/adr/$ADR_FILENAME)
     ```

5. **Edit constitution**:
   - Open constitution file for editing
   - Add new principle in appropriate section
   - Ensure ADR reference is included

6. **Confirm update**:
   ```
   ✅ Constitution updated with ADR-$ADR_ID reference

   Added principle: [Principle summary]
   See: spectri/constitution.md
   ```

**d. If user selects "No, skip constitution update"**:
- Log: "Constitution update skipped"
- Continue to step 7

**e. Constitution file structure** (if creating new):

```markdown
# Project Constitution

*Governance principles established through Architecture Decision Records*

## Core Principles

### Article I: [First Principle]

[Description]

**Rationale**: See [ADR-0001](spectri/adr/0001-example.md)

---

## Operational Guidelines

### [Guideline Name]

[Description]

**Established by**: ADR-$ADR_ID

---

*Last updated: YYYY-MM-DD*
```

### 7. Error Handling

Handle common errors gracefully:

**Template not found**:
```
ERROR: ADR template not found at .spectri/templates/spectri-trail/adr-template.md

This usually means the ADR system hasn't been set up yet.
Run: git pull origin main  # To get latest templates
```

**Script not found**:
```
ERROR: create-adr.sh script not found at .spectri/scripts/spectri-trail/create-adr.sh

The ADR system may not be installed yet.
Check: Is this a Spectri repository with ADR support?
```

**Filesystem errors**:
```
ERROR: Could not create ADR file at $ADR_PATH

Possible causes:
- Insufficient permissions (check directory write access)
- Disk space full
- Invalid characters in title
```

---

## Examples

### Example 1: Create ADR for Backend Stack

**User Input**:
```
/spec.adr --title "Backend Technology Stack"
```

**Agent Actions**:
1. Run significance test (optional, ask user)
2. Create ADR-0001 (assuming first ADR)
3. Pre-populate frontmatter if working in spec directory
4. Display next steps guidance

**Result**:
```
✅ ADR-0001 created: spectri/adr/0001-backend-technology-stack.md

User can now edit file to document:
- Decision: FastAPI + Python 3.11 + PostgreSQL + Redis
- Context: Need async web framework with type safety
- Consequences: Fast development, strong typing, but Python deployment complexity
- Alternatives: Django (rejected: too heavyweight), Flask (rejected: lacks async)
```

### Example 2: Interactive Mode with Context Detection

**User Input**:
```
/spec.adr
```

**Agent Prompts**:
```
What architectural decision would you like to document?
> Frontend Stack Selection

Does this decision meet all 3 significance criteria? (y/n)
> y
```

**Agent Detects**: User is in `spectri/specs/025-dashboard-ui/` directory

**Agent Actions**:
1. Create ADR with auto-populated context:
   - feature: 025-dashboard-ui
   - spec: ../../spectri/specs/025-dashboard-ui/spec.md
   - plan: ../../spectri/specs/025-dashboard-ui/plan.md
2. Display next steps

---

## Validation

Before completing this command:
- ✅ ADR file created in spectri/adr/NNNN-slug.md
- ✅ Sequential ID correctly generated (no collisions)
- ✅ Template structure intact (all sections present)
- ✅ Frontmatter pre-populated with context (if applicable)
- ✅ User guidance provided for next steps
- ✅ No errors or warnings displayed

---

## References

- **ADR System Spec**: [spectri/specs/04-deployed/028-adr-module/spec.md](../../spectri/specs/04-deployed/028-adr-module/spec.md)
- **3-Criteria Significance Test**: See spectri/specs/04-deployed/028-adr-module/spec.md "When to Create ADRs" section

---

**Command Type**: Creation
**Estimated Duration**: 1-2 minutes (creation) + 10-30 minutes (user fills in content)
**Prerequisites**: ADR system installed (template, scripts, directory structure)
**Output**: New ADR file in spectri/adr/ with sequential ID

<!-- INJECT: post-finalization -->

## Finalization Checklist

Before completing this command, verify:

- [ ] **Implementation summary created**: `bash .spectri/scripts/spectri-trail/create-implementation-summary.sh --spec "$SPEC_FOLDER" --scope "[scope]"`
- [ ] **meta.json updated** (when applicable): `bash .spectri/scripts/shared/update-spec-meta.sh --spec "$SPEC_FOLDER" --updated-by "[session-id]"` (Only update meta.json when command modifies spec state, not during implementation phases)
- [ ] **Work committed to git**: Commit using appropriate commands
