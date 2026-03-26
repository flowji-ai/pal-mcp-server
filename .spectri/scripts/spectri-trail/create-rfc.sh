#!/usr/bin/env bash
# create-rfc.sh - Create Request for Comments with date-based naming
#
# Usage:
#   create-rfc.sh --title "Proposal Title" [--type "System Architecture"] [--json]
#
# Output:
#   Creates spectri/rfc/RFC-YYYY-MM-DD-proposal-title.md from template
#   Returns JSON: {"date":"YYYY-MM-DD","path":"/abs/path/to/rfc.md"}
#
# Exit Codes:
#   0 - Success
#   1 - Missing required input (--title not provided)
#   2 - Filesystem error (can't create directory, permission denied)
#   3 - Template not found (rfc-template.md missing)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/logging.sh"
source "$SCRIPT_DIR/../../lib/timestamp-utils.sh"
source "$SCRIPT_DIR/../../lib/filename-utils.sh"
source "$SCRIPT_DIR/../../lib/common.sh"

# Default values
TITLE=""
TYPE="System Architecture"
JSON_OUTPUT=false
REPO_ROOT=""

# Error handling
error_exit() {
    local code=$1
    shift
    log_error "$*"
    exit "$code"
}

# Generate date-based RFC identifier (just the date - slug ensures uniqueness)
generate_rfc_id() {
    get_date_timestamp
}


# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --title)
            TITLE="$2"
            shift 2
            ;;
        --type)
            TYPE="$2"
            shift 2
            ;;
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        --help|-h)
            echo "Usage: create-rfc.sh --title \"Proposal Title\" [--type \"Type\"] [--json]"
            echo ""
            echo "Options:"
            echo "  --title TITLE    RFC title (required)"
            echo "  --type TYPE      RFC type: System Architecture, Process Change, Tooling Decision (default: System Architecture)"
            echo "  --json           Output JSON format"
            echo "  --help           Show this help message"
            echo ""
            echo "Exit Codes:"
            echo "  0 - Success"
            echo "  1 - Missing required input"
            echo "  2 - Filesystem error"
            echo "  3 - Template not found"
            exit 0
            ;;
        *)
            error_exit 1 "Unknown option: $1. Use --help for usage information."
            ;;
    esac
done

# Validate required arguments
if [[ -z "$TITLE" ]]; then
    error_exit 1 "Missing required argument: --title. Usage: create-rfc.sh --title \"Proposal Title\""
fi

# Validate RFC type
case "$TYPE" in
    "System Architecture"|"Process Change"|"Tooling Decision")
        # Valid type
        ;;
    *)
        error_exit 1 "Invalid RFC type: $TYPE. Must be one of: System Architecture, Process Change, Tooling Decision"
        ;;
esac

# Find repository root
REPO_ROOT=$(get_repo_root)

# Define paths
RFC_DIR="$REPO_ROOT/spectri/rfc"
TEMPLATE_PATH="$REPO_ROOT/.spectri/templates/spectri-trail/rfc-template.md"

# Verify template exists
if [[ ! -f "$TEMPLATE_PATH" ]]; then
    error_exit 3 "Template not found at $TEMPLATE_PATH. Check .spectri/templates/ directory."
fi

# Create RFC directory if it doesn't exist
if [[ ! -d "$RFC_DIR" ]]; then
    mkdir -p "$RFC_DIR" 2>/dev/null || error_exit 2 "Could not create directory $RFC_DIR. Check permissions."
fi

# Generate date-based ID (slug ensures uniqueness)
RFC_ID=$(generate_rfc_id)
SLUG=$(slugify "$TITLE")
RFC_FILENAME="RFC-${RFC_ID}-${SLUG}.md"
RFC_PATH="$RFC_DIR/$RFC_FILENAME"

# Check if file already exists (race condition protection)
if [[ -f "$RFC_PATH" ]]; then
    error_exit 2 "RFC file already exists: $RFC_PATH"
fi

# Copy template to destination
cp "$TEMPLATE_PATH" "$RFC_PATH" 2>/dev/null || error_exit 2 "Could not create RFC file at $RFC_PATH. Check permissions and disk space."

# Update template placeholders
CURRENT_DATETIME=$(get_iso_timestamp)
CURRENT_DATE=$(get_date_timestamp)

# Update frontmatter
sed_inplace "s|Date Created: {{ISO_TIMESTAMP}}|Date Created: $CURRENT_DATETIME|" "$RFC_PATH"
sed_inplace "s|Date Updated: {{ISO_TIMESTAMP}}|Date Updated: $CURRENT_DATETIME|" "$RFC_PATH"
sed_inplace "s/Type: \[System Architecture | Process Change | Tooling Decision\]/Type: $TYPE/" "$RFC_PATH"

# Update title
sed_inplace "s|# RFC-YYYY-MM-DD: \[Descriptive Title\]|# RFC-${RFC_ID}: ${TITLE}|" "$RFC_PATH"

# Update status history
sed_inplace "s/Under Discussion | YYYY-MM-DD/Under Discussion | $CURRENT_DATE/" "$RFC_PATH"

# Output result
if [[ "$JSON_OUTPUT" = true ]]; then
    # JSON output for programmatic use
    echo "{\"id\":\"$RFC_ID\",\"path\":\"$RFC_PATH\",\"slug\":\"$SLUG\",\"title\":\"$TITLE\",\"type\":\"$TYPE\"}"
else
    # Human-readable output
    log_success "RFC created successfully!"
    echo ""
    log_info "ID: RFC-$RFC_ID"
    log_info "File: $RFC_PATH"
    log_info "Title: $TITLE"
    log_info "Type: $TYPE"
    echo ""
    echo "Next steps:"
    echo "   1. Edit $RFC_PATH"
    echo "   2. Fill in Context, Problem Statement, and Proposed Directions"
    echo "   3. Update Status History when decision is made"
    echo "   4. Create ADRs when RFC transitions to 'Accepted' status"
fi

exit 0
