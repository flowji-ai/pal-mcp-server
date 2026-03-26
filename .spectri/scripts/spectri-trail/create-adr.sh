#!/usr/bin/env bash
# create-adr.sh - Create Architecture Decision Record with sequential ID
#
# Usage:
#   create-adr.sh --title "Decision Title" [--json]
#
# Output:
#   Creates history/adr/NNNN-decision-title.md from template
#   Returns JSON: {"id":"NNNN","path":"/abs/path/to/adr.md"}
#
# Exit Codes:
#   0 - Success
#   1 - Missing required input (--title not provided)
#   2 - Filesystem error (can't create directory, permission denied)
#   3 - Template not found (adr-template.md missing)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/logging.sh"
source "$SCRIPT_DIR/../../lib/filename-utils.sh"
source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/timestamp-utils.sh"

# Escape special characters for sed replacement
escape_sed() {
    printf '%s\n' "$1" | sed -e 's/[\/&|]/\\&/g'
}

# Default values
TITLE=""
JSON_OUTPUT=false
REPO_ROOT=""

# Error handling
error_exit() {
    local code=$1
    shift
    log_error "$*"
    exit "$code"
}

# Generate next sequential ADR ID
next_id() {
    local adr_dir="$1"
    local max=0

    # Find highest existing ADR number using glob (no process substitution)
    if [[ -d "$adr_dir" ]]; then
        for file in "$adr_dir"/[0-9][0-9][0-9][0-9]-*.md; do
            [[ -e "$file" ]] || continue
            local basename="${file##*/}"
            if [[ "$basename" =~ ^([0-9]{4})- ]]; then
                local num="${BASH_REMATCH[1]}"
                # Remove leading zeros for arithmetic
                num=$((10#$num))
                if ((num > max)); then
                    max=$num
                fi
            fi
        done
    fi

    # Return next ID, zero-padded to 4 digits
    printf "%04d" $((max + 1))
}


# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --title)
            TITLE="$2"
            shift 2
            ;;
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        --help|-h)
            echo "Usage: create-adr.sh --title \"Decision Title\" [--json]"
            echo ""
            echo "Options:"
            echo "  --title TITLE    ADR title (required)"
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
    error_exit 1 "Missing required argument: --title. Usage: create-adr.sh --title \"Decision Title\""
fi

# Find repository root
REPO_ROOT=$(get_repo_root)

# Define paths
ADR_DIR="$REPO_ROOT/spectri/adr"
TEMPLATE_PATH="$REPO_ROOT/.spectri/templates/spectri-trail/adr-template.md"

# Verify template exists
if [[ ! -f "$TEMPLATE_PATH" ]]; then
    error_exit 3 "Template not found at $TEMPLATE_PATH. Run ADR system setup or check .spectri/templates/ directory."
fi

# Create ADR directory if it doesn't exist
if [[ ! -d "$ADR_DIR" ]]; then
    mkdir -p "$ADR_DIR" 2>/dev/null || error_exit 2 "Could not create directory $ADR_DIR. Check permissions."
fi

# Generate sequential ID and slug
ADR_ID=$(next_id "$ADR_DIR")
SLUG=$(slugify "$TITLE")
ADR_FILENAME="${ADR_ID}-${SLUG}.md"
ADR_PATH="$ADR_DIR/$ADR_FILENAME"

# Check if file already exists (race condition protection)
if [[ -f "$ADR_PATH" ]]; then
    error_exit 2 "ADR file already exists: $ADR_PATH"
fi

# Copy template to destination
cp "$TEMPLATE_PATH" "$ADR_PATH" 2>/dev/null || error_exit 2 "Could not create ADR file at $ADR_PATH. Check permissions and disk space."

# Replace template placeholders with actual values
CURRENT_DATE=$(get_date_timestamp)
SAFE_TITLE=$(escape_sed "$TITLE")

sed_inplace "s|{{NNNN}}|${ADR_ID}|g" "$ADR_PATH"
sed_inplace "s|{Decision Cluster Title}|${SAFE_TITLE}|g" "$ADR_PATH"
sed_inplace "s|{{YYYY-MM-DD}}|${CURRENT_DATE}|g" "$ADR_PATH"
sed_inplace "s|{Cluster Title}|${SAFE_TITLE}|g" "$ADR_PATH"

# Output result
if [[ "$JSON_OUTPUT" = true ]]; then
    # JSON output for programmatic use
    echo "{\"id\":\"$ADR_ID\",\"path\":\"$ADR_PATH\",\"slug\":\"$SLUG\",\"title\":\"$TITLE\"}"
else
    # Human-readable output
    echo "✅ ADR created successfully!"
    echo ""
    echo "   ID: ADR-$ADR_ID"
    echo "   File: $ADR_PATH"
    echo "   Title: $TITLE"
    echo ""
    echo "Next steps:"
    echo "   1. Edit $ADR_PATH"
    echo "   2. Replace placeholders with actual content"
    echo "   3. Update status from 'Proposed' to 'Accepted' after implementation"
fi

exit 0
