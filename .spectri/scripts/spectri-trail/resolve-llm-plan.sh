#!/usr/bin/env bash
set -euo pipefail

# resolve-llm-plan.sh - Mark an LLM plan as resolved and move to resolved/
# Usage: resolve-llm-plan.sh <plan-file> --status <implemented|superseded|abandoned> [--notes "resolution notes"]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/resolve-common.sh"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"

PLANS_DIR="$PROJECT_ROOT/spectri/coordination/llm-plans"

PLAN_FILE=""
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
      if [ -z "$PLAN_FILE" ]; then
        PLAN_FILE="$1"
        shift
      else
        log_error "Unknown argument: $1"
        echo "Usage: resolve-llm-plan.sh <plan-file> --status <implemented|superseded|abandoned> [--notes \"notes\"]"
        exit 1
      fi
      ;;
  esac
done

if [ -z "$PLAN_FILE" ]; then
  log_error "LLM plan file required"
  echo "Usage: resolve-llm-plan.sh <plan-file> --status <implemented|superseded|abandoned> [--notes \"notes\"]"
  exit 1
fi

# Resolve relative paths - search in llm-plans and per-agent subdirectories
if [[ ! "$PLAN_FILE" = /* ]] && [[ ! -f "$PLAN_FILE" ]]; then
  if [ -f "$PLANS_DIR/$PLAN_FILE" ]; then
    PLAN_FILE="$PLANS_DIR/$PLAN_FILE"
  else
    # Search subdirectories (e.g., claude-plans/, gemini-plans/)
    MATCH=$(find "$PLANS_DIR" -name "$PLAN_FILE" -not -path "*/resolved/*" -type f 2>/dev/null | head -1)
    if [ -n "$MATCH" ]; then
      PLAN_FILE="$MATCH"
    else
      PLAN_FILE="$PLANS_DIR/$PLAN_FILE"
    fi
  fi
fi

if [ ! -f "$PLAN_FILE" ]; then
  log_error "LLM plan file not found: $PLAN_FILE"
  exit 1
fi

# Validate status
VALID_STATUSES="implemented superseded abandoned"
if [ -z "$STATUS" ]; then
  echo "Select resolution status:"
  echo "  1) implemented - Plan was fully executed"
  echo "  2) superseded  - Replaced by newer plan or approach"
  echo "  3) abandoned   - Plan no longer needed"
  read -rp "Choice [1-3]: " CHOICE
  case $CHOICE in
    1) STATUS="implemented" ;;
    2) STATUS="superseded" ;;
    3) STATUS="abandoned" ;;
    *) log_error "Invalid choice"; exit 1 ;;
  esac
fi

if ! echo "$VALID_STATUSES" | grep -qw "$STATUS"; then
  log_error "Invalid status '$STATUS'. Valid: $VALID_STATUSES"
  exit 1
fi

# Interactive prompts for missing args
if [ -z "$NOTES" ]; then
  read -rp "Resolution notes (or press Enter to skip): " NOTES
fi

BASENAME=$(basename "$PLAN_FILE")
# Determine the parent directory to create resolved/ alongside the plan
PLAN_PARENT=$(dirname "$PLAN_FILE")
RESOLVED_DIR="$PLAN_PARENT/resolved"
TODAY=$(get_date_timestamp)
NOW=$(get_iso_timestamp)

# Update frontmatter
STATUS_UPPER=$(echo "$STATUS" | tr '[:lower:]' '[:upper:]')
if [ -n "$NOTES" ]; then
  resolve_update_frontmatter "$PLAN_FILE" "Status" "RESOLVED - $STATUS_UPPER: $NOTES"
else
  resolve_update_frontmatter "$PLAN_FILE" "Status" "RESOLVED - $STATUS_UPPER"
fi
resolve_update_frontmatter "$PLAN_FILE" "Resolved Date" "$NOW"

# Move to resolved/
resolve_move_to_resolved "$PLAN_FILE" "$RESOLVED_DIR"

RELATIVE_DEST="${RESOLVED_DIR#$PROJECT_ROOT/}"
resolve_print_summary "LLM-plan" "$BASENAME" "$STATUS" "$TODAY" "$RELATIVE_DEST" "${NOTES:-Plan resolved}"
