#!/usr/bin/env bash
# create-brainstorm.sh - Create a brainstorm folder with BRAINSTORM.md
#
# Each brainstorm lives in its own folder:
#   spectri/coordination/brainstorms/<topic>/BRAINSTORM.md
#
# Usage:
#   create-brainstorm.sh --topic "topic-slug" --title "Title" [--json]
#
# Exit codes:
#   0 - Success
#   1 - Invalid arguments
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
BRAINSTORMS_DIR="$REPO_ROOT/spectri/coordination/brainstorms"

# ============================================================================
# Utility Functions
# ============================================================================

usage() {
    cat <<EOF
Usage: create-brainstorm.sh --topic "topic-slug" --title "Title" [--json]

Options:
  --topic    Kebab-case topic slug for the folder name (required)
  --title    Human-readable title (required)
  --json     Output result as JSON

Examples:
  create-brainstorm.sh --topic "auth-redesign" --title "Authentication Redesign"
  create-brainstorm.sh --topic "cli-ux-improvements" --title "CLI UX Improvements" --json
EOF
}

# ============================================================================
# Main Logic
# ============================================================================

main() {
    local topic=""
    local title=""
    local json_output=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --topic)
                topic="$2"
                shift 2
                ;;
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
    if [[ -z "$topic" ]]; then
        log_error "Missing required argument: --topic"
        usage
        exit 1
    fi

    if [[ -z "$title" ]]; then
        log_error "Missing required argument: --title"
        usage
        exit 1
    fi

    # Create brainstorm folder
    local target_dir="$BRAINSTORMS_DIR/$topic"

    if [[ -d "$target_dir" ]]; then
        log_error "Brainstorm folder already exists: $target_dir"
        exit 4
    fi

    if ! mkdir -p "$target_dir"; then
        log_error "Failed to create directory: $target_dir"
        exit 4
    fi

    # Get timestamp
    local full_date
    full_date="$(get_iso_timestamp)"

    # Write BRAINSTORM.md
    local filepath="$target_dir/BRAINSTORM.md"
    cat > "$filepath" <<TEMPLATE
---
topic: "$title"
status: active
metadata:
  date_created: "$full_date"
  date_updated: "$full_date"
  created_by: "${USER:-unknown}"
---

# Brainstorm: $title

## Context

[What situation or problem prompted this exploration]

## Questions

[Specific questions to investigate]

## Approaches

### Approach 1: [Name]

[Description, trade-offs, pros/cons]

### Approach 2: [Name]

[Description, trade-offs, pros/cons]

## Recommendation

[Which approach and why — or "undecided, needs more exploration"]

## Decision

[Final decision when brainstorm concludes — update status to resolved]
TEMPLATE

    if [[ $? -ne 0 ]]; then
        log_error "Failed to write BRAINSTORM.md: $filepath"
        exit 4
    fi

    # Stage the file
    if has_git; then
        git add "$filepath" 2>/dev/null || true
    fi

    # Output result
    local relative_path="${filepath#$REPO_ROOT/}"
    local relative_dir="${target_dir#$REPO_ROOT/}"

    if $json_output; then
        cat <<EOF
{
  "topic": "$topic",
  "title": "$title",
  "path": "$filepath",
  "relative_path": "$relative_path",
  "folder": "$relative_dir"
}
EOF
    else
        echo "Brainstorm created successfully"
        echo ""
        echo "Topic: $topic"
        echo "Folder: $relative_dir"
        echo "File: $relative_path"
        echo ""
        echo "Next steps:"
        echo "1. Fill in Context and Questions"
        echo "2. Explore approaches — add supporting files alongside BRAINSTORM.md as needed"
        echo "3. Record recommendation and final decision"
        echo "4. Update status to 'resolved' when complete"
    fi
}

# Run main
main "$@"
