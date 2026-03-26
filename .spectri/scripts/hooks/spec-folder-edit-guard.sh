#!/usr/bin/env bash
# spec-folder-edit-guard.sh — PreToolUse hook for Claude Code
#
# Purpose: Blocks edits to files in a spec folder when another spec folder
# already has uncommitted changes. Enforces the commit-per-spec-folder
# work cycle by preventing cross-spec-folder edit accumulation.
#
# Input: JSON on stdin with tool_name and tool_input
# Output: JSON with decision "block" and reason, or empty for allow
#
# Spec: spectri/issues/2026-02-13-agents-skip-commits-accumulate-dirty-working-tree.md

set -euo pipefail

# Read stdin (tool input JSON)
INPUT=$(cat)

# Extract file_path from tool_input
# For Edit: tool_input.file_path
# For Write: tool_input.file_path
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

# If no file_path, allow
if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

# Normalize path — resolve absolute paths to repo-relative
REPO_ROOT_NORM=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
if [[ -n "$REPO_ROOT_NORM" && "$FILE_PATH" == "$REPO_ROOT_NORM/"* ]]; then
  FILE_PATH="${FILE_PATH#$REPO_ROOT_NORM/}"
fi
FILE_PATH="${FILE_PATH#./}"

# Check if this edit targets a spec folder
# Pattern: spectri/specs/0N-stage/NNN-name/
if ! echo "$FILE_PATH" | grep -qE '^spectri/specs/0[0-5]-[^/]+/[^/]+/' 2>/dev/null; then
  # Not editing a spec folder — allow
  exit 0
fi

# Extract the target spec folder (e.g., spectri/specs/02-implementing/025-dashboard/)
TARGET_FOLDER=$(echo "$FILE_PATH" | grep -oE '^spectri/specs/0[0-5]-[^/]+/[^/]+/' 2>/dev/null)

if [[ -z "$TARGET_FOLDER" ]]; then
  exit 0
fi

# Get repo root
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || exit 0)

# Find all dirty spec folders (modified or untracked files)
# Strip the 2-char status code + space prefix before matching, so renames and
# other multi-path lines don't match the status prefix as part of the path.
DIRTY_FOLDERS=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null \
  | sed 's/^...//' \
  | grep -oE 'spectri/specs/0[0-5]-[^/]+/[^/]+/' \
  | sort -u 2>/dev/null || true)

# Check if any dirty folder is DIFFERENT from the target
OTHER_DIRTY=""
while IFS= read -r folder; do
  [[ -z "$folder" ]] && continue
  if [[ "$folder" != "$TARGET_FOLDER" ]]; then
    OTHER_DIRTY="$folder"
    break
  fi
done <<< "$DIRTY_FOLDERS"

# If another spec folder has uncommitted changes, block
if [[ -n "$OTHER_DIRTY" ]]; then
  echo "Another spec folder (${OTHER_DIRTY}) has uncommitted changes. Commit changes there first before editing ${TARGET_FOLDER}. The Work Cycle requires: Execute → Document → Update Meta → Commit per spec folder. Run: git add ${OTHER_DIRTY} && git commit -m 'feat(spec-NNN): description'" >&2
  exit 2
fi

# No other dirty spec folders — allow
exit 0
