#!/usr/bin/env bash
# update-issue.sh
# Update an existing issue's fields through the command system
#
# Usage:
#   ./update-issue.sh [ISSUE_FILE]
#   ./update-issue.sh --slug SLUG
#
# Parameters:
#   ISSUE_FILE          Path to issue file (optional - will prompt if not provided)
#   --slug SLUG         Issue slug to update (optional - will prompt if not provided)
#
# Updates allowed: priority, summary, blocked, blocker_info, related_specs, related_tests, related_files
# Protected fields: status, created_by_agent, created_by_user, opened, closed
#
# Dependencies: .spectri/lib/common.sh, yq
# Task Reference: FR-020 to FR-026 (spec 020)

set -euo pipefail

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"
REPO_ROOT=$(get_repo_root)

ISSUES_DIR="$REPO_ROOT/spectri/issues"

# Source shared libraries
source "$SCRIPT_DIR/../../lib/validation.sh"
source "$REPO_ROOT/.spectri/lib/logging.sh"
source "$REPO_ROOT/.spectri/lib/timestamp-utils.sh"

# --- Functions ---

print_usage() {
    echo "Usage: $0 [ISSUE_FILE]"
    echo "       $0 --slug SLUG"
    echo ""
    echo "Updates existing issue fields through the command system."
    echo ""
    echo "If no issue file is provided, you'll be prompted to select from open issues."
    echo ""
    echo "Updatable fields:"
    echo "  - priority (critical/high/medium/low)"
    echo "  - summary (issue description)"
    echo "  - blocked (true/false)"
    echo "  - blocker_info (description of blockers)"
    echo "  - related_specs (comma-separated spec numbers)"
    echo "  - related_tests (comma-separated test paths)"
    echo "  - related_files (comma-separated file paths)"
    echo ""
    echo "Protected fields (use lifecycle scripts instead):"
    echo "  - status (use resolve-issue.sh, reopen-issue.sh)"
    echo "  - created_by_agent, created_by_user (historical)"
    echo "  - opened, closed (historical)"
}

list_open_issues() {
    echo ""
    echo "Open issues:"
    echo "---"
    local count=0
    for issue in "$ISSUES_DIR"/*.md; do
        if [[ -f "$issue" ]]; then
            local basename=$(basename "$issue")
            local status=$(grep "^status:" "$issue" | head -1 | sed 's/status: *//' || echo "unknown")
            if [[ "$status" != "resolved" ]]; then
                count=$((count + 1))
                echo "$count) $basename (status: $status)"
            fi
        fi
    done
    echo "---"

    if [[ $count -eq 0 ]]; then
        log_error "No open issues found in $ISSUES_DIR"
        exit 1
    fi

    echo ""
    echo "Select issue number (1-$count) or 'q' to quit:"
    read -r selection

    if [[ "$selection" == "q" ]]; then
        echo "Update cancelled"
        exit 0
    fi

    if ! [[ "$selection" =~ ^[0-9]+$ ]] || [[ "$selection" -lt 1 ]] || [[ "$selection" -gt $count ]]; then
        log_error "Invalid selection: $selection"
        exit 1
    fi

    # Get the selected issue file
    local current=0
    for issue in "$ISSUES_DIR"/*.md; do
        if [[ -f "$issue" ]]; then
            local status=$(grep "^status:" "$issue" | head -1 | sed 's/status: *//' || echo "unknown")
            if [[ "$status" != "resolved" ]]; then
                current=$((current + 1))
                if [[ $current -eq $selection ]]; then
                    echo "$issue"
                    return 0
                fi
            fi
        fi
    done

    log_error "Could not find selected issue"
    exit 1
}

extract_frontmatter_value() {
    local file="$1"
    local field="$2"
    grep "^${field}:" "$file" | head -1 | sed "s/${field}: *//" || echo ""
}

extract_issue_summary() {
    local file="$1"
    # Extract Issue Summary section content (first paragraph after ## Issue Summary)
    awk '/^## Issue Summary/,/^## / {if (!/^## / && NF) print}' "$file" | head -1
}

update_frontmatter_field() {
    local file="$1"
    local field="$2"
    local value="$3"

    # Escape special characters for sed
    local escaped_value=$(echo "$value" | sed 's/[&/\]/\\&/g')

    # Update the field in frontmatter
    sed -i.bak "s/^${field}:.*/${field}: ${escaped_value}/" "$file"
    rm -f "${file}.bak"
}

update_issue_summary() {
    local file="$1"
    local new_summary="$2"

    # Replace Issue Summary section content
    awk -v summary="$new_summary" '
        /^## Issue Summary/ {
            print
            print ""
            print summary
            skip=1
            next
        }
        /^## / && skip {
            skip=0
        }
        !skip
    ' "$file" > "$file.tmp"
    mv "$file.tmp" "$file"
}

# --- Main ---

ISSUE_FILE=""
SLUG=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --slug)
            if [[ -z "${2:-}" ]]; then
                log_error "--slug requires a value"
                exit 1
            fi
            SLUG="$2"
            shift 2
            ;;
        --help|-h)
            print_usage
            exit 0
            ;;
        *)
            if [[ -z "$ISSUE_FILE" ]]; then
                ISSUE_FILE="$1"
                shift
            else
                log_error "Unknown argument: $1"
                print_usage
                exit 1
            fi
            ;;
    esac
done

# If slug provided, find the issue file
if [[ -n "$SLUG" ]]; then
    MATCHES=("$ISSUES_DIR"/*"$SLUG"*.md)
    if [[ ${#MATCHES[@]} -eq 0 ]] || [[ ! -f "${MATCHES[0]}" ]]; then
        log_error "No issue found matching slug: $SLUG"
        exit 1
    fi
    if [[ ${#MATCHES[@]} -gt 1 ]]; then
        log_error "Multiple issues match slug '$SLUG'. Please be more specific."
        for match in "${MATCHES[@]}"; do
            echo "  - $(basename "$match")"
        done
        exit 1
    fi
    ISSUE_FILE="${MATCHES[0]}"
fi

# If no issue file specified, prompt to select
if [[ -z "$ISSUE_FILE" ]]; then
    ISSUE_FILE=$(list_open_issues)
fi

# Resolve relative paths
if [[ ! "$ISSUE_FILE" = /* ]]; then
    ISSUE_FILE="$ISSUES_DIR/$ISSUE_FILE"
fi

# Check file exists
if [[ ! -f "$ISSUE_FILE" ]]; then
    log_error "Issue file not found: $ISSUE_FILE"
    exit 1
fi

BASENAME=$(basename "$ISSUE_FILE")
log_info "Updating issue: $BASENAME"
echo ""

# Extract current values
CURRENT_PRIORITY=$(extract_frontmatter_value "$ISSUE_FILE" "priority")
CURRENT_SUMMARY=$(extract_issue_summary "$ISSUE_FILE")
CURRENT_BLOCKED=$(extract_frontmatter_value "$ISSUE_FILE" "blocked")
CURRENT_BLOCKER_INFO=$(extract_frontmatter_value "$ISSUE_FILE" "blocker_info")
CURRENT_RELATED_SPECS=$(extract_frontmatter_value "$ISSUE_FILE" "related_specs")
CURRENT_RELATED_TESTS=$(extract_frontmatter_value "$ISSUE_FILE" "related_tests")
CURRENT_RELATED_FILES=$(extract_frontmatter_value "$ISSUE_FILE" "related_files")

# Display current values
echo "Current values:"
echo "  Priority: $CURRENT_PRIORITY"
echo "  Summary: $CURRENT_SUMMARY"
echo "  Blocked: $CURRENT_BLOCKED"
echo "  Blocker Info: $CURRENT_BLOCKER_INFO"
echo "  Related Specs: $CURRENT_RELATED_SPECS"
echo "  Related Tests: $CURRENT_RELATED_TESTS"
echo "  Related Files: $CURRENT_RELATED_FILES"
echo ""

# Track if any changes were made
CHANGES_MADE=false

# Collect updates
echo "Enter new values (or press Enter to keep current):"
echo ""

# Priority
echo "Priority [$CURRENT_PRIORITY] (critical/high/medium/low):"
read -r NEW_PRIORITY
if [[ -n "$NEW_PRIORITY" ]] && [[ "$NEW_PRIORITY" != "$CURRENT_PRIORITY" ]]; then
    if ! validate_priority "$NEW_PRIORITY"; then
        log_error "Invalid priority: $NEW_PRIORITY. Must be one of: $VALID_PRIORITIES"
        exit 1
    fi
    update_frontmatter_field "$ISSUE_FILE" "priority" "$NEW_PRIORITY"
    CHANGES_MADE=true
    log_info "Updated priority: $CURRENT_PRIORITY -> $NEW_PRIORITY"
fi

# Summary
echo ""
echo "Summary (press Enter to keep current, or provide new text):"
echo "Current: $CURRENT_SUMMARY"
read -r NEW_SUMMARY
if [[ -n "$NEW_SUMMARY" ]] && [[ "$NEW_SUMMARY" != "$CURRENT_SUMMARY" ]]; then
    update_issue_summary "$ISSUE_FILE" "$NEW_SUMMARY"
    CHANGES_MADE=true
    log_info "Updated summary"
fi

# Blocked
echo ""
echo "Blocked [$CURRENT_BLOCKED] (true/false):"
read -r NEW_BLOCKED
if [[ -n "$NEW_BLOCKED" ]] && [[ "$NEW_BLOCKED" != "$CURRENT_BLOCKED" ]]; then
    if [[ "$NEW_BLOCKED" != "true" ]] && [[ "$NEW_BLOCKED" != "false" ]]; then
        log_error "Blocked must be 'true' or 'false'"
        exit 1
    fi
    update_frontmatter_field "$ISSUE_FILE" "blocked" "$NEW_BLOCKED"
    CHANGES_MADE=true
    log_info "Updated blocked: $CURRENT_BLOCKED -> $NEW_BLOCKED"
fi

# Blocker Info
echo ""
echo "Blocker Info [$CURRENT_BLOCKER_INFO]:"
read -r NEW_BLOCKER_INFO
if [[ -n "$NEW_BLOCKER_INFO" ]] && [[ "$NEW_BLOCKER_INFO" != "$CURRENT_BLOCKER_INFO" ]]; then
    update_frontmatter_field "$ISSUE_FILE" "blocker_info" "$NEW_BLOCKER_INFO"
    CHANGES_MADE=true
    log_info "Updated blocker_info"
fi

# Related Specs
echo ""
echo "Related Specs [$CURRENT_RELATED_SPECS] (comma-separated spec numbers):"
read -r NEW_RELATED_SPECS
if [[ -n "$NEW_RELATED_SPECS" ]] && [[ "$NEW_RELATED_SPECS" != "$CURRENT_RELATED_SPECS" ]]; then
    update_frontmatter_field "$ISSUE_FILE" "related_specs" "[$NEW_RELATED_SPECS]"
    CHANGES_MADE=true
    log_info "Updated related_specs"
fi

# Related Tests
echo ""
echo "Related Tests [$CURRENT_RELATED_TESTS] (comma-separated test paths):"
read -r NEW_RELATED_TESTS
if [[ -n "$NEW_RELATED_TESTS" ]] && [[ "$NEW_RELATED_TESTS" != "$CURRENT_RELATED_TESTS" ]]; then
    update_frontmatter_field "$ISSUE_FILE" "related_tests" "[$NEW_RELATED_TESTS]"
    CHANGES_MADE=true
    log_info "Updated related_tests"
fi

# Related Files
echo ""
echo "Related Files [$CURRENT_RELATED_FILES] (comma-separated file paths):"
read -r NEW_RELATED_FILES
if [[ -n "$NEW_RELATED_FILES" ]] && [[ "$NEW_RELATED_FILES" != "$CURRENT_RELATED_FILES" ]]; then
    update_frontmatter_field "$ISSUE_FILE" "related_files" "[$NEW_RELATED_FILES]"
    CHANGES_MADE=true
    log_info "Updated related_files"
fi

echo ""

# If no changes made, exit
if [[ "$CHANGES_MADE" = false ]]; then
    log_info "No changes made. Issue not updated."
    exit 0
fi

# Update Date Updated timestamp
CURRENT_DATE=$(date +"%Y-%m-%dT%H:%M:%S%:z")
sed -i.bak "s/^Date Updated:.*/Date Updated: $CURRENT_DATE/" "$ISSUE_FILE"
rm -f "${ISSUE_FILE}.bak"

log_info "Updated Date Updated timestamp: $CURRENT_DATE"

# Stage changes
git add "$ISSUE_FILE"

log_info "Issue updated successfully: $ISSUE_FILE"
log_info "Changes staged for commit"

# Print file path for command integration
echo "$ISSUE_FILE"
