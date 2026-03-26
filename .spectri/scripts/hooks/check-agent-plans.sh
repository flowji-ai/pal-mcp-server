#!/usr/bin/env bash
#
# check-agent-plans.sh - Pre-commit hook for AGENTS.md enforcement
#
# Spec: 038-agents-md-enforcement
# Purpose: Detect agent documentation changes, block excessive growth, warn on size thresholds
#
# Usage:
#   .spectri/scripts/hooks/check-agent-plans.sh [--staged]
#
# Options:
#   --staged    Check staged files (default for pre-commit hook)
#   --help      Show this help message
#
# Configuration:
#   .spectri/config/agent-files.txt    - File patterns to detect
#   Environment variables:
#     AGENT_DOCS_GROWTH_THRESHOLD      - Lines growth that blocks commit (default: 30)
#     AGENT_DOCS_SIZE_THRESHOLD        - Lines that trigger warning (default: 200)
#     AGENT_DOCS_DIFF_PREVIEW_LINES    - Lines to show in diff preview (default: 10)
#
# Exit codes:
#   0 - Success (commit can proceed)
#   1 - Blocked (AGENTS.md grew too much)
#
# Implements:
#   FR-001 to FR-016 from spec.md

set -euo pipefail

# ==============================================================================
# Configuration
# ==============================================================================

# Script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"
REPO_ROOT=$(get_repo_root)

# Configuration file path
CONFIG_FILE="${REPO_ROOT}/.spectri/config/agent-files.txt"

# Default thresholds (can be overridden by environment variables)
GROWTH_THRESHOLD="${AGENT_DOCS_GROWTH_THRESHOLD:-30}"
SIZE_THRESHOLD="${AGENT_DOCS_SIZE_THRESHOLD:-200}"
DIFF_PREVIEW_LINES="${AGENT_DOCS_DIFF_PREVIEW_LINES:-10}"

# Performance tracking (FR-012)
SHOW_TIMING="${AGENT_DOCS_SHOW_TIMING:-false}"
START_TIME=""

# ==============================================================================
# Output Formatting
# ==============================================================================

# Colors and log functions from shared library
source "$SCRIPT_DIR/../../lib/logging.sh"

# Output symbols
SYMBOL_ERROR="❌"
SYMBOL_WARNING="⚠️ "
SYMBOL_SUCCESS="✅"
SYMBOL_INFO="ℹ️ "

# ==============================================================================
# Helper Functions
# ==============================================================================

# Print colored output
print_error() {
    printf "${RED}${SYMBOL_ERROR} %s${NC}\n" "$1" >&2
}

print_warning() {
    printf "${YELLOW}${SYMBOL_WARNING} %s${NC}\n" "$1"
}

print_success() {
    printf "${GREEN}${SYMBOL_SUCCESS} %s${NC}\n" "$1"
}

print_info() {
    printf "${BLUE}${SYMBOL_INFO} %s${NC}\n" "$1"
}

# Show help message
show_help() {
    sed -n '2,/^$/p' "$0" | sed 's/^#//' | sed 's/^ //'
}

# Start timing for performance tracking (FR-012)
start_timer() {
    if command -v date >/dev/null 2>&1; then
        START_TIME=$(date +%s%3N 2>/dev/null || date +%s)
    fi
}

# Show elapsed time if enabled
show_elapsed_time() {
    if [[ "$SHOW_TIMING" == "true" ]] && [[ -n "$START_TIME" ]]; then
        local end_time
        local elapsed
        end_time=$(date +%s%3N 2>/dev/null || date +%s)
        elapsed=$((end_time - START_TIME))
        printf "${BLUE}Hook execution time: %dms${NC}\n" "$elapsed"
    fi
}

# Validate git repository state
validate_git_state() {
    # Check if we're in a git repository
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        print_error "Not in a git repository"
        return 1
    fi

    # Check if there are staged changes (needed for pre-commit hook)
    if ! git diff --cached --quiet 2>/dev/null; then
        return 0  # Has staged changes, OK
    fi

    # No staged changes is fine - hook will run silently
    return 0
}

# ==============================================================================
# Pattern Detection (FR-010, FR-013)
# ==============================================================================

# Load agent file patterns from config
# Returns: newline-separated list of patterns
load_patterns() {
    local config_file="$1"

    if [[ ! -f "$config_file" ]]; then
        # Default patterns if config file missing
        echo "AGENTS.md"
        echo "CLAUDE.md"
        echo "QWEN.md"
        echo "GEMINI.md"
        return 0
    fi

    # Read patterns, skip comments and empty lines
    grep -v '^#' "$config_file" 2>/dev/null | grep -v '^[[:space:]]*$' || true
}

# Check if a file matches agent doc patterns
# Args: $1 = filename, $2 = patterns (newline-separated)
# Returns: 0 if matches, 1 if not
is_agent_doc() {
    local file="$1"
    local patterns="$2"
    local basename
    basename=$(basename "$file")

    while IFS= read -r pattern; do
        [[ -z "$pattern" ]] && continue

        # Check if basename matches pattern (supports wildcards)
        if [[ "$basename" == $pattern ]]; then
            return 0
        fi
    done <<< "$patterns"

    return 1
}

# ==============================================================================
# Git Operations (FR-001 to FR-003)
# ==============================================================================

# Get list of modified/added files in staging area
# Returns: newline-separated list of files
get_staged_files() {
    git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true
}

# Get list of newly created files (not in HEAD)
# Returns: newline-separated list of files
get_new_files() {
    git diff --cached --name-only --diff-filter=A 2>/dev/null || true
}

# Get line count of a file in HEAD
# Args: $1 = filename
# Returns: line count or 0 if file doesn't exist
get_head_line_count() {
    local file="$1"
    git show "HEAD:$file" 2>/dev/null | wc -l | tr -d ' ' || echo "0"
}

# Get line count of staged version of file
# Args: $1 = filename
# Returns: line count
get_staged_line_count() {
    local file="$1"
    git show ":$file" 2>/dev/null | wc -l | tr -d ' ' || wc -l < "$file" | tr -d ' '
}

# Get current working directory line count
# Args: $1 = filename
# Returns: line count
get_current_line_count() {
    local file="$1"
    if [[ -f "$file" ]]; then
        wc -l < "$file" | tr -d ' '
    else
        echo "0"
    fi
}

# Get diff preview for a file (additions only)
# Args: $1 = filename, $2 = max lines to show
# Returns: diff preview text
get_diff_preview() {
    local file="$1"
    local max_lines="$2"
    local additions
    local total_additions

    # Get added lines from diff
    additions=$(git diff --cached "$file" 2>/dev/null | grep '^+' | grep -v '^+++' | head -n "$max_lines" || true)
    total_additions=$(git diff --cached "$file" 2>/dev/null | grep '^+' | grep -vc '^+++' || echo "0")

    if [[ -n "$additions" ]]; then
        echo "$additions"
        if [[ "$total_additions" -gt "$max_lines" ]]; then
            local remaining=$((total_additions - max_lines))
            echo "...and $remaining more lines"
        fi
    fi
}

# ==============================================================================
# Validation Logic (FR-004 to FR-009)
# ==============================================================================

# Main validation function
# Returns: 0 if commit can proceed, 1 if blocked
validate_agent_docs() {
    local patterns
    local staged_files
    local new_files
    local modified_agent_docs=()
    local new_agent_docs=()
    local blocked=0
    local has_output=0

    # Load patterns
    patterns=$(load_patterns "$CONFIG_FILE")

    # Get staged files
    staged_files=$(get_staged_files)
    new_files=$(get_new_files)

    # Categorize agent docs
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue

        if is_agent_doc "$file" "$patterns"; then
            # Check if it's a new file
            if echo "$new_files" | grep -qF "$file"; then
                new_agent_docs+=("$file")
            else
                modified_agent_docs+=("$file")
            fi
        fi
    done <<< "$staged_files"

    # Exit silently if no agent docs modified (FR-011)
    if [[ ${#modified_agent_docs[@]} -eq 0 ]] && [[ ${#new_agent_docs[@]} -eq 0 ]]; then
        return 0
    fi

    # FR-003: Notify about new agent docs
    if [[ ${#new_agent_docs[@]} -gt 0 ]]; then
        for file in "${new_agent_docs[@]}"; do
            print_warning "New agent doc created: $file"
            has_output=1
        done
    fi

    # FR-001, FR-002, FR-004: Notify about modified agent docs
    if [[ ${#modified_agent_docs[@]} -gt 0 ]]; then
        local files_list
        files_list=$(printf '%s, ' "${modified_agent_docs[@]}" | sed 's/, $//')
        print_warning "Agent docs modified: $files_list"
        has_output=1
    fi

    # Process each modified agent doc for line count checks
    if [[ ${#modified_agent_docs[@]} -gt 0 ]]; then
        for file in "${modified_agent_docs[@]}"; do
            local prev_lines
            local curr_lines
            local delta

            prev_lines=$(get_head_line_count "$file")
            curr_lines=$(get_staged_line_count "$file")
            delta=$((curr_lines - prev_lines))

            # FR-009: File shrinking - always allow
            if [[ $delta -lt 0 ]]; then
                print_success "$file: ${delta} lines (${prev_lines}→${curr_lines})"
                continue
            fi

            # FR-005, FR-006, FR-007: Check for 30+ line growth
            if [[ $delta -ge $GROWTH_THRESHOLD ]]; then
                print_error "$file grew by ${delta} lines (${prev_lines}→${curr_lines}) - threshold: ${GROWTH_THRESHOLD} lines"

                # Show diff preview (FR-006)
                local preview
                preview=$(get_diff_preview "$file" "$DIFF_PREVIEW_LINES")
                if [[ -n "$preview" ]]; then
                    echo ""
                    echo "Added lines preview:"
                    echo "$preview"
                    echo ""
                fi

                echo "Run \`git diff --cached $file\` to see full changes"
                blocked=1
                continue
            fi

            # FR-007: Info message for <30 line growth
            if [[ $delta -gt 0 ]]; then
                print_info "$file: +${delta} lines (${prev_lines}→${curr_lines})"
            fi

            # FR-008: Warn if over 200 lines (non-blocking)
            if [[ $curr_lines -gt $SIZE_THRESHOLD ]]; then
                print_warning "$file: ${curr_lines} lines (target: ${SIZE_THRESHOLD})"
            fi
        done
    fi

    # Process new agent docs for size warnings only
    if [[ ${#new_agent_docs[@]} -gt 0 ]]; then
        for file in "${new_agent_docs[@]}"; do
            local curr_lines
            curr_lines=$(get_staged_line_count "$file")

            # FR-008: Warn if new file is over threshold
            if [[ $curr_lines -gt $SIZE_THRESHOLD ]]; then
                print_warning "$file: ${curr_lines} lines (target: ${SIZE_THRESHOLD})"
            fi
        done
    fi

    return $blocked
}

# ==============================================================================
# Main Entry Point
# ==============================================================================

main() {
    local exit_code=0

    # Start performance timer
    start_timer

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                show_help
                exit 0
                ;;
            --staged)
                # Default behavior, no action needed
                shift
                ;;
            --timing)
                SHOW_TIMING="true"
                shift
                ;;
            *)
                echo "Unknown option: $1" >&2
                exit 1
                ;;
        esac
    done

    # Validate git state
    if ! validate_git_state; then
        exit 1
    fi

    # Run validation
    validate_agent_docs
    exit_code=$?

    # Show timing if enabled
    show_elapsed_time

    return $exit_code
}

# Run main if not being sourced (allows testing)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
