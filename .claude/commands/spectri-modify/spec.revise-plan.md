---
managed_by: spectri
description: "Iteratively refine the implementation approach in an existing plan.md to reflect changes in spec.md with automatic frontmatter updates, soft validation, and implementation summary creation."
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
  built_at: 2026-03-26T07:35:27Z
  manifest_version: 1.1.0
---

<!--
  COMMAND TYPE: Hybrid

  Hybrid: Mixes strategic thinking (evaluating plan changes) with mechanical execution (updating frontmatter, creating summaries, soft validation)
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

Goal: Iteratively refine the implementation approach in an existing plan.md to reflect changes in spec.md with automatic frontmatter updates, soft validation, and implementation summary creation, providing a golden path for safely revising plan documents as the approach evolves.

Execution steps:

1. **Validate Location**: Confirm you're in a spec directory with both spec.md and plan.md present
   - Check current directory for spec.md and plan.md files
   - If either not found, ERROR "Not in a spec directory - spec.md or plan.md not found"
   - Validate both files are readable and properly formatted

2. **Check Git Availability**: Determine if git-based change detection is possible
   - Run `git rev-parse --is-inside-work-tree` to check if inside a git repository
   - If git is not available or not in a repo, display INFO "Git not available - manual review of spec.md required" and skip to Step 5
   - Store git availability status for later use

3. **Get Last Plan Commit**: Find when plan.md was last modified in git
   - Run `git log -n 1 --pretty=format:%H -- plan.md` to get the commit hash
   - If no commit history exists (new file), display INFO "plan.md has no git history - showing all spec.md content" and skip to Step 5
   - Store the commit hash for comparison

4. **Show Spec Changes**: Display what changed in spec.md since plan.md was last updated
   - Run `git diff $COMMIT_HASH -- spec.md` to show changes
   - If diff is empty, display INFO "spec.md unchanged since last plan update"
   - If diff has content, display the raw diff output with `+` markers showing additions:
     ```
     spec.md changes since plan.md was last updated (commit: $SHORT_HASH):

     [git diff output here - shows literal +/- markers for changes]
     ```
   - The agent can read the `+` lines to identify new user stories, FRs, and acceptance criteria that may need reflection in plan.md

5. **Load Existing Files**: Read current spec.md, plan.md, and constitution
   - Read spec.md content into memory
   - Read plan.md content into memory
   - Read `spectri/constitution.md` if it exists (constitution provides governance rules for plan changes)
   - Parse structure to identify existing user stories and plan phases
   - If spec.md or plan.md read fails, ERROR "Cannot read spec.md or plan.md file"
   - If constitution not found, INFO "Constitution not found - skipping constitutional validation"

6. **Prompt for Changes**: Ask agent what to add or refine in plan.md
   - Present options: add new phase, refine existing approach, update technical details
   - Gather detailed input about what to add or how to refine existing content
   - Validate input is non-empty and relevant to plan

7. **Soft Validation**: Check structural alignment and constitutional compliance
   - Compare new phase content with existing user stories in spec.md
   - If no reference found, warn: "⚠️ WARNING: New phase doesn't reference existing user stories from spec.md"
   - **Constitution Check (Article III — Test-First Imperative)**: If plan changes affect code-producing phases, verify TDD ordering is maintained:
     - Test tasks MUST precede implementation tasks in each phase
     - WARN if new phases lack test planning: "⚠️ WARNING: New phase has no test planning step (Article III)"
   - **Constitution Check (General)**: Verify plan changes don't introduce approaches that contradict constitutional principles
   - Continue execution despite warnings (soft validation — don't block)
   - Skip constitution checks for documentation-only specs or non-code features
   - If validation fails critically, ERROR "Unable to perform soft validation"

8. **Make Modifications**: Add or refine content in plan.md based on agent's input
   - Determine optimal placement in document structure
   - Insert new content or refine existing content maintaining proper markdown formatting
   - Preserve existing structure and formatting
   - If modification fails, ERROR "Unable to modify content in plan.md"

9. **Display Changes**: Show agent what will be changed in plan.md for review
   - Highlight the specific changes made
   - Allow agent to approve or request modifications
   - If agent rejects changes, revert and ERROR "Changes rejected by user"

10. **Update Frontmatter**: Apply injection markers to update Date Updated and updated_by fields
    - Locate frontmatter section in plan.md
    - Update Date Updated with current timestamp
    - Update updated_by with agent session ID
    - If frontmatter update fails, ERROR "Unable to update frontmatter"

11. **Create Summary**: Apply injection markers to automatically create implementation summary
    - Call create-implementation-summary.sh script with context parameters:
      - `--changes`: Brief description of phase/section changes (e.g., "Added Phase 5 for export functionality")
      - `--related-specs`: Reference to related spec sections the changes align with (e.g., "spec.md US4, FR-019, FR-020")
    - Example: `.spectri/scripts/spectri-trail/create-implementation-summary.sh --spec . --scope "plan.md" --changes "Added Phase 5 for data export feature" --related-specs "spec.md US4, FR-019, FR-020" ...`
    - Document what was changed and why (summary will be pre-populated with context)
    - If summary creation fails, ERROR "Unable to create implementation summary"

12. **Stage Changes**: Add modified plan.md to git staging
    - Add plan.md to git staging area
    - Do NOT auto-commit - agent must review and commit
    - If staging fails, ERROR "Unable to stage changes to git"

13. **Report Completion**: Inform agent of successful completion
    - Confirm changes were made to plan.md
    - Remind agent to review and commit changes
    - Suggest next appropriate command

<!-- INJECT: post-execution -->

---

**MANDATORY COMPLETION STEPS** - Execute ALL before ending this command:

1. **Create implementation summary**:
   ```bash
   bash .spectri/scripts/spectri-trail/create-implementation-summary.sh \
     --spec "$SPEC_FOLDER" \
     --scope "plan update" \
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

- Governing Spec: `spectri/specs/04-deployed/015-revise-plan-module/spec.md`
