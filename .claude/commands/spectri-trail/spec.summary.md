---
managed_by: spectri
description: "Create implementation summary for recent work when automatic creation was missed"
model: sonnet
family: spectri-trail
origin:
  source: spectri
injections_applied:
  - user-input
  - finalization-verification
build_info:
  built_at: 2026-03-26T05:51:03Z
  manifest_version: 1.1.0
---
# Create Implementation Summary

<!-- INJECT: post-frontmatter -->

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Purpose

Create an implementation summary for recent work when automatic creation was missed or when working outside standard commands.

## Workflow

1. **Parse arguments**:
   - Check for `--scope` flag with value
   - **If scope provided**: Use it directly (non-interactive mode)
   - **If no scope**: Proceed to scope detection (interactive mode)

2. **Detect spec folder context**:
   - Determine current working directory
   - Extract spec folder pattern: `spectri/specs/NNN-feature-name/`
   - **If not in a spec folder**: ERROR "Not in a spec folder. Run this command from within a spec directory."

3. **Determine scope** (if not provided via `--scope`):

   a. **Analyze recent git changes**:
      ```bash
      # Get modified files (excluding implementation-summaries/)
      git diff --name-only HEAD | grep -v "implementation-summaries/"

      # Get untracked files
      git status --porcelain | grep "^??" | cut -d' ' -f2
      ```

   b. **Suggest scope based on changes**:
      - **Single file changed**: Suggest that filename as scope
      - **2-5 files changed**: Suggest pipe-separated filenames (e.g., `spec.md|plan.md`)
      - **Many files changed**: Suggest determining focus area:
        - Task range: `T001-T010`
        - Document: `plan.md`
        - Combined: `plan.md|research.md|tasks.md`

   c. **Check for completed tasks** (if tasks.md was modified):
      ```bash
      # Look for completed tasks in tasks.md
      COMPLETED_TASKS=$(git diff HEAD spectri/specs/*/tasks.md 2>/dev/null | grep -E "^\\- \\[x\\]|^\\+\\[X\\]" | wc -l | tr -d ' ')
      if [[ $COMPLETED_TASKS -gt 0 ]]; then
          echo "Note: $COMPLETED_TASKS completed tasks detected in tasks.md - consider task range scope instead"
      fi
      ```

   d. **Prompt user for scope confirmation**:
      - Display suggested scope
      - Allow user to confirm or provide custom scope
      - **If empty scope provided**: ERROR "Scope cannot be empty"

4. **Verify spec reflects current reality**:

   <HARD-GATE>
   Before creating the implementation summary, confirm that `spec.md` has been updated to reflect the work being documented. Implementation summaries are immutable snapshots — if the spec still describes pre-change behaviour, the summary will document reality while the spec does not, creating permanent audit trail drift.

   Check whether `spec.md` is staged or has been modified in the current working tree:
   ```bash
   git diff --name-only --cached | grep "spec.md" || git diff --name-only | grep "spec.md"
   ```

   - **If spec.md is staged or modified**: Proceed — the spec is being updated alongside this work.
   - **If spec.md is NOT staged or modified**: Ask the agent/user: "Has spec.md been updated to reflect this work? The spec must describe current behaviour before an implementation summary is created." Block until confirmed.
   - **If the work does not change observable behaviour** (e.g., refactoring, formatting, internal-only changes): The agent may confirm "no spec update needed" and proceed.
   </HARD-GATE>

5. **Generate implementation summary**:

   a. **Create timestamp**:
      - Filename format: `YYYY-MM-DD-HHMM` (e.g., `2026-01-14-2148`)
      - ISO format for frontmatter: `YYYY-MM-DDTHH:MM:SS+HH:MM`

   b. **Determine summary filename**:
      - Base: `{timestamp}_{scope-description}.md`
      - Example: `2026-01-14-2148_spec-creation.md`

   c. **Create summary file**:
      - Path: `{spec-folder}/implementation-summaries/{filename}`
      - Load `.spectri/templates/spectri-trail/implementation-summary-template.md`
      - If template not found, ERROR "Template not found at .spectri/templates/spectri-trail/implementation-summary-template.md"

6. **Stage the summary file**:
   ```bash
   git add "{spec-folder}/implementation-summaries/{filename}"
   ```

7. **Report completion**:
   ```
   Created implementation summary:
     File: {full-path-to-summary}
     Scope: {scope}

   Remember to:
   1. Fill in narrative sections in the summary file
   2. Commit work + summary together
   ```

## Examples

```bash
# Interactive mode - will analyze changes and prompt for scope
/spec.summary

# Non-interactive mode - provide scope directly
/spec.summary --scope "spec.md|plan.md"

# Task range scope
/spec.summary --scope "T001-T015"
```

## Scope Format

- **Single document**: `spec.md`
- **Multiple documents**: `spec.md|plan.md|tasks.md` (pipe-separated)
- **Task range**: `T001-T010`
- **Phase**: `PHASE_1` or `PHASE_2`
- **Combined**: `plan.md|research.md`

<!-- INJECT: post-finalization -->

## Finalization Checklist

Before completing this command, verify:

- [ ] **Implementation summary created**: `bash .spectri/scripts/spectri-trail/create-implementation-summary.sh --spec "$SPEC_FOLDER" --scope "[scope]"`
- [ ] **meta.json updated** (when applicable): `bash .spectri/scripts/shared/update-spec-meta.sh --spec "$SPEC_FOLDER" --updated-by "[session-id]"` (Only update meta.json when command modifies spec state, not during implementation phases)
- [ ] **Work committed to git**: Commit using appropriate commands
