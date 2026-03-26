#!/usr/bin/env bash
# spec-folder-watchdog.sh — PostToolUse hook for Claude Code
#
# Purpose: After every Edit/Write, counts dirty spec folders in the working tree.
# Warns the agent when more than 1 spec folder has uncommitted changes,
# enforcing the commit-per-spec-folder work cycle.
#
# Input: JSON on stdin with tool_name and tool_input
# Output: Warning message string if >1 dirty spec folder, empty otherwise
#
# Spec: spectri/issues/2026-02-13-agents-skip-commits-accumulate-dirty-working-tree.md

set -euo pipefail

# Read stdin (consume it, but we don't need the specific tool input)
cat > /dev/null

# Get the repo root
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || exit 0)

# Find dirty spec folders by checking git status for modified/untracked files
# in spectri/specs/ directories. Strip the 2-char status code + space prefix
# before matching to correctly handle renames and other multi-path lines.
DIRTY_FOLDERS=$(cd "$REPO_ROOT" && git status --porcelain 2>/dev/null \
  | sed 's/^...//' \
  | grep -oE 'spectri/specs/0[0-5]-[^/]+/[^/]+/' \
  | sort -u 2>/dev/null || true)

if [[ -z "$DIRTY_FOLDERS" ]]; then
  DIRTY_COUNT=0
else
  DIRTY_COUNT=$(echo "$DIRTY_FOLDERS" | wc -l)
fi

# If more than 1 spec folder is dirty, warn the agent
if [[ "$DIRTY_COUNT" -gt 1 ]]; then
  FOLDER_LIST=$(echo "$DIRTY_FOLDERS" | sed 's/^/  - /')
  echo "WARNING: ${DIRTY_COUNT} spec folders have uncommitted changes. The Work Cycle requires committing after completing work on each spec folder before moving to the next. Dirty spec folders:"
  echo "$FOLDER_LIST"
  echo ""
  echo "Please commit changes for the current spec folder before editing another. Use: git add <spec-folder> && git commit -m \"feat(spec-NNN): description\""
fi

exit 0
