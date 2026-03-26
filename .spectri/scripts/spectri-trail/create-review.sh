#!/usr/bin/env bash
# create-review.sh - Create a review file in the reviews directory
#
# Usage:
#   create-review.sh --title "Title" [--type <type>] [--source <path>] [--json]
#
# Exit codes:
#   0 - Success
#   1 - Invalid arguments
#   3 - Template missing
#   4 - Filesystem error

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/logging.sh"
source "$SCRIPT_DIR/../../lib/timestamp-utils.sh"
source "$SCRIPT_DIR/../../lib/filename-utils.sh"
source "$SCRIPT_DIR/../../lib/common.sh"

REPO_ROOT="$(get_repo_root)"
TEMPLATE_PATH="$REPO_ROOT/.spectri/templates/spectri-trail/review-template.md"
REVIEWS_DIR="$REPO_ROOT/spectri/coordination/reviews"

VALID_TYPES=(
    "architecture"
    "code-quality"
    "spec"
    "system-enhancement"
    "onboarding"
    "historical-analysis"
    "marketing"
    "pre-implementation-gate"
    "comparative-analysis"
)

# ============================================================================
# Utility Functions
# ============================================================================

usage() {
    cat <<EOF
Usage: create-review.sh --title "Title" [--type <type>] [--source <path>] [--json]

Options:
  --title    Title for the review (required)
  --type     Review type (default: architecture). Valid types:
             architecture, code-quality, spec, system-enhancement,
             onboarding, historical-analysis, marketing,
             pre-implementation-gate, comparative-analysis
  --source   Source being reviewed (path or description)
  --json     Output result as JSON

Examples:
  create-review.sh --title "Auth module architecture" --type architecture
  create-review.sh --title "Spec 042 readiness" --type pre-implementation-gate --source "spectri/specs/02-implementing/042-auth/"
EOF
}

# ============================================================================
# Main Logic
# ============================================================================

main() {
    local title=""
    local review_type="architecture"
    local source_path=""
    local json_output=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --title)
                title="$2"
                shift 2
                ;;
            --type)
                review_type="$2"
                shift 2
                ;;
            --source)
                source_path="$2"
                shift 2
                ;;
            --json)
                json_output=true
                shift
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    # Validate required arguments
    if [[ -z "$title" ]]; then
        log_error "Missing required argument: --title"
        usage
        exit 1
    fi

    # Check template exists
    if [[ ! -f "$TEMPLATE_PATH" ]]; then
        log_error "Template not found: $TEMPLATE_PATH"
        exit 3
    fi

    # Create target directory if needed
    if ! mkdir -p "$REVIEWS_DIR"; then
        log_error "Failed to create directory: $REVIEWS_DIR"
        exit 4
    fi

    # Generate filename
    local date_prefix
    date_prefix="$(get_date_timestamp)"
    local slug
    slug="$(slugify "$title")"
    local filename="${date_prefix}-${slug}-review.md"
    local filepath="$REVIEWS_DIR/$filename"

    # Get timestamp
    local full_date
    full_date="$(get_iso_timestamp)"

    # Copy template and substitute placeholders
    local content
    content=$(cat "$TEMPLATE_PATH")
    content=$(echo "$content" | sed "s|{{TITLE}}|${title}|g")
    content=$(echo "$content" | sed "s|{{DATE}}|${full_date}|g")
    content=$(echo "$content" | sed "s|{{SOURCE}}|${source_path:-unspecified}|g")
    # Replace generic Type with the specified review type
    content=$(echo "$content" | sed "s|^Type: review|Type: ${review_type}|")

    if ! echo "$content" > "$filepath"; then
        log_error "Failed to write review file: $filepath"
        exit 4
    fi

    # Stage the file
    if has_git; then
        git add "$filepath" 2>/dev/null || true
    fi

    # Output result
    local relative_path="${filepath#$REPO_ROOT/}"

    if $json_output; then
        cat <<EOF
{
  "filename": "$filename",
  "path": "$filepath",
  "relative_path": "$relative_path",
  "type": "$review_type"
}
EOF
    else
        echo "Review created successfully"
        echo ""
        echo "Filename: $filename"
        echo "Path: $relative_path"
        echo "Type: $review_type"
        echo ""
        echo "Next steps:"
        echo "1. Fill in Summary, Findings, and Recommendations"
        echo "2. Use the body structure for your review type (see spectri/coordination/reviews/SPECTRI.md)"
        echo "3. Commit when complete"
    fi
}

# Run main
main "$@"
