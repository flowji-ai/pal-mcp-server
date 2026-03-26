#!/usr/bin/env bash
set -euo pipefail

# resolve-prompt.sh - Mark a prompt as resolved and move to resolved/
# Usage: resolve-prompt.sh <prompt-file> --status <implemented|superseded> [--notes "resolution notes"]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/resolve-common.sh"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"

PROMPTS_DIR="$PROJECT_ROOT/spectri/coordination/prompts"
RESOLVED_DIR="$PROMPTS_DIR/resolved"

PROMPT_FILE=""
STATUS=""
NOTES=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --status)
      STATUS="$2"
      shift 2
      ;;
    --notes)
      NOTES="$2"
      shift 2
      ;;
    *)
      if [ -z "$PROMPT_FILE" ]; then
        PROMPT_FILE="$1"
        shift
      else
        log_error "Unknown argument: $1"
        echo "Usage: resolve-prompt.sh <prompt-file> --status <implemented|superseded> [--notes \"notes\"]"
        exit 1
      fi
      ;;
  esac
done

if [ -z "$PROMPT_FILE" ]; then
  log_error "Prompt file required"
  echo "Usage: resolve-prompt.sh <prompt-file> --status <implemented|superseded> [--notes \"notes\"]"
  exit 1
fi

# Resolve relative paths
if [[ ! "$PROMPT_FILE" = /* ]] && [[ ! -f "$PROMPT_FILE" ]]; then
  if [ -f "$PROMPTS_DIR/$PROMPT_FILE" ]; then
    PROMPT_FILE="$PROMPTS_DIR/$PROMPT_FILE"
  else
    PROMPT_FILE="$PROMPTS_DIR/$PROMPT_FILE"
  fi
fi

if [ ! -f "$PROMPT_FILE" ]; then
  log_error "Prompt file not found: $PROMPT_FILE"
  exit 1
fi

# Validate status
if [ -z "$STATUS" ]; then
  echo "Select resolution status:"
  echo "  1) implemented - Prompt work was completed and deployed"
  echo "  2) superseded  - Replaced by newer prompt or approach"
  read -rp "Choice [1-2]: " CHOICE
  case $CHOICE in
    1) STATUS="implemented" ;;
    2) STATUS="superseded" ;;
    *) log_error "Invalid choice"; exit 1 ;;
  esac
fi

if [[ "$STATUS" != "implemented" && "$STATUS" != "superseded" ]]; then
  log_error "Invalid status '$STATUS'. Valid: implemented, superseded"
  exit 1
fi

# Interactive prompts for missing args
if [ -z "$NOTES" ]; then
  read -rp "Resolution notes (or press Enter to skip): " NOTES
fi

BASENAME=$(basename "$PROMPT_FILE")
TODAY=$(get_date_timestamp)
NOW=$(get_iso_timestamp)

# Update frontmatter (add status field - prompts may not have had one before)
resolve_update_frontmatter "$PROMPT_FILE" "status" "$STATUS"
resolve_update_frontmatter "$PROMPT_FILE" "resolved_date" "$NOW"
if [ -n "$NOTES" ]; then
  resolve_update_frontmatter "$PROMPT_FILE" "resolution_notes" "\"$NOTES\""
fi

# Move to resolved/ (no filename suffix - standardised pattern)
resolve_move_to_resolved "$PROMPT_FILE" "$RESOLVED_DIR"

resolve_print_summary "Prompt" "$BASENAME" "$STATUS" "$TODAY" "spectri/coordination/prompts/resolved" "${NOTES:-Prompt resolved}"
