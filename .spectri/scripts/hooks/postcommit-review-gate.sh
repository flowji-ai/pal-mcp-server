#!/usr/bin/env bash
# postcommit-review-gate.sh — PostToolUse hook on Bash (git commit) for Claude Code
#
# Purpose: After a git commit, checks whether the committed files include
# the required bundle elements (implementation summary when code or spec changed).
# Warns via additionalContext — does NOT block (commit already happened).
#
# ADVISORY ONLY — always exits 0.
#
# Input: JSON on stdin with tool_input.command (the Bash command that ran)
# Fires only when the command contains "git commit"
#
# Deployed to: .spectri/scripts/hooks/postcommit-review-gate.sh
# Configured in: hooks.json manifest under PostToolUse/Bash

set -euo pipefail

# Read stdin (tool input JSON)
INPUT=$(cat)

# Extract command from tool_input
if command -v jq &>/dev/null; then
  CMD=$(printf '%s\n' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || true)
else
  CMD=$(printf '%s\n' "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null || true)
fi

# Only fire for git commit commands
case "$CMD" in
  *"git commit"*) ;;
  *) exit 0 ;;
esac

# Find project root via git
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$PROJECT_ROOT" ]; then
  exit 0
fi

# Get the files changed in the last commit
COMMITTED_FILES=$(git diff-tree --no-commit-id --name-only -r HEAD 2>/dev/null || true)
if [ -z "$COMMITTED_FILES" ]; then
  exit 0
fi

WARNINGS=""

# Check if any code/script/config files were committed
HAS_CODE=false
while IFS= read -r file; do
  case "$file" in
    src/*|tests/*|scripts/*|lib/*|*.py|*.sh|*.js|*.ts|*.json|*.toml|*.yaml|*.yml)
      HAS_CODE=true
      break
      ;;
  esac
done <<< "$COMMITTED_FILES"

# Check if any spec files were committed
HAS_SPEC=false
while IFS= read -r file; do
  case "$file" in
    spectri/specs/*/spec.md)
      HAS_SPEC=true
      break
      ;;
  esac
done <<< "$COMMITTED_FILES"

# Check if any implementation summary was committed
HAS_SUMMARY=false
while IFS= read -r file; do
  case "$file" in
    spectri/specs/*/implementation-summaries/*)
      HAS_SUMMARY=true
      break
      ;;
  esac
done <<< "$COMMITTED_FILES"

# Build warnings
if [ "$HAS_CODE" = true ] && [ "$HAS_SUMMARY" = false ]; then
  WARNINGS="${WARNINGS}The last commit included code changes but no implementation summary. "
  WARNINGS="${WARNINGS}If this commit changed behaviour, consider creating a follow-up commit with /spec.summary. "
fi

if [ "$HAS_SPEC" = true ] && [ "$HAS_SUMMARY" = false ]; then
  WARNINGS="${WARNINGS}The last commit updated spec files but no implementation summary was included. "
  WARNINGS="${WARNINGS}Implementation summaries document what changed and why — create one with /spec.summary. "
fi

# Output warning if any
if [ -n "$WARNINGS" ]; then
  cat <<JSONEOF
{
  "hookSpecificOutput": {
    "additionalContext": "<IMPORTANT>Post-Commit Bundle Review: ${WARNINGS}The Spectri work cycle requires implementation summaries for code and spec changes.</IMPORTANT>"
  }
}
JSONEOF
fi

# Always exit 0 — advisory only, commit already happened
exit 0
