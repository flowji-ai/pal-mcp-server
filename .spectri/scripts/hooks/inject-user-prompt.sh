#!/usr/bin/env bash
# inject-user-prompt.sh — UserPromptSubmit hook for using-spectri
# Injects a short reinforcement reminder on every user message.
#
# Deployed to: .spectri/scripts/hooks/inject-user-prompt.sh
# Configured in: .claude/settings.json under hooks.UserPromptSubmit
# Fires on: every user message (no matcher support for this event type)

set -euo pipefail

REMINDER="You MUST use a Spectri skill or /spec.* command if one exists for the action you are about to take. This is not optional. Confirm with the user which skill or command you are going to use before using it. Do not rationalise skipping this."

cat <<JSONEOF
{
  "hookSpecificOutput": {
    "additionalContext": "<EXTREMELY_IMPORTANT>${REMINDER}</EXTREMELY_IMPORTANT>"
  }
}
JSONEOF
