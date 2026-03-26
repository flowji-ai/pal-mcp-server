#!/usr/bin/env bash
# reorder-todos.sh - Reorder and clean up spectri/TODO.md
#
# Moves checked items to Completed section and sorts active items
# into priority sections by marker (!! = Priority One, ! = Priority Two).
#
# Usage:
#   reorder-todos.sh [--dry-run]
#
# Exit codes:
#   0 - Success
#   1 - TODO.md not found
#   4 - Filesystem error

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/logging.sh"
source "$SCRIPT_DIR/../../lib/common.sh"

REPO_ROOT="$(get_repo_root)"
TODO_FILE="$REPO_ROOT/spectri/TODO.md"

# ============================================================================
# Main Logic
# ============================================================================

main() {
    local dry_run=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                dry_run=true
                shift
                ;;
            --help|-h)
                echo "Usage: reorder-todos.sh [--dry-run]"
                echo ""
                echo "Reorders spectri/TODO.md:"
                echo "  - Moves checked items ([X]) to Completed section"
                echo "  - Sorts active items by priority marker (!! > ! > unmarked)"
                echo ""
                echo "Options:"
                echo "  --dry-run  Show what would change without modifying the file"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    if [[ ! -f "$TODO_FILE" ]]; then
        log_error "TODO.md not found at: $TODO_FILE"
        exit 1
    fi

    # Parse the file into arrays
    local -a priority_one=()
    local -a priority_two=()
    local -a other_tasks=()
    local -a completed=()

    local in_section=""

    while IFS= read -r line; do
        # Skip section headers — we'll rebuild them
        if [[ "$line" =~ ^#\  ]]; then
            continue
        fi

        # Skip empty lines
        if [[ -z "${line// /}" ]]; then
            continue
        fi

        # Categorise checkbox items (regex in variables for Bash 3.2 compat)
        local re_done_upper='^- \[X\] '
        local re_done_lower='^- \[x\] '
        local re_p1='^- \[ \] !! '
        local re_p2='^- \[ \] ! '
        local re_task='^- \[ \] '
        if [[ "$line" =~ $re_done_upper ]] || [[ "$line" =~ $re_done_lower ]]; then
            completed+=("$line")
        elif [[ "$line" =~ $re_p1 ]]; then
            priority_one+=("$line")
        elif [[ "$line" =~ $re_p2 ]]; then
            priority_two+=("$line")
        elif [[ "$line" =~ $re_task ]]; then
            other_tasks+=("$line")
        fi
    done < "$TODO_FILE"

    # Build output
    local output="# TO DO

## Priority One
"
    for item in "${priority_one[@]+"${priority_one[@]}"}"; do
        output+="
$item"
    done

    output+="

## Priority Two
"
    for item in "${priority_two[@]+"${priority_two[@]}"}"; do
        output+="
$item"
    done

    output+="

## Other Tasks
"
    for item in "${other_tasks[@]+"${other_tasks[@]}"}"; do
        output+="
$item"
    done

    output+="

## Completed
"
    for item in "${completed[@]+"${completed[@]}"}"; do
        output+="
$item"
    done
    output+="
"

    if $dry_run; then
        echo "=== DRY RUN — would write: ==="
        echo "$output"
        echo ""
        echo "Priority One: ${#priority_one[@]} items"
        echo "Priority Two: ${#priority_two[@]} items"
        echo "Other Tasks: ${#other_tasks[@]} items"
        echo "Completed: ${#completed[@]} items"
    else
        if ! echo "$output" > "$TODO_FILE"; then
            log_error "Failed to write TODO.md"
            exit 4
        fi
        echo "TODO.md reordered successfully"
        echo ""
        echo "Priority One: ${#priority_one[@]} items"
        echo "Priority Two: ${#priority_two[@]} items"
        echo "Other Tasks: ${#other_tasks[@]} items"
        echo "Completed: ${#completed[@]} items"
    fi
}

# Run main
main "$@"
