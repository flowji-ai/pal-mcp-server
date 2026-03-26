#!/bin/bash

# validate-meta-json.sh
# Validates that meta.json accurately reflects the filesystem state
#
# Usage:
#   ./validate-meta-json.sh <spec-path>       # Validate single spec
#   ./validate-meta-json.sh --all             # Validate all specs
#   ./validate-meta-json.sh --fix <spec-path> # Fix discrepancies (update meta.json)
#
# Exit codes:
#   0 = All valid
#   1 = Discrepancies found
#   2 = Invalid arguments
#   3 = System error
#
# Dependencies: jq

set -euo pipefail

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SPECS_DIR="$PROJECT_ROOT/spectri/specs"
META_FILENAME="meta.json"

# Core documents to track (excluding implementation-summaries which are handled separately)
CORE_DOCS=("spec.md" "plan.md" "tasks.md" "research.md" "quickstart.md" "migration-plan.md" "workflow.md" "architecture.md")

# Source shared libraries
source "$SCRIPT_DIR/../../lib/logging.sh"
source "$SCRIPT_DIR/../../lib/timestamp-utils.sh"

# Counters
TOTAL_SPECS=0
VALID_SPECS=0
INVALID_SPECS=0
TOTAL_DISCREPANCIES=0

# --- Functions ---

print_usage() {
    echo "Usage: $0 <spec-path> | --all [--fix]"
    echo ""
    echo "Arguments:"
    echo "  <spec-path>     Path to a spec folder (e.g., spectri/specs/040-workflow-documentation)"
    echo "  --all           Validate all specs in spectri/specs/ directory"
    echo "  --fix           Auto-fix discrepancies by updating meta.json"
    echo "  --quiet, -q     Only output errors (for CI/scripts)"
    echo "  --help, -h      Show this help message"
    echo ""
    echo "Exit codes:"
    echo "  0 = All valid"
    echo "  1 = Discrepancies found"
    echo "  2 = Invalid arguments"
    echo "  3 = System error"
}

check_jq() {
    if ! command -v jq &> /dev/null; then
        log_error "jq is required but not installed."
        exit 3
    fi
}

# Validate a single spec's meta.json against filesystem
validate_spec() {
    local spec_path="$1"
    local fix_mode="${2:-false}"
    local spec_name=$(basename "$spec_path")
    local meta_file="$spec_path/$META_FILENAME"
    local has_errors=false
    local discrepancies=()

    # Check meta.json exists
    if [[ ! -f "$meta_file" ]]; then
        log_error "[$spec_name] meta.json not found"
        return 1
    fi

    # Validate JSON
    if ! jq empty "$meta_file" 2>/dev/null; then
        log_error "[$spec_name] meta.json is invalid JSON"
        return 1
    fi

    # Check each core document
    for doc in "${CORE_DOCS[@]}"; do
        local file_exists=false
        local meta_tracked=false
        local meta_created="null"

        # Check filesystem
        if [[ -f "$spec_path/$doc" ]]; then
            file_exists=true
        fi

        # Check meta.json
        meta_created=$(jq -r ".documents[\"$doc\"].created // \"null\"" "$meta_file")
        if [[ "$meta_created" != "null" ]]; then
            meta_tracked=true
        fi

        # Compare
        if [[ "$file_exists" == "true" && "$meta_tracked" == "false" ]]; then
            discrepancies+=("[$spec_name] $doc EXISTS but meta.json shows created: null")
            has_errors=true
            TOTAL_DISCREPANCIES=$(( TOTAL_DISCREPANCIES + 1 ))

            if [[ "$fix_mode" == "true" ]]; then
                # Auto-fix: update meta.json with current timestamp
                local timestamp=$(get_iso_timestamp)
                local temp_file=$(mktemp)
                jq ".documents[\"$doc\"].created = \"$timestamp\" | .documents[\"$doc\"].status = \"complete\"" "$meta_file" > "$temp_file"
                mv "$temp_file" "$meta_file"
                log_info "  -> Fixed: Set $doc created=$timestamp, status=complete"
            fi
        elif [[ "$file_exists" == "false" && "$meta_tracked" == "true" ]]; then
            discrepancies+=("[$spec_name] $doc MISSING but meta.json claims created: $meta_created")
            has_errors=true
            TOTAL_DISCREPANCIES=$(( TOTAL_DISCREPANCIES + 1 ))
        fi
    done

    # Check for untracked files (files that exist but aren't in CORE_DOCS and not in meta.json)
    for file in "$spec_path"/*.md; do
        [[ -f "$file" ]] || continue
        local filename=$(basename "$file")

        # Skip if it's a known core doc
        local is_core=false
        for doc in "${CORE_DOCS[@]}"; do
            if [[ "$filename" == "$doc" ]]; then
                is_core=true
                break
            fi
        done
        [[ "$is_core" == "true" ]] && continue

        # Check if tracked in meta.json
        local meta_entry=$(jq -r ".documents[\"$filename\"] // \"null\"" "$meta_file")
        if [[ "$meta_entry" == "null" ]]; then
            discrepancies+=("[$spec_name] $filename EXISTS but not tracked in meta.json")
            has_errors=true
            TOTAL_DISCREPANCIES=$(( TOTAL_DISCREPANCIES + 1 ))
        fi
    done

    # Output results
    if [[ "$has_errors" == "true" ]]; then
        for d in "${discrepancies[@]}"; do
            log_warn "$d"
        done
        return 1
    else
        log_success "[$spec_name] meta.json matches filesystem"
        return 0
    fi
}

# Find all spec directories (excluding deployed, archived, _registry)
find_all_specs() {
    local dirs=()

    # Stage-based specs (01-drafting through 05-archived)
    for stage_dir in "$SPECS_DIR"/0[0-5]-*/; do
        if [[ -d "$stage_dir" ]]; then
            for dir in "$stage_dir"[0-9][0-9][0-9]-*/; do
                [[ -d "$dir" ]] && dirs+=("$dir")
            done
        fi
    done

    # Legacy compatibility: Check old flat structure
    for dir in "$SPECS_DIR"/[0-9][0-9][0-9]-*/; do
        [[ -d "$dir" ]] && dirs+=("$dir")
    done

    printf '%s\n' "${dirs[@]}"
}

# --- Main ---

check_jq

# Parse arguments
FIX_MODE=false
QUIET=false
ALL_MODE=false
SPEC_PATH=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --all)
            ALL_MODE=true
            shift
            ;;
        --fix)
            FIX_MODE=true
            shift
            ;;
        --quiet|-q)
            QUIET=true
            shift
            ;;
        --help|-h)
            print_usage
            exit 0
            ;;
        *)
            if [[ -z "$SPEC_PATH" ]]; then
                SPEC_PATH="$1"
            else
                log_error "Unknown argument: $1"
                print_usage
                exit 2
            fi
            shift
            ;;
    esac
done

# Validate arguments
if [[ "$ALL_MODE" == "false" && -z "$SPEC_PATH" ]]; then
    log_error "Must provide spec path or --all"
    print_usage
    exit 2
fi

# Run validation
if [[ "$ALL_MODE" == "true" ]]; then
    log_info "Validating all specs..."
    log_info ""

    while IFS= read -r spec_dir; do
        [[ -z "$spec_dir" ]] && continue
        spec_dir="${spec_dir%/}"  # Remove trailing slash
        TOTAL_SPECS=$(( TOTAL_SPECS + 1 ))

        if validate_spec "$spec_dir" "$FIX_MODE"; then
            VALID_SPECS=$(( VALID_SPECS + 1 ))
        else
            INVALID_SPECS=$(( INVALID_SPECS + 1 ))
        fi
    done < <(find_all_specs)

    log_info ""
    log_info "=== Summary ==="
    log_info "Total specs:       $TOTAL_SPECS"
    log_info "Valid:             $VALID_SPECS"
    log_info "With discrepancies: $INVALID_SPECS"
    log_info "Total discrepancies: $TOTAL_DISCREPANCIES"

    if [[ $INVALID_SPECS -gt 0 ]]; then
        exit 1
    fi
else
    # Resolve path
    if [[ ! "$SPEC_PATH" = /* ]]; then
        # Relative path - try to resolve
        if [[ -d "$PROJECT_ROOT/$SPEC_PATH" ]]; then
            SPEC_PATH="$PROJECT_ROOT/$SPEC_PATH"
        elif [[ -d "$SPECS_DIR/$SPEC_PATH" ]]; then
            SPEC_PATH="$SPECS_DIR/$SPEC_PATH"
        fi
    fi

    if [[ ! -d "$SPEC_PATH" ]]; then
        log_error "Spec directory not found: $SPEC_PATH"
        exit 2
    fi

    if validate_spec "$SPEC_PATH" "$FIX_MODE"; then
        exit 0
    else
        exit 1
    fi
fi
