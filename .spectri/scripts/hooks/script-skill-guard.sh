#!/usr/bin/env bash
# script-skill-guard.sh — PreToolUse hook for Bash tool
#
# Purpose: Warns agents when they call creation scripts directly via
# the Bash tool, reminding them to use the governing skill or command.
#
# This is a SOFT GUARD (exit 0 with warning), not a BLOCK. The script
# still runs — but the agent sees the warning and should self-correct
# if it wasn't already operating within the governing skill.
#
# Input: JSON on stdin with tool_name and tool_input.command
# Output: Warning on stderr if creation script detected; always exit 0
#
# Related issue: 2026-03-15-glm-cannot-operate-within-skill-orchestrated-frameworks.md

set -euo pipefail

# Read stdin (tool input JSON)
INPUT=$(cat)

# Extract command from tool_input
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# If no command, nothing to check
if [[ -z "$COMMAND" ]]; then
  exit 0
fi

# Script → governing skill/command mapping
# Format: script_name|skill_or_command|invocation_hint
SCRIPT_MAPPINGS=(
  "create-issue.sh|/spec.issue command|Invoke via Skill tool: spectri-quality:spec.issue"
  "create-backlog-item.sh|spectri-backlog skill|Skill auto-invokes when task matches backlog capture"
  "create-spec.sh|/spec.specify command|Invoke via Skill tool: spectri-core:spec.specify"
  "create-plan-scaffold.sh|/spec.plan command|Invoke via Skill tool: spectri-core:spec.plan"
  "create-design.sh|/spec.plan command|Part of the spec.plan workflow"
  "create-adr.sh|/spec.adr command|Invoke via Skill tool: spectri-trail:spec.adr"
  "create-rfc.sh|/spec.rfc command|Invoke via Skill tool: spectri-trail:spec.rfc"
  "create-thread.sh|spectri-threads skill|Skill auto-invokes when task matches thread operations"
  "create-implementation-summary.sh|/spec.summary command|Invoke via Skill tool: spectri-trail:spec.summary"
  "create-llm-plan.sh|spectri-llm-plans skill|Skill auto-invokes when task matches LLM plan operations"
  "create-prompt.sh|spectri-prompts skill|Skill auto-invokes when task matches prompt operations"
  "create-review.sh|spectri-reviews skill|Skill auto-invokes when task matches review operations"
  "create-brainstorm.sh|spectri-brainstorming skill|Skill auto-invokes when task matches brainstorming"
  "create-research.sh|spectri-research skill|Skill auto-invokes when task matches research operations"
  "create-adrs-from-suggestions.sh|/spec.adr command|Invoke via Skill tool: spectri-trail:spec.adr"
)

# Check if the command calls a creation script
for mapping in "${SCRIPT_MAPPINGS[@]}"; do
  IFS='|' read -r script_name governing hint <<< "$mapping"

  if [[ "$COMMAND" == *"$script_name"* ]]; then
    cat >&2 <<EOF
⚠️  TOOLING-FIRST MANDATE — Script-Skill Guard

You are calling ${script_name} directly via the Bash tool.
This script is governed by: ${governing}
${hint}

If you are already operating within this skill/command, proceed.
If NOT, STOP and use the governing skill/command instead.

The Tooling-First Mandate requires: Skill → Command → Script → Manual.
Calling scripts directly bypasses the workflow guidance, interactive
gates, and quality checks that the skill/command provides.
EOF
    exit 0
  fi
done

# Not a creation script — nothing to warn about
exit 0
