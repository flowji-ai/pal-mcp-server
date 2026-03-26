#!/usr/bin/env bash
# create-prompt.sh - Create a prompt file in the prompts directory
#
# Usage:
#   create-prompt.sh --title "Title" [--json]
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
TEMPLATE_PATH="$REPO_ROOT/.spectri/templates/spectri-trail/prompt-template.md"
PROMPTS_DIR="$REPO_ROOT/spectri/coordination/prompts"

# ============================================================================
# Utility Functions
# ============================================================================

usage() {
    cat <<EOF
Usage: create-prompt.sh --title "Title" [--json]

Options:
  --title    Title for the prompt (required)
  --json     Output result as JSON

Examples:
  create-prompt.sh --title "Implement dark mode toggle"
  create-prompt.sh --title "Review API authentication flow" --json
EOF
}

# ============================================================================
# Main Logic
# ============================================================================

main() {
    local title=""
    local json_output=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --title)
                title="$2"
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
    if ! mkdir -p "$PROMPTS_DIR"; then
        log_error "Failed to create directory: $PROMPTS_DIR"
        exit 4
    fi

    # Generate filename
    local date_prefix
    date_prefix="$(get_date_timestamp)"
    local slug
    slug="$(slugify "$title")"
    local filename="${date_prefix}-${slug}.md"
    local filepath="$PROMPTS_DIR/$filename"

    # Get timestamp
    local full_date
    full_date="$(get_iso_timestamp)"

    # Copy template and substitute placeholders
    local content
    content=$(cat "$TEMPLATE_PATH")
    content=$(echo "$content" | sed "s|{{TITLE}}|${title}|g")
    content=$(echo "$content" | sed "s|{{DATE_ISO}}|${full_date}|g")
    content=$(echo "$content" | sed "s|{{AGENT_SESSION_ID}}|${AGENT_SESSION_ID:-unknown}|g")

    if ! echo "$content" > "$filepath"; then
        log_error "Failed to write prompt file: $filepath"
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
  "relative_path": "$relative_path"
}
EOF
    else
        echo "Prompt created successfully"
        echo ""
        echo "Filename: $filename"
        echo "Path: $relative_path"
        echo ""
        echo "Next steps:"
        echo "1. Open the file and write the task description"
        echo "2. Include enough context for an agent with no prior session knowledge"
        echo "3. Commit when complete"
    fi
}

# Run main
main "$@"
