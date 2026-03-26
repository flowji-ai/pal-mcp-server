---
managed_by: spectri
description: "Extend an existing tasks.md by adding tasks to align with changes in plan.md (preserving existing tasks) with automatic frontmatter updates, soft validation, and implementation summary creation."
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
  built_at: 2026-03-26T05:51:01Z
  manifest_version: 1.1.0
---

<!--
  COMMAND TYPE: Hybrid

  Hybrid: Mixes strategic thinking (evaluating task changes) with mechanical execution (updating frontmatter, creating summaries, soft validation)
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

Goal: Extend an existing tasks.md by adding tasks to align with changes in plan.md with automatic frontmatter updates, soft validation, and implementation summary creation. CRITICAL: This command PRESERVES existing tasks and only ADDS new ones - it does not delete or replace existing task entries. Provides a golden path for safely augmenting the execution plan.

Execution steps:

1. **Validate Location**: Confirm you're in a spec directory with both plan.md and tasks.md present
   - Check current directory for plan.md and tasks.md files
   - If either not found, ERROR "Not in a spec directory - plan.md or tasks.md not found"
   - Validate both files are readable and properly formatted

2. **Check Git Availability**: Determine if git-based change detection is possible
   - Run `git rev-parse --is-inside-work-tree` to check if inside a git repository
   - If git is not available or not in a repo, display INFO "Git not available - manual review of plan.md required" and skip to Step 5
   - Store git availability status for later use

3. **Get Last Tasks Commit**: Find when tasks.md was last modified in git
   - Run `git log -n 1 --pretty=format:%H -- tasks.md` to get the commit hash
   - If no commit history exists (new file), display INFO "tasks.md has no git history - showing all plan.md content" and skip to Step 5
   - Store the commit hash for comparison

4. **Show Plan Changes**: Display what changed in plan.md since tasks.md was last updated
   - Run `git diff $COMMIT_HASH -- plan.md` to show plan changes
   - If diff is empty, display INFO "plan.md unchanged since last tasks update"
   - If diff has content, display the raw diff output with `+` markers showing additions:
     ```
     plan.md changes since tasks.md was last updated (commit: $SHORT_HASH):

     [git diff output here - shows literal +/- markers for changes]
     ```
   - Optionally show spec.md changes for additional context: `git diff $COMMIT_HASH -- spec.md`
   - The agent can read the `+` lines to identify new phases, sections, or requirements that may need new tasks

5. **Load Existing Files**: Read current plan.md, tasks.md, and constitution
   - Read plan.md content into memory
   - Read tasks.md content into memory
   - Read `spectri/constitution.md` if it exists (constitution provides governance rules for task ordering)
   - Parse structure to identify existing phases and tasks
   - If plan.md or tasks.md read fails, ERROR "Cannot read plan.md or tasks.md file"
   - If constitution not found, INFO "Constitution not found - skipping constitutional validation"

6. **Prompt for Task Additions**: Ask agent what tasks to add to tasks.md
   - Present options: new tasks for new phases, additional tasks for existing phases
   - Gather detailed input about what tasks to add (NOT modify existing tasks)
   - Validate input is non-empty and relevant to tasks
   - Explicitly confirm that existing tasks will be preserved

7. **Soft Validation**: Check structural alignment and constitutional compliance
   - Compare new task content with existing phases in plan.md
   - If no reference found, warn: "⚠️ WARNING: New task doesn't reference existing phases from plan.md"
   - **Constitution Check (Article III — Test-First Imperative)**: Verify TDD task ordering for new tasks:
     - Test tasks (marked `[Test]` or containing "test" in description) MUST appear before their corresponding implementation tasks
     - WARN if implementation tasks are added without preceding test tasks: "⚠️ WARNING: Implementation task added without corresponding test task (Article III)"
   - **Constitution Check (General)**: Verify new tasks don't introduce approaches that contradict constitutional principles
   - Continue execution despite warnings (soft validation — don't block)
   - Skip constitution checks for documentation-only specs or non-code features
   - If validation fails critically, ERROR "Unable to perform soft validation"

8. **Add Tasks**: Insert new tasks into tasks.md based on agent's input while PRESERVING all existing tasks
   - CRITICAL: DO NOT delete or modify any existing task entries
   - Determine optimal placement in document structure for new tasks
   - Insert new tasks maintaining proper markdown formatting
   - Ensure sequential task numbering continues from last existing task ID
   - Preserve all existing tasks, structure, and formatting
   - If insertion fails, ERROR "Unable to add tasks to tasks.md"

9. **Display Changes**: Show agent what tasks will be ADDED to tasks.md for review
   - Highlight the new tasks being added (not changes to existing tasks)
   - Confirm existing tasks remain unchanged
   - Allow agent to approve or request modifications
   - If agent rejects changes, revert and ERROR "Changes rejected by user"

10. **Update Frontmatter**: Apply injection markers to update Date Updated and updated_by fields
    - Locate frontmatter section in tasks.md
    - Update Date Updated with current timestamp
    - Update updated_by with agent session ID
    - If frontmatter update fails, ERROR "Unable to update frontmatter"

11. **Create Summary**: Apply injection markers to automatically create implementation summary
    - Call create-implementation-summary.sh script with context parameters:
      - `--changes`: Task IDs added and phase alignment (e.g., "Added T060-T076 for Phase 7")
      - `--related-specs`: Reference to plan.md phases the tasks align with (e.g., "plan.md Phase 7: Change Detection & Summary Pre-Population")
    - Example: `.spectri/scripts/spectri-trail/create-implementation-summary.sh --spec . --scope "tasks.md" --changes "Added T060-T076 for Phase 7 - Change Detection" --related-specs "plan.md Phase 7, spec.md US6, US7" ...`
    - Document what tasks were added and why (note preservation of existing tasks, summary will be pre-populated with context)
    - If summary creation fails, ERROR "Unable to create implementation summary"

12. **Stage Changes**: Add modified tasks.md to git staging
    - Add tasks.md to git staging area
    - Do NOT auto-commit - agent must review and commit
    - If staging fails, ERROR "Unable to stage changes to git"

13. **Report Completion**: Inform agent of successful completion
    - Confirm changes were made to tasks.md
    - Remind agent to review and commit changes
    - Suggest next appropriate command

<!-- INJECT: post-execution -->

---

**MANDATORY COMPLETION STEPS** - Execute ALL before ending this command:

1. **Create implementation summary**:
   ```bash
   bash .spectri/scripts/spectri-trail/create-implementation-summary.sh \
     --spec "$SPEC_FOLDER" \
     --scope "tasks revision" \
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

- Governing Spec: `spectri/specs/04-deployed/014-extend-tasks-module/spec.md`
