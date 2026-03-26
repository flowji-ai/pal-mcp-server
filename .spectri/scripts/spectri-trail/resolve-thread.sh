#!/usr/bin/env bash
set -euo pipefail

# resolve-thread.sh - Mark a thread as completed and move to resolved/
# Usage: resolve-thread.sh <thread-file> --status <completed|superseded> [--notes "completion notes"] [--processed-by "agent name"]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/resolve-common.sh"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"

THREADS_DIR="$PROJECT_ROOT/spectri/coordination/threads"

THREAD_FILE=""
STATUS=""
NOTES=""
PROCESSED_BY=""

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
    --processed-by)
      PROCESSED_BY="$2"
      shift 2
      ;;
    *)
      if [ -z "$THREAD_FILE" ]; then
        THREAD_FILE="$1"
        shift
      else
        log_error "Unknown argument: $1"
        echo "Usage: resolve-thread.sh <thread-file> --status <completed|superseded> [--notes \"notes\"] [--processed-by \"agent\"]"
        exit 1
      fi
      ;;
  esac
done

if [ -z "$THREAD_FILE" ]; then
  log_error "Thread file required"
  echo "Usage: resolve-thread.sh <thread-file> --status <completed|superseded> [--notes \"notes\"]"
  exit 1
fi

# Resolve relative paths - search in threads directory and subdirectories
if [[ ! "$THREAD_FILE" = /* ]] && [[ ! -f "$THREAD_FILE" ]]; then
  # Try direct match in threads dir
  if [ -f "$THREADS_DIR/$THREAD_FILE" ]; then
    THREAD_FILE="$THREADS_DIR/$THREAD_FILE"
  else
    # Search subdirectories
    MATCH=$(find "$THREADS_DIR" -name "$THREAD_FILE" -type f 2>/dev/null | head -1)
    if [ -n "$MATCH" ]; then
      THREAD_FILE="$MATCH"
    else
      THREAD_FILE="$THREADS_DIR/$THREAD_FILE"
    fi
  fi
fi

if [ ! -f "$THREAD_FILE" ]; then
  log_error "Thread file not found: $THREAD_FILE"
  exit 1
fi

# Validate status
if [ -z "$STATUS" ]; then
  echo "Select resolution status:"
  echo "  1) completed  - Thread work is done"
  echo "  2) superseded - Replaced by newer thread or approach"
  read -rp "Choice [1-2]: " CHOICE
  case $CHOICE in
    1) STATUS="completed" ;;
    2) STATUS="superseded" ;;
    *) log_error "Invalid choice"; exit 1 ;;
  esac
fi

if [[ "$STATUS" != "completed" && "$STATUS" != "superseded" ]]; then
  log_error "Invalid status '$STATUS'. Valid: completed, superseded"
  exit 1
fi

# Interactive prompts for missing args
if [ -z "$NOTES" ]; then
  read -rp "Resolution notes (or press Enter to skip): " NOTES
fi

if [ -z "$PROCESSED_BY" ]; then
  read -rp "Processed by (agent session ID, or press Enter to skip): " PROCESSED_BY
fi

BASENAME=$(basename "$THREAD_FILE")
# Determine the parent directory to create resolved/ alongside the thread
THREAD_PARENT=$(dirname "$THREAD_FILE")
RESOLVED_DIR="$THREAD_PARENT/resolved"
TODAY=$(get_date_timestamp)
NOW=$(get_iso_timestamp)

# Update frontmatter
resolve_update_frontmatter "$THREAD_FILE" "status" "$STATUS"
resolve_update_frontmatter "$THREAD_FILE" "processed_date" "$NOW"
if [ -n "$PROCESSED_BY" ]; then
  resolve_update_frontmatter "$THREAD_FILE" "processed_by" "\"$PROCESSED_BY\""
fi
if [ -n "$NOTES" ]; then
  resolve_update_frontmatter "$THREAD_FILE" "response_notes" "\"$NOTES\""
fi

# Move to resolved/
resolve_move_to_resolved "$THREAD_FILE" "$RESOLVED_DIR"

RELATIVE_DEST="${RESOLVED_DIR#$PROJECT_ROOT/}"
resolve_print_summary "Thread" "$BASENAME" "$STATUS" "$TODAY" "$RELATIVE_DEST" "${NOTES:-Thread resolved}"
