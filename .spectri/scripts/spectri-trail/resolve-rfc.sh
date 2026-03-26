#!/usr/bin/env bash
set -euo pipefail

# resolve-rfc.sh - Mark an RFC as resolved and move to spectri/rfc/resolved/
# Usage: resolve-rfc.sh <rfc-name> --status <Implemented|Superseded|Resolved|Rejected> [--notes "reason"] [--superseded-by "RFC-YYYY-MM-DD-slug"]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/resolve-common.sh"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"

RFC_DIR="$PROJECT_ROOT/spectri/rfc"
RESOLVED_DIR="$RFC_DIR/resolved"

RFC_NAME=""
STATUS=""
NOTES=""
SUPERSEDED_BY=""

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
    --superseded-by)
      SUPERSEDED_BY="$2"
      shift 2
      ;;
    *)
      if [ -z "$RFC_NAME" ]; then
        RFC_NAME="$1"
        shift
      else
        log_error "Unknown argument: $1"
        echo "Usage: resolve-rfc.sh <rfc-name> --status <Implemented|Superseded|Resolved|Rejected> [--notes \"reason\"] [--superseded-by \"RFC-YYYY-MM-DD-slug\"]"
        exit 1
      fi
      ;;
  esac
done

if [ -z "$RFC_NAME" ]; then
  log_error "RFC name required"
  echo "Usage: resolve-rfc.sh <rfc-name> --status <Implemented|Superseded|Resolved|Rejected> [--notes \"reason\"]"
  exit 1
fi

# Find RFC file (supports partial match)
RFC_FILE=""
if [ -f "$RFC_NAME" ]; then
  RFC_FILE="$RFC_NAME"
elif [ -f "$RFC_DIR/$RFC_NAME" ]; then
  RFC_FILE="$RFC_DIR/$RFC_NAME"
else
  MATCHES=$(find "$RFC_DIR" -maxdepth 1 -iname "*${RFC_NAME}*" -type f 2>/dev/null)
  MATCH_COUNT=$(echo "$MATCHES" | grep -c . 2>/dev/null || echo "0")

  if [ "$MATCH_COUNT" -eq 0 ]; then
    log_error "No RFC found matching '$RFC_NAME'"
    echo ""
    echo "Available RFCs:"
    ls -1 "$RFC_DIR"/*.md 2>/dev/null | xargs -n1 basename >&2
    exit 1
  elif [ "$MATCH_COUNT" -gt 1 ]; then
    log_error "Multiple RFCs match '$RFC_NAME':"
    echo "$MATCHES" | xargs -n1 basename >&2
    echo ""
    echo "Please be more specific."
    exit 1
  else
    RFC_FILE="$MATCHES"
  fi
fi

if [ ! -f "$RFC_FILE" ]; then
  log_error "RFC file not found: $RFC_FILE"
  exit 1
fi

# Validate status
VALID_STATUSES="Implemented Superseded Resolved Rejected"
if [ -z "$STATUS" ]; then
  echo "Select resolution status:"
  echo "  1) Implemented - RFC proposal was built"
  echo "  2) Superseded  - Replaced by another RFC or decision"
  echo "  3) Resolved    - Concluded without direct implementation (e.g., research consumed)"
  echo "  4) Rejected    - Proposal declined"
  read -rp "Choice [1-4]: " CHOICE
  case $CHOICE in
    1) STATUS="Implemented" ;;
    2) STATUS="Superseded" ;;
    3) STATUS="Resolved" ;;
    4) STATUS="Rejected" ;;
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

if [ "$STATUS" = "Superseded" ] && [ -z "$SUPERSEDED_BY" ]; then
  read -rp "Superseded by (RFC filename, or press Enter to skip): " SUPERSEDED_BY
fi

BASENAME=$(basename "$RFC_FILE")
TODAY=$(get_date_timestamp)
NOW=$(get_iso_timestamp)

# Update frontmatter using shared functions
resolve_update_frontmatter "$RFC_FILE" "Status" "$STATUS"
resolve_update_frontmatter "$RFC_FILE" "Date Updated" "$NOW"

# Build status history note
HISTORY_NOTE="${NOTES:-RFC resolved}"
if [ -n "$SUPERSEDED_BY" ]; then
  HISTORY_NOTE="$HISTORY_NOTE (superseded by $SUPERSEDED_BY)"
fi

# Append to Status History table
if grep -q "^| .* | .* | .* |$" "$RFC_FILE"; then
  awk -v new_row="| $STATUS | $TODAY | $HISTORY_NOTE |" '
    /^\| [^-]/ { last_table_line = NR; last_line = $0 }
    { lines[NR] = $0 }
    END {
      for (i = 1; i <= NR; i++) {
        print lines[i]
        if (i == last_table_line) print new_row
      }
    }
  ' "$RFC_FILE" > "${RFC_FILE}.tmp" && mv "${RFC_FILE}.tmp" "$RFC_FILE"
fi

# Move to resolved/ using shared function
resolve_move_to_resolved "$RFC_FILE" "$RESOLVED_DIR"

resolve_print_summary "RFC" "$BASENAME" "$STATUS" "$TODAY" "spectri/rfc/resolved" "${NOTES:-RFC resolved}"
if [ -n "$SUPERSEDED_BY" ]; then
  echo "  Superseded by: $SUPERSEDED_BY"
fi
