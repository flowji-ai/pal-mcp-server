#!/usr/bin/env bash
# inject-user-prompt.sh — UserPromptSubmit hook for using-spectri
# Injects a short reinforcement reminder on every user message.
#
# Deployed to: .spectri/scripts/hooks/inject-user-prompt.sh
# Configured in: .claude/settings.json under hooks.UserPromptSubmit
# Fires on: every user message (no matcher support for this event type)

set -euo pipefail

REMINDER="BEFORE responding: check if a Spectri skill applies to this task (even 1% chance). If yes, invoke it via the Skill tool FIRST. If you are about to create a file in spectri/, check if a creation script exists. Do not rationalise skipping this check."

cat <<JSONEOF
{
  "hookSpecificOutput": {
    "additionalContext": "<EXTREMELY_IMPORTANT>${REMINDER}</EXTREMELY_IMPORTANT>"
  }
}
JSONEOF
