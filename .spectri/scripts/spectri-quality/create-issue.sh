#!/usr/bin/env bash
# create-issue.sh
# Create a new issue file with auto-populated metadata
#
# Usage:
#   ./create-issue.sh --slug SLUG --priority PRIORITY --summary SUMMARY [OPTIONS]
#
# Parameters:
#   --slug SLUG             Issue slug (kebab-case)
#   --priority PRIORITY     Priority (critical/high/medium/low)
#   --summary SUMMARY       Issue summary text
#   --screenshot PATH       Optional screenshot path (will be linked and moved)
#   --agent ID              Agent session ID (optional, defaults to "unknown")
#   --user USERNAME         Username (optional, auto-detected via whoami)
#
# Dependencies: .spectri/templates/spectri-quality/issue-template.md
# Task Reference: T007-T012 (spec 031)

set -euo pipefail

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"
REPO_ROOT=$(get_repo_root)

TEMPLATE_FILE="$REPO_ROOT/.spectri/templates/spectri-quality/issue-template.md"
ISSUES_DIR="$REPO_ROOT/spectri/issues"
SCREENSHOTS_DIR="$REPO_ROOT/screenshots"
SCREENSHOTS_PROCESSED_DIR="$REPO_ROOT/screenshots/processed"

# Source shared libraries
source "$SCRIPT_DIR/../../lib/validation.sh"
source "$REPO_ROOT/.spectri/lib/logging.sh"
source "$REPO_ROOT/.spectri/lib/timestamp-utils.sh"

# --- Functions ---

print_usage() {
    echo "Usage: $0 --slug SLUG --priority PRIORITY --summary SUMMARY [OPTIONS]"
    echo ""
    echo "Parameters:"
    echo "  --slug SLUG             Issue slug (kebab-case)"
    echo "  --priority PRIORITY     Priority (critical/high/medium/low)"
    echo "  --summary SUMMARY       Issue summary text"
    echo "  --screenshot PATH       Optional screenshot path (will be linked and moved)"
    echo "  --agent ID              Agent session ID (optional)"
    echo "  --user USERNAME         Username (optional, auto-detected via whoami)"
    echo "  --target-repo REPO      Target repository: 'current' (default) or 'spectri'"
    echo "                          Use 'spectri' for Spectri framework issues found in other projects"
    echo "                          [INTERNAL TESTING -- remove after 2026-04-15]"
    echo ""
    echo "Valid priorities: $VALID_PRIORITIES"
    echo ""
    echo "Examples:"
    echo "  $0 --slug \"fix-login-bug\" --priority high --summary \"Login fails with valid credentials\""
    echo "  $0 --slug \"ui-broken\" --priority critical --summary \"UI not rendering\" --screenshot screenshots/ui-bug.png"
}

generate_filename() {
    local slug="$1"
    local date_part=$(get_date_timestamp)
    echo "${date_part}-${slug}.md"
}

# --- Main ---

# Parse arguments
SLUG=""
PRIORITY=""
SUMMARY=""
SCREENSHOT=""
AGENT="unknown"
USER=$(whoami || echo "unknown")
TARGET_REPO="current"  # INTERNAL TESTING: 'current' or 'spectri' -- remove after 2026-04-15

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
        --priority)
            if [[ -z "${2:-}" ]]; then
                log_error "--priority requires a value"
                exit 1
            fi
            PRIORITY="$2"
            shift 2
            ;;
        --summary)
            if [[ -z "${2:-}" ]]; then
                log_error "--summary requires a value"
                exit 1
            fi
            SUMMARY="$2"
            shift 2
            ;;
        --screenshot)
            if [[ -z "${2:-}" ]]; then
                log_error "--screenshot requires a value"
                exit 1
            fi
            SCREENSHOT="$2"
            shift 2
            ;;
        --agent)
            if [[ -z "${2:-}" ]]; then
                log_error "--agent requires a value"
                exit 1
            fi
            AGENT="$2"
            shift 2
            ;;
        --user)
            if [[ -z "${2:-}" ]]; then
                log_error "--user requires a value"
                exit 1
            fi
            USER="$2"
            shift 2
            ;;
        --target-repo)
            if [[ -z "${2:-}" ]]; then
                log_error "--target-repo requires a value"
                exit 1
            fi
            TARGET_REPO="$2"
            shift 2
            ;;
        --help|-h)
            print_usage
            exit 0
            ;;
        *)
            log_error "Unknown argument: $1"
            print_usage
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$SLUG" ]]; then
    log_error "Missing required parameter: --slug"
    print_usage
    exit 1
fi

if [[ -z "$PRIORITY" ]]; then
    log_error "Missing required parameter: --priority"
    print_usage
    exit 1
fi

if [[ -z "$SUMMARY" ]]; then
    log_error "Missing required parameter: --summary"
    print_usage
    exit 1
fi

# Validate priority
if ! validate_priority "$PRIORITY"; then
    log_error "Invalid priority: $PRIORITY. Must be one of: $VALID_PRIORITIES"
    exit 1
fi

# Validate slug format
if ! validate_slug "$SLUG"; then
    log_error "Invalid slug format: $SLUG. Must be kebab-case (lowercase letters, numbers, hyphens only)"
    exit 1
fi

# Validate target-repo
# [INTERNAL TESTING -- remove after 2026-04-15]
if [[ "$TARGET_REPO" != "current" && "$TARGET_REPO" != "spectri" ]]; then
    log_error "Invalid --target-repo value: $TARGET_REPO. Must be 'current' or 'spectri'"
    exit 1
fi

# Check template exists
if [[ ! -f "$TEMPLATE_FILE" ]]; then
    log_error "Template file not found: $TEMPLATE_FILE"
    exit 1
fi

# Generate filename and target path
FILENAME=$(generate_filename "$SLUG")
TARGET_PATH="$ISSUES_DIR/$FILENAME"

# Check if file already exists
if [[ -f "$TARGET_PATH" ]]; then
    log_error "Issue file already exists: $TARGET_PATH"
    exit 1
fi

# Prepare metadata values
OPENED=$(get_date_timestamp)
TITLE=$(echo "$SLUG" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')

# Handle screenshot if provided
SCREENSHOT_LINK=""
if [[ -n "$SCREENSHOT" ]]; then
    if [[ ! -f "$SCREENSHOT" ]]; then
        log_error "Screenshot file not found: $SCREENSHOT"
        exit 1
    fi

    # Get screenshot filename
    SCREENSHOT_FILENAME=$(basename "$SCREENSHOT")
    SCREENSHOT_DEST="$SCREENSHOTS_PROCESSED_DIR/$SCREENSHOT_FILENAME"

    # Move screenshot to processed folder
    mkdir -p "$SCREENSHOTS_PROCESSED_DIR"
    if ! mv "$SCREENSHOT" "$SCREENSHOT_DEST"; then
        log_error "Failed to move screenshot: $SCREENSHOT"
        log_error "Issue not created"
        exit 1
    fi
    log_info "Moved screenshot to: screenshots/processed/$SCREENSHOT_FILENAME"

    # Store relative path for template
    SCREENSHOT_LINK="screenshots/processed/$SCREENSHOT_FILENAME"
fi

# Create issue file from template
log_info "Creating issue file: $FILENAME"

# Read template and replace placeholders
CONTENT=$(cat "$TEMPLATE_FILE")

# Replace placeholders
CONTENT=$(echo "$CONTENT" | sed "s|{{STATUS}}|identified|g")
CONTENT=$(echo "$CONTENT" | sed "s|{{PRIORITY}}|$PRIORITY|g")
CONTENT=$(echo "$CONTENT" | sed "s|{{CREATED_BY_AGENT}}|$AGENT|g")
CONTENT=$(echo "$CONTENT" | sed "s|{{CREATED_BY_USER}}|$USER|g")
CONTENT=$(echo "$CONTENT" | sed "s|{{OPENED}}|$OPENED|g")
CONTENT=$(echo "$CONTENT" | sed "s|{{CLOSED}}|null|g")
CONTENT=$(echo "$CONTENT" | sed "s|{{BLOCKED}}|false|g")
CONTENT=$(echo "$CONTENT" | sed "s|{{BLOCKER_INFO}}|null|g")
CONTENT=$(echo "$CONTENT" | sed "s|{{SPEC_NEEDS_UPDATE}}|null|g")
# [INTERNAL TESTING -- remove after 2026-04-15]
if [[ "$TARGET_REPO" == "spectri" ]]; then
    # Determine current project name for attribution
    CURRENT_PROJECT=$(git remote get-url origin 2>/dev/null | sed 's|.*/||' | sed 's|\.git$||' || basename "$REPO_ROOT")
    # Escape sed replacement special chars (&, \) in project name
    CURRENT_PROJECT_SAFE=$(printf '%s' "$CURRENT_PROJECT" | sed 's/[&\\]/\\&/g')
    CONTENT=$(echo "$CONTENT" | sed "s|{{RELATES_TO_THIS_PROJECT}}|false|g")
    CONTENT=$(echo "$CONTENT" | sed "s|{{TARGET_REPO}}|$CURRENT_PROJECT_SAFE|g")
else
    CONTENT=$(echo "$CONTENT" | sed "s|{{RELATES_TO_THIS_PROJECT}}|true|g")
    CONTENT=$(echo "$CONTENT" | sed "s|{{TARGET_REPO}}|null|g")
fi
CONTENT=$(echo "$CONTENT" | sed "s|{{TITLE}}|$TITLE|g")
CONTENT=$(echo "$CONTENT" | sed "s|{{ISSUE_SUMMARY}}|$SUMMARY|g")

# If screenshot provided, add to related_files
if [[ -n "$SCREENSHOT_LINK" ]]; then
    CONTENT=$(echo "$CONTENT" | sed "s|related_files: \[\]|related_files: [\"$SCREENSHOT_LINK\"]|g")
fi

# Write to file
echo "$CONTENT" > "$TARGET_PATH"

log_info "Issue created successfully: $TARGET_PATH"
log_info "Status: identified (awaiting triage)"

# Print file path for command integration
echo "$TARGET_PATH"
