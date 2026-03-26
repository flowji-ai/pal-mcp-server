#!/usr/bin/env bash
# inject-session-start.sh — SessionStart/SubagentStart/PostCompact hook for using-spectri
# Reads the using-spectri SKILL.md and outputs it as additionalContext for Claude Code.
#
# Also used by SubagentStart and PostCompact hooks (same injection).
# SKILL.md already contains its own EXTREMELY_IMPORTANT tags — do NOT double-wrap.
#
# Deployed to: .spectri/scripts/hooks/inject-session-start.sh
# Configured in: .claude/settings.json under hooks.SessionStart/SubagentStart/PostCompact

set -euo pipefail

# Find project root via git (works regardless of where the hook is invoked from)
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$PROJECT_ROOT" ]; then
  exit 0
fi

SKILL_FILE="$PROJECT_ROOT/.claude/skills/using-spectri/SKILL.md"

if [ ! -f "$SKILL_FILE" ]; then
  echo "Warning: using-spectri SKILL.md not found at $SKILL_FILE" >&2
  echo "Hint: Run 'spectri sync-canonical' to deploy skills" >&2
  exit 0
fi

# JSON-escape the content (prefer jq, fallback to python3)
if command -v jq &>/dev/null; then
  ESCAPED=$(jq -Rs . < "$SKILL_FILE") || { echo "Error: jq failed to escape SKILL.md" >&2; exit 0; }
else
  ESCAPED=$(python3 -c "import json,sys; print(json.dumps(sys.stdin.read()))" < "$SKILL_FILE") || { echo "Error: python3 fallback failed" >&2; exit 0; }
fi

cat <<JSONEOF
{
  "hookSpecificOutput": {
    "additionalContext": ${ESCAPED}
  }
}
JSONEOF
