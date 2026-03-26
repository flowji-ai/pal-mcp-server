---
managed_by: spectri
description: "Iteratively refine user stories, FRs, or acceptance criteria in an existing spec.md with automatic frontmatter updates and implementation summary creation."
model: sonnet
family: spectri-modify
origin:
  source: spectri
injections_applied:
  - user-input
  - frontmatter-update
  - summary-creation
  - finalization-verification
build_info:
  built_at: 2026-03-26T05:51:00Z
  manifest_version: 1.1.0
---

<!--
  COMMAND TYPE: Hybrid

  Hybrid: Mixes strategic thinking (evaluating what to add to spec) with mechanical execution (updating frontmatter, creating summaries)
-->

<!-- INJECT: post-frontmatter -->

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

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

## Outline

Goal: Iteratively refine user stories, FRs, or acceptance criteria in an existing spec.md with automatic frontmatter updates and implementation summary creation, providing a golden path for safely revising spec documents as understanding evolves.

Execution steps:

1. **Validate Location**: Confirm you're in a spec directory with spec.md present
   - Check current directory for spec.md file
   - If not found, ERROR "Not in a spec directory - spec.md not found"
   - Validate spec.md is readable and properly formatted

2. **Load Context**: Read spec.md and constitution for validation
   - Read spec.md content into memory
   - Parse structure to identify existing user stories, FRs, and acceptance criteria
   - Read `spectri/constitution.md` if it exists (constitution provides governance rules for spec changes)
   - If spec.md read fails, ERROR "Cannot read spec.md file"
   - If constitution not found, INFO "Constitution not found - skipping constitutional validation"

3. **Prompt for Changes**: Ask agent what to add or modify in spec.md
   - Present options: add/refine user story, add/refine functional requirement, add/refine acceptance criterion
   - Gather detailed input about what to add or how to modify existing content
   - Validate input is non-empty and relevant to spec

4. **Make Modifications**: Insert or update content at appropriate location based on agent's input
   - Determine optimal placement in document structure
   - Insert new content or refine existing content maintaining proper markdown formatting
   - Preserve existing structure and formatting
   - **Safeguard**: After modifications, verify that `### Functional Requirements` heading still exists under `## Requirements`. If the heading was accidentally removed during editing, restore it before proceeding.
   - If modification fails, ERROR "Unable to modify content in spec.md"

5. **Constitution Soft Validation**: If constitution was loaded, validate changes against governance articles
   - **Article III (Test-First Imperative)**: If adding code-related user stories or FRs, verify they include testable acceptance criteria. WARN if new requirements lack test hooks: "⚠️ WARNING: New requirements may not have testable acceptance criteria (Article III)"
   - **General**: Verify new content doesn't contradict existing constitutional principles
   - This is a soft check — WARN but don't block. Document any warnings for agent review.
   - Skip this step for documentation-only specs or non-code features

6. **Display Changes**: Show agent what will be changed in spec.md for review
   - Highlight the specific changes made
   - Show any constitutional warnings from Step 5
   - Allow agent to approve or request modifications
   - If agent rejects changes, revert and ERROR "Changes rejected by user"

7. **Update Frontmatter**: Apply injection markers to update Date Updated and updated_by fields
   - Locate frontmatter section in spec.md
   - Update Date Updated with current timestamp
   - Update updated_by with agent session ID
   - If frontmatter update fails, ERROR "Unable to update frontmatter"

8. **Create Summary**: Apply injection markers to automatically create implementation summary
   - Call create-implementation-summary.sh script with context parameters:
     - `--changes`: Brief description of what was added/modified (e.g., "Added User Story 8 for export functionality")
     - `--related-specs`: Reference to related spec sections (e.g., "US8, FR-023, FR-024")
   - Example: `.spectri/scripts/spectri-trail/create-implementation-summary.sh --spec . --scope "spec.md" --changes "Added User Story 8 for data export" --related-specs "US8, FR-023, FR-024, AC-8.1 through AC-8.3" ...`
   - Document what was changed and why (summary will be pre-populated with context)
   - If summary creation fails, ERROR "Unable to create implementation summary"

9. **Stage Changes**: Add modified spec.md to git staging
   - Add spec.md to git staging area
   - Do NOT auto-commit - agent must review and commit
   - If staging fails, ERROR "Unable to stage changes to git"

10. **Report Completion**: Inform agent of successful completion
   - Confirm changes were made to spec.md
   - Remind agent to review and commit changes
   - Suggest next appropriate command

<!-- INJECT: post-execution -->

---

**MANDATORY COMPLETION STEPS** - Execute ALL before ending this command:

1. **Create implementation summary**:
   ```bash
   bash .spectri/scripts/spectri-trail/create-implementation-summary.sh \
     --spec "$SPEC_FOLDER" \
     --scope "spec extension" \
     --session-id "$AGENT_SESSION_ID" \
     --agent-name "$AGENT_NAME" \
     --session-start "$SESSION_START"
   ```

2. **Commit all changes**:
   `git add . && git commit -m "feat(spec-NNN): [description]"`

Do NOT skip these steps. The summary script also updates meta.json automatically.

<!-- INJECT: post-finalization -->

## Finalization Checklist

Before completing this command, verify:

- [ ] **Implementation summary created**: `bash .spectri/scripts/spectri-trail/create-implementation-summary.sh --spec "$SPEC_FOLDER" --scope "[scope]"`
- [ ] **meta.json updated** (when applicable): `bash .spectri/scripts/shared/update-spec-meta.sh --spec "$SPEC_FOLDER" --updated-by "[session-id]"` (Only update meta.json when command modifies spec state, not during implementation phases)
- [ ] **Work committed to git**: Commit using appropriate commands

## References

- Governing Spec: `spectri/specs/04-deployed/016-revise-spec-module/spec.md`
