#!/usr/bin/env bash
# stop-completion-gate.sh — Stop hook for Claude Code
#
# Purpose: Advisory check that fires when the agent is about to present its
# response to the user. Checks if staged changes are missing an implementation
# summary or spec update and reminds the agent.
#
# ADVISORY ONLY — always exits 0. Outputs additionalContext warnings.
# Does NOT block the agent from completing.
#
# Deployed to: .spectri/scripts/hooks/stop-completion-gate.sh
# Configured in: hooks.json manifest under Stop

set -euo pipefail

# Find project root via git
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$PROJECT_ROOT" ]; then
  exit 0
fi

# Check for staged changes
STAGED=$(git diff --cached --name-only 2>/dev/null || true)
if [ -z "$STAGED" ]; then
  # No staged changes — nothing to check
  exit 0
fi

WARNINGS=""

# Check if any code/script/config files are staged
HAS_CODE=false
while IFS= read -r file; do
  case "$file" in
    src/*|tests/*|scripts/*|lib/*|*.py|*.sh|*.js|*.ts|*.json|*.toml|*.yaml|*.yml)
      HAS_CODE=true
      break
      ;;
  esac
done <<< "$STAGED"

# Check if any spec files are staged
HAS_SPEC=false
while IFS= read -r file; do
  case "$file" in
    spectri/specs/*/spec.md)
      HAS_SPEC=true
      break
      ;;
  esac
done <<< "$STAGED"

# Check if any implementation summary is staged
HAS_SUMMARY=false
while IFS= read -r file; do
  case "$file" in
    spectri/specs/*/implementation-summaries/*)
      HAS_SUMMARY=true
      break
      ;;
  esac
done <<< "$STAGED"

# Build warnings
if [ "$HAS_CODE" = true ] && [ "$HAS_SUMMARY" = false ]; then
  WARNINGS="${WARNINGS}Code changes are staged but no implementation summary is included. "
  WARNINGS="${WARNINGS}If this commit changes behaviour, create one with /spec.summary before committing. "
fi

if [ "$HAS_SPEC" = true ] && [ "$HAS_SUMMARY" = false ]; then
  WARNINGS="${WARNINGS}Spec updates are staged but no implementation summary is included. "
  WARNINGS="${WARNINGS}Run /spec.summary before committing to document this change. "
fi

# Output warning if any
if [ -n "$WARNINGS" ]; then
  cat <<JSONEOF
{
  "hookSpecificOutput": {
    "additionalContext": "<IMPORTANT>Commit Bundle Check: ${WARNINGS}The Spectri work cycle requires implementation summaries for code and spec changes.</IMPORTANT>"
  }
}
JSONEOF
fi

# Always exit 0 — advisory only
exit 0
