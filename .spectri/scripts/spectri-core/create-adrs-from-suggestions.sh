#!/usr/bin/env bash
# create-adrs-from-suggestions.sh - Batch create ADRs from suggestions JSON
#
# Usage:
#   create-adrs-from-suggestions.sh --suggestions suggestions.json [--json]
#
# Input:
#   JSON array of ADR suggestions from suggest-adrs.sh
#   [
#     {
#       "title": "Backend Technology Stack",
#       "decisions": ["Use FastAPI", "Use Python 3.11"],
#       "cluster_type": "technology_stack",
#       "significance": { ... }
#     }
#   ]
#
# Output:
#   Creates multiple ADR files in history/adr/
#   Returns JSON array of created ADRs:
#   [
#     {"id": "0001", "path": "/path/to/adr.md", "title": "..."},
#     {"id": "0002", "path": "/path/to/adr.md", "title": "..."}
#   ]
#
# Exit Codes:
#   0 - Success
#   1 - Missing required input
#   2 - Invalid JSON input or file error
#   3 - ADR creation failed

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/logging.sh"
source "$SCRIPT_DIR/../../lib/common.sh"

# Default values
SUGGESTIONS_FILE=""
JSON_OUTPUT=true
REPO_ROOT=""

# Error handling
error_exit() {
    local code=$1
    shift
    log_error "$*"
    exit "$code"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --suggestions)
            SUGGESTIONS_FILE="$2"
            shift 2
            ;;
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        --help|-h)
            echo "Usage: create-adrs-from-suggestions.sh --suggestions suggestions.json [--json]"
            echo ""
            echo "Options:"
            echo "  --suggestions FILE Path to suggestions JSON file (required)"
            echo "  --json             Output JSON format (default: true)"
            echo "  --help             Show this help message"
            exit 0
            ;;
        *)
            error_exit 1 "Unknown option: $1"
            ;;
    esac
done

# Validate required arguments
if [[ -z "$SUGGESTIONS_FILE" ]]; then
    error_exit 1 "Missing required argument: --suggestions"
fi

# Read suggestions file
if [[ ! -f "$SUGGESTIONS_FILE" ]]; then
    error_exit 2 "Suggestions file not found: $SUGGESTIONS_FILE"
fi

SUGGESTIONS_JSON=$(cat "$SUGGESTIONS_FILE")

# Verify JSON is valid
if ! echo "$SUGGESTIONS_JSON" | jq empty 2>/dev/null; then
    error_exit 2 "Invalid JSON in suggestions file: $SUGGESTIONS_FILE"
fi

# Find repository root
REPO_ROOT=$(get_repo_root)
CREATE_ADR_SCRIPT="$REPO_ROOT/.spectri/scripts/spectri-trail/create-adr.sh"

# Verify create-adr.sh exists
if [[ ! -x "$CREATE_ADR_SCRIPT" ]]; then
    error_exit 3 "create-adr.sh not found or not executable at $CREATE_ADR_SCRIPT"
fi

# Create ADRs from suggestions
CREATED_ADRS='[]'
SUGGESTION_COUNT=$(echo "$SUGGESTIONS_JSON" | jq 'length')

for ((i=0; i<SUGGESTION_COUNT; i++)); do
    SUGGESTION=$(echo "$SUGGESTIONS_JSON" | jq -r ".[$i]")
    TITLE=$(echo "$SUGGESTION" | jq -r '.title')

    # Create ADR using create-adr.sh
    ADR_RESULT=$("$CREATE_ADR_SCRIPT" --title "$TITLE" --json 2>&1) || {
        error_exit 3 "Failed to create ADR for: $TITLE. Error: $ADR_RESULT"
    }

    # Add to created ADRs array
    CREATED_ADRS=$(echo "$CREATED_ADRS" | jq --argjson adr "$ADR_RESULT" '. + [$adr]')
done

# Output result
if [[ "$JSON_OUTPUT" = true ]]; then
    echo "$CREATED_ADRS"
else
    echo "✅ Created $SUGGESTION_COUNT ADRs successfully!"
    echo ""
    echo "$CREATED_ADRS" | jq -r '.[] | "   ADR-\(.id): \(.title)"'
fi

exit 0
