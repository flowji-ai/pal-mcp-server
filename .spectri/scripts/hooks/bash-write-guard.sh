#!/usr/bin/env bash
# bash-write-guard.sh — PreToolUse hook on Bash tool for Claude Code
#
# Purpose: Blocks Bash commands that could write to spectri/ artifact directories,
# using an ALLOWLIST approach. If a command references spectri/ (the artifact dir),
# it must be either (a) the spectri CLI, (b) a .spectri/scripts/ invocation, or
# (c) a known read-only tool. Everything else is blocked.
#
# Protects: spectri/ (artifact dirs: issues, specs, adr, rfc, coordination, research)
# Allows: .spectri/ (infra dir), read-only commands, running .spectri/scripts/
#
# Input: JSON on stdin with tool_name and tool_input.command
# Output: exit 0 to allow, exit 2 to block (with reason on stderr)
#
# Deployed to: .spectri/scripts/hooks/bash-write-guard.sh
# Configured in: hooks.json manifest under PreToolUse/Bash
#
# --- Known Limitations ---
# This guard performs static pattern matching on the command string.
# 1. Variable expansion: $DIR/spectri/... bypasses detection (variables not resolved)
# 2. Subshell indirection: $(echo spectri)/issues/... same reason
# 3. Shell quoting in arguments: grep "a|b" spectri/ may false-positive because
#    segment/pipe splitting does not respect quoted strings. Error mode is
#    over-blocking (false positive), never under-blocking (false negative).
# These are inherent to pre-execution static analysis, not bugs.
# Defence in depth (Write/Edit guards, spec-folder guards) provides additional coverage.
# -------------------------

set -euo pipefail

# Read stdin (tool input JSON)
INPUT=$(cat)

# Extract command from tool_input
# Use || true to prevent set -e from killing us on parse failures (malformed JSON)
if command -v jq &>/dev/null; then
  CMD=$(printf '%s\n' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || true)
else
  CMD=$(printf '%s\n' "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null || true)
fi

# If no command, allow
if [[ -z "$CMD" ]]; then
  exit 0
fi

# --- Step 1: Does the command reference spectri/ (not .spectri/)? ---
# Replace .spectri/ with a placeholder to avoid false positives, then check
# Use escaped dot in sed pattern to match literal .spectri/ only
CLEANED=$(printf '%s\n' "$CMD" | sed 's|\.spectri/|__DOT_SPECTRI__|g')

if ! printf '%s\n' "$CLEANED" | grep -q 'spectri/'; then
  # Command does not reference spectri/ artifact dirs — allow
  exit 0
fi

# --- Step 2: Is it running .spectri/scripts/ or the spectri CLI? ---
# Check against original CMD (not cleaned) for .spectri/scripts/
if printf '%s\n' "$CMD" | grep -qE '(^|[[:space:];|&])bash[[:space:]]+\.spectri/scripts/'; then
  # But also check: does the full command have OTHER references to spectri/ (chained commands)?
  # Remove .spectri/scripts/ invocations and re-check
  AFTER_SCRIPT=$(printf '%s\n' "$CMD" | sed 's|bash[[:space:]]*\.spectri/scripts/[^ ;|&]*||g' | sed 's|\.spectri/|__DOT_SPECTRI__|g')
  if ! printf '%s\n' "$AFTER_SCRIPT" | grep -q 'spectri/'; then
    exit 0
  fi
  # Fall through — the chained part still references spectri/
fi

if printf '%s\n' "$CMD" | grep -qE '(^|[[:space:];|&])\.spectri/scripts/'; then
  AFTER_SCRIPT=$(printf '%s\n' "$CMD" | sed 's|\.spectri/scripts/[^ ;|&]*||g' | sed 's|\.spectri/|__DOT_SPECTRI__|g')
  if ! printf '%s\n' "$AFTER_SCRIPT" | grep -q 'spectri/'; then
    exit 0
  fi
fi

# Check spectri CLI
if printf '%s\n' "$CMD" | grep -qE '(^|[[:space:];|&])spectri[[:space:]]'; then
  AFTER_CLI=$(printf '%s\n' "$CMD" | sed 's|spectri[[:space:]][^ ;|&]*||g' | sed 's|\.spectri/|__DOT_SPECTRI__|g')
  if ! printf '%s\n' "$AFTER_CLI" | grep -q 'spectri/'; then
    exit 0
  fi
fi

# --- Step 3: Is the command a known read-only tool? ---
# Read-only allowlist: commands that only read, never write
# For each "segment" of a chained command (split by ; && || |), check if the
# part that references spectri/ uses only read-only tools.

# Strategy: check whether ALL references to spectri/ in the cleaned command
# are preceded by a read-only command. If any reference to spectri/ is NOT
# preceded by a read-only tool, block.

# Read-only tool patterns (the tool must be the command, not an argument)
# We check each ;/&&/||-delimited segment that contains spectri/
READONLY_PATTERN='^[[:space:]]*(cat|ls|find|grep|egrep|fgrep|rg|head|tail|wc|diff|file|stat|test|\[|git[[:space:]]+(log|diff|show|blame|status|ls-files|rev-parse))[[:space:]]'

# Redirect pattern: > or >> followed by a path containing spectri/
# This catches "cat > spectri/..." which would otherwise match the read-only allowlist
REDIRECT_TO_SPECTRI='>+[[:space:]]*[^ ]*spectri/'

blocked=false

# Split command on ; && || into segments and check each
# Use newline-delimited segments for iteration
# Note: pipe (|) chains are fine — the first command in a pipe determines write behaviour
SEGMENTS=$(printf '%s\n' "$CMD" | sed 's/&&/\n/g; s/||/\n/g; s/;/\n/g')

while IFS= read -r segment; do
  # Skip empty segments
  [ -z "$segment" ] && continue

  # Clean .spectri/ references
  seg_cleaned=$(printf '%s\n' "$segment" | sed 's|\.spectri/|__DOT_SPECTRI__|g')

  # Does this segment reference spectri/?
  if printf '%s\n' "$seg_cleaned" | grep -q 'spectri/'; then
    # First check: does this segment contain a redirect to spectri/?
    # This catches "cat > spectri/..." which starts with a read-only tool
    # but uses a redirect to write.
    if printf '%s\n' "$seg_cleaned" | grep -qE "$REDIRECT_TO_SPECTRI"; then
      blocked=true
      break
    fi

    # Check if it's a read-only tool
    # Strip leading pipe portions — for "cat foo | grep spectri/", the write-relevant
    # command is the one that has spectri/ as an argument, not the pipe source
    # Actually, within a single segment (already split on ;/&&/||), pipes are safe
    # because piped commands don't write to their arguments. But we should check
    # the first command in the pipe chain that references spectri/.

    # Find the pipe-segment that contains spectri/
    pipe_parts=$(printf '%s\n' "$segment" | tr '|' '\n')
    while IFS= read -r pipe_part; do
      pp_cleaned=$(printf '%s\n' "$pipe_part" | sed 's|\.spectri/|__DOT_SPECTRI__|g')
      if printf '%s\n' "$pp_cleaned" | grep -q 'spectri/'; then
        # Trim leading whitespace for pattern match
        trimmed=$(printf '%s\n' "$pipe_part" | sed 's/^[[:space:]]*//')
        if ! printf '%s\n' "$trimmed" | grep -qE "$READONLY_PATTERN"; then
          blocked=true
          break 2
        fi
      fi
    done <<< "$pipe_parts"
  fi
done <<< "$SEGMENTS"

if [ "$blocked" = true ]; then
  printf '%s\n' "BLOCKED: Bash command writes to spectri/ artifact directory. Use the appropriate Spectri command or Write/Edit tool instead. Direct file operations via Bash bypass artifact guards. If you need to run a .spectri/scripts/ script, that is allowed." >&2
  exit 2
fi

# All segments with spectri/ references use read-only tools — allow
exit 0
