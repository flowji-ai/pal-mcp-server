#!/usr/bin/env bash
#
# find-callers.sh - Find files that reference given function/method names
#
# Given function or method names whose signatures changed, finds all files
# in the project that reference those names. Language-agnostic grep search.
# Read-only: searches and reports only, never modifies files.
#
# Usage:
#   find-callers.sh --names <name1,name2,...>                    # Human-readable
#   find-callers.sh --names <name1,name2> --exclude <path>      # Exclude file
#   find-callers.sh --names <name1,name2> --json                # JSON output
#   find-callers.sh --help                                      # Show this help
#
# Exit codes:
#   0 - Success (callers found or none found)
#   1 - Bad arguments

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/logging.sh"
source "$SCRIPT_DIR/../../lib/common.sh"

# --- Cleanup ---
TMPDIR_CALLERS=""
cleanup() {
    local exit_code=$?
    if [ -n "$TMPDIR_CALLERS" ] && [ -d "$TMPDIR_CALLERS" ]; then
        rm -rf "$TMPDIR_CALLERS"
    fi
    exit $exit_code
}
trap cleanup EXIT INT TERM

# --- Defaults ---
NAMES=""
EXCLUDES=""
JSON_MODE=false

# --- Parse arguments ---
while [ $# -gt 0 ]; do
    case "$1" in
        --names)
            if [ $# -lt 2 ]; then
                log_error "--names requires a value"
                exit 1
            fi
            NAMES="$2"
            shift
            ;;
        --exclude)
            if [ $# -lt 2 ]; then
                log_error "--exclude requires a value"
                exit 1
            fi
            EXCLUDES="$EXCLUDES $2"
            shift
            ;;
        --json)
            JSON_MODE=true
            ;;
        --help|-h)
            sed -n '3,16p' "$0" | sed 's/^# \?//'
            exit 0
            ;;
        *)
            log_error "Unknown argument '$1'"
            echo "Usage: $0 --names <name1,name2,...> [--exclude <path>] [--json]"
            exit 1
            ;;
    esac
    shift
done

# --- Validate ---
if [ -z "$NAMES" ]; then
    log_error "--names is required"
    echo "Usage: $0 --names <name1,name2,...> [--exclude <path>] [--json]"
    exit 1
fi

REPO_ROOT=$(get_repo_root)
TMPDIR_CALLERS=$(mktemp -d)

# Split names on commas
IFS=',' read -ra NAME_LIST <<< "$NAMES"

# Build exclude args for grep
GREP_EXCLUDES="--exclude-dir=.git --exclude-dir=node_modules --exclude-dir=__pycache__ --exclude-dir=.spectri --exclude-dir=venv --exclude-dir=.venv"

total_files=0
all_files=""

for name in "${NAME_LIST[@]}"; do
    # Trim whitespace
    name=$(echo "$name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    [ -z "$name" ] && continue

    result_file="$TMPDIR_CALLERS/$name"

    # Grep for the name across the project
    grep_output=$(grep -rn $GREP_EXCLUDES "$name" "$REPO_ROOT" 2>/dev/null || true)

    if [ -n "$grep_output" ]; then
        # Filter out excluded files and format results
        while IFS= read -r match_line; do
            file_path=$(echo "$match_line" | cut -d: -f1)
            line_num=$(echo "$match_line" | cut -d: -f2)

            # Make path relative
            rel_path="${file_path#$REPO_ROOT/}"

            # Check if this file is excluded
            skip=false
            for excl in $EXCLUDES; do
                if [ "$rel_path" = "$excl" ]; then
                    skip=true
                    break
                fi
            done
            [ "$skip" = "true" ] && continue

            # Write to result file (dedup by file:line)
            printf '%s:%s\n' "$rel_path" "$line_num" >> "$result_file"

            # Track unique files
            case " $all_files " in
                *" $rel_path "*) ;;
                *) all_files="$all_files $rel_path"; total_files=$((total_files + 1)) ;;
            esac
        done <<< "$grep_output"
    fi
done

# --- Output ---
if $JSON_MODE; then
    printf '{"callers":['

    first_name=true
    for name in "${NAME_LIST[@]}"; do
        name=$(echo "$name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        [ -z "$name" ] && continue

        if [ "$first_name" = "true" ]; then
            first_name=false
        else
            printf ','
        fi

        printf '{"name":"%s","references":[' "$name"

        result_file="$TMPDIR_CALLERS/$name"
        first_ref=true
        if [ -f "$result_file" ]; then
            # Deduplicate
            sort -u "$result_file" | while IFS= read -r entry; do
                ref_file=$(echo "$entry" | cut -d: -f1)
                ref_line=$(echo "$entry" | cut -d: -f2)
                if [ "$first_ref" = "true" ]; then
                    first_ref=false
                else
                    printf ','
                fi
                printf '{"file":"%s","line":%s}' "$ref_file" "$ref_line"
            done
        fi

        printf ']}'
    done

    printf '],"total_files":%s}\n' "$total_files"
else
    if [ "$total_files" -eq 0 ]; then
        log_info "No callers found for: $NAMES"
    else
        echo "Callers of changed signatures:"
        echo ""

        for name in "${NAME_LIST[@]}"; do
            name=$(echo "$name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            [ -z "$name" ] && continue

            result_file="$TMPDIR_CALLERS/$name"
            if [ -f "$result_file" ] && [ -s "$result_file" ]; then
                echo "  $name:"
                sort -u "$result_file" | while IFS= read -r entry; do
                    echo "    $entry"
                done
                echo ""
            fi
        done

        echo "$total_files files reference changed signatures."
    fi
fi
