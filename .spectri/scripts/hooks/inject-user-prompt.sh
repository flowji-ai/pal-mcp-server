#!/usr/bin/env bash
# inject-user-prompt.sh — UserPromptSubmit hook for using-spectri
# Injects a short reinforcement reminder on every user message.
#
# Deployed to: .spectri/scripts/hooks/inject-user-prompt.sh
# Configured in: .claude/settings.json under hooks.UserPromptSubmit
# Fires on: every user message (no matcher support for this event type)

set -euo pipefail

REMINDER="TOOLING-FIRST LAW — ZERO EXCEPTIONS. Before taking any action in response to this request, check your available skills and commands for existing automation. If a Spectri skill or /spec.* command covers any actions you are about to take, you MUST use it — manual execution is a violation. State the skill or command you will use and get user confirmation before proceeding. If none exists, state that no matching skill or command applies and why. Skipping this, rationalising around it, or proceeding without confirmation is forbidden."

cat <<JSONEOF
{
  "hookSpecificOutput": {
    "additionalContext": "<EXTREMELY_IMPORTANT>${REMINDER}</EXTREMELY_IMPORTANT>"
  }
}
JSONEOF
