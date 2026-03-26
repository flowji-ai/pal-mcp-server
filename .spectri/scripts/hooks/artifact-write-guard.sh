#!/usr/bin/env bash
# artifact-write-guard.sh — PreToolUse hook for Claude Code
#
# Purpose: Blocks manual file creation in known artifact directories,
# directing agents to use the correct /spec.* command instead.
#
# This prevents agents from bypassing command workflows by manually
# creating artifacts (issues, ADRs, RFCs, threads, etc.).
#
# Input: JSON on stdin with tool_name and tool_input
# Output: JSON with decision "block" and reason, or empty for allow
#
# Spec: spectri/issues/2026-02-13-agents-bypass-commands-copy-existing-files.md

set -euo pipefail

# Read stdin (tool input JSON)
INPUT=$(cat)

# Extract file_path from tool_input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

# If no file_path, allow (not a file write)
if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

# Normalize path — resolve absolute paths to repo-relative
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
if [[ -n "$REPO_ROOT" && "$FILE_PATH" == "$REPO_ROOT/"* ]]; then
  FILE_PATH="${FILE_PATH#$REPO_ROOT/}"
fi
FILE_PATH="${FILE_PATH#./}"

# Artifact directory → command mapping
# Each entry: directory_pattern|command|description
ARTIFACT_MAPPINGS=(
  "spectri/issues/|/spec.issue|issues"
  "spectri/adr/|/spec.adr|Architecture Decision Records"
  "spectri/rfc/|/spec.rfc|Request for Comments"
  "spectri/coordination/threads/|spectri-threads skill|continuation threads"
  "spectri/coordination/llm-plans/|spectri-llm-plans skill|LLM plans"
  "spectri/coordination/prompts/|spectri-prompts skill|prompts"
  "spectri/coordination/brainstorms/|spectri-brainstorming skill|brainstorms"
)

# Special case: implementation summaries (nested path, not a fixed prefix)
# Pattern: spectri/specs/<stage>/<spec-id>/implementation-summaries/*.md
if [[ "$FILE_PATH" == spectri/specs/*/implementation-summaries/*.md ]]; then
  if [[ -f "$FILE_PATH" ]] || [[ -n "$REPO_ROOT" && -f "$REPO_ROOT/$FILE_PATH" ]]; then
    exit 0
  fi
  echo "Use /spec.summary to create implementation summaries instead of manually creating files. The command calls the creation script which timestamps filenames from the system clock — agents must not supply the filename." >&2
  exit 2
fi

# Check if the file is in a guarded artifact directory
for mapping in "${ARTIFACT_MAPPINGS[@]}"; do
  IFS='|' read -r dir_pattern command desc <<< "$mapping"

  if [[ "$FILE_PATH" == ${dir_pattern}* ]]; then
    # Exception: allow writes to resolved/ subdirectories (part of resolve workflow)
    if [[ "$FILE_PATH" == *"/resolved/"* ]]; then
      exit 0
    fi

    # Exception: allow writes to screenshots/ subdirectories
    if [[ "$FILE_PATH" == *"/screenshots/"* ]]; then
      exit 0
    fi

    # Exception: allow writes to templates/ subdirectories
    if [[ "$FILE_PATH" == *"/templates/"* ]]; then
      exit 0
    fi

    # Exception: allow SPECTRI.md files (build artifacts)
    if [[ "$FILE_PATH" == */SPECTRI.md ]]; then
      exit 0
    fi

    # Exception: allow deferred-to-spec/ subdirectories
    if [[ "$FILE_PATH" == *"/deferred-to-spec/"* ]]; then
      exit 0
    fi

    # Exception: allow updates to existing files (command-initiated workflow)
    # Only block NEW file creation - commands update files after creation
    if [[ -f "$FILE_PATH" ]] || [[ -n "$REPO_ROOT" && -f "$REPO_ROOT/$FILE_PATH" ]]; then
      exit 0
    fi

    # Block the write and suggest the correct command
    echo "Use ${command} to create ${desc} instead of manually creating files in ${dir_pattern}. The command handles template structure, metadata population, script-driven validation, and correct file placement. If you are running ${command} or a resolve script, this guard should not fire — check the file path." >&2
    exit 2
  fi
done

# Not in a guarded directory — allow
exit 0
