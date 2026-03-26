#!/usr/bin/env bash
set -euo pipefail

# reopen-issue.sh - Reopen a resolved issue
# Usage: reopen-issue.sh <issue-file> [--reason "why reopening"]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/logging.sh"
source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/timestamp-utils.sh"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"

ISSUE_FILE=""
REASON=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --reason)
      REASON="$2"
      shift 2
      ;;
    *)
      if [ -z "$ISSUE_FILE" ]; then
        ISSUE_FILE="$1"
        shift
      else
        log_error "Unknown argument: $1"
        echo "Usage: reopen-issue.sh <issue-file> [--reason \"why reopening\"]"
        exit 1
      fi
      ;;
  esac
done

if [ -z "$ISSUE_FILE" ]; then
  log_error "Issue file required"
  echo "Usage: reopen-issue.sh <issue-file> [--reason \"why reopening\"]"
  exit 1
fi

# Handle both absolute and relative paths
if [[ "$ISSUE_FILE" = /* ]]; then
  FULL_PATH="$ISSUE_FILE"
else
  # Try resolved/ first, then spectri/issues/
  if [ -f "$PROJECT_ROOT/spectri/issues/resolved/$ISSUE_FILE" ]; then
    FULL_PATH="$PROJECT_ROOT/spectri/issues/resolved/$ISSUE_FILE"
  elif [ -f "$PROJECT_ROOT/spectri/issues/$ISSUE_FILE" ]; then
    FULL_PATH="$PROJECT_ROOT/spectri/issues/$ISSUE_FILE"
  else
    log_error "Issue file not found: $ISSUE_FILE"
    echo "Searched in: spectri/issues/resolved/ and spectri/issues/"
    exit 1
  fi
fi

BASENAME=$(basename "$FULL_PATH")

# Interactive prompt if reason not provided
if [ -z "$REASON" ]; then
  echo "Why is this issue being reopened?"
  read -r REASON
fi

# Get today's date
REOPENED_DATE=$(get_date_timestamp)

# Update frontmatter
sed_inplace "s/^status: .*/status: reopened/" "$FULL_PATH"
sed_inplace "s/^closed: .*/closed: null/" "$FULL_PATH"

# Add reopening notes after Resolution section
REOPENING_NOTES="

## Reopening Notes

**Reopened**: $REOPENED_DATE
**Reason**: $REASON"

# Append reopening notes to the file
echo "$REOPENING_NOTES" >> "$FULL_PATH"

# Move back to spectri/issues/ if currently in resolved/
if [[ "$FULL_PATH" == */resolved/* ]]; then
  mv "$FULL_PATH" "$PROJECT_ROOT/spectri/issues/$BASENAME"
  echo "✅ Issue reopened: $BASENAME"
  echo "   Reopened: $REOPENED_DATE"
  echo "   Reason: $REASON"
  echo "   Moved to: spectri/issues/$BASENAME"
else
  echo "✅ Issue reopened: $BASENAME"
  echo "   Reopened: $REOPENED_DATE"
  echo "   Reason: $REASON"
  echo "   (File was already in spectri/issues/)"
fi

echo ""
echo "💡 Next: Update status to 'open' when ready to work on it"
