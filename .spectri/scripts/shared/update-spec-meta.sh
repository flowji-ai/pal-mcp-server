#!/bin/bash

# update-spec-meta.sh
# Utility to programmatically update meta.json files for Spectri
#
# Usage:
#   ./update-spec-meta.sh --spec <path> [options]
#
# Options:
#   --status <status>           Update status (draft|in-progress|iterating|ready-for-testing|resolving-issues|deployed|blocked|archived)
#   --add-blocker <text>        Add a blocker description
#   --remove-blocker <text>     Remove a blocker description
#   --update-doc <filename>     Update document metadata (requires --updated-by)
#   --doc-status <status>       Document status (draft|planned|complete|up-to-date) - used with --update-doc
#   --updated-by <agent>        Agent session identifier for document updates
#
# Implementation Summary Registration:
#   --add-implementation-summary <file>   Register summary in meta.json (requires all 4 params below)
#   --summary-phase <phase>               Phase: specification|planning|implementation|testing|review|polish|revision
#   --summary-scope <scope>               Scope: document name, pipe-separated list, or task range
#   --summary-text <text>                 One-line description of the work
#
# Dependencies: jq

set -e

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
META_FILENAME="meta.json"

# Source shared libraries
source "$SCRIPT_DIR/../../lib/logging.sh"
source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/timestamp-utils.sh"

# --- Functions ---

print_usage() {
    echo "Usage: $0 --spec <path> [options]"
    echo ""
    echo "Options:"
    echo "  --status <status>           Update status (draft|in-progress|iterating|ready-for-testing|resolving-issues|deployed|blocked|archived)"
    echo "  --add-blocker <text>        Add a blocker description"
    echo "  --remove-blocker <text>     Remove a blocker description"
    echo "  --update-doc <filename>     Update document metadata (requires --updated-by)"
    echo "  --doc-status <status>       Document status (draft|planned|complete|up-to-date) - used with --update-doc"
    echo "  --updated-by <agent>        Agent session identifier for document updates"
    echo ""
    echo "Implementation Summary Registration:"
    echo "  --add-implementation-summary <file>   Register summary in meta.json"
    echo "  --summary-phase <phase>               Phase: specification|planning|implementation|testing|review|polish|revision"
    echo "  --summary-scope <scope>               Scope: document name, pipe-separated list, or task range"
    echo "  --summary-text <text>                 One-line description of the work"
    echo "  Note: All 4 summary parameters must be provided together"
    echo ""
    echo "  --help                      Show this help message"
}

check_jq() {
    if ! command -v jq &> /dev/null; then
        log_error "jq is required but not installed."
        exit 1
    fi
}

validate_status() {
    local status="$1"
    case "$status" in
        draft|in-progress|iterating|ready-for-testing|resolving-issues|deployed|blocked|archived)
            return 0
            ;;
        *)
            log_error "Invalid status: '$status'. Must be one of: draft, in-progress, iterating, ready-for-testing, resolving-issues, deployed, blocked, archived."
            return 1
            ;;
    esac
}

validate_doc_status() {
    local status="$1"
    case "$status" in
        draft|planned|complete|up-to-date)
            return 0
            ;;
        *)
            log_error "Invalid document status: '$status'. Must be one of: draft, planned, complete, up-to-date."
            return 1
            ;;
    esac
}

validate_summary_phase() {
    local phase="$1"
    case "$phase" in
        specification|planning|implementation|testing|review|polish|revision)
            return 0
            ;;
        *)
            log_error "Invalid summary phase: '$phase'. Must be one of: specification, planning, implementation, testing, review, polish, revision."
            return 1
            ;;
    esac
}


# --- Main Execution ---

check_jq

SPEC_PATH=""
STATUS=""
ADD_BLOCKER=""
REMOVE_BLOCKER=""
UPDATE_DOC=""
DOC_STATUS=""
UPDATED_BY=""
ADD_IMPL_SUMMARY=""
SUMMARY_PHASE=""
SUMMARY_SCOPE=""
SUMMARY_TEXT=""
HAS_ACTION=false

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --spec)
            SPEC_PATH="$2"
            shift
            ;;
        --status)
            STATUS="$2"
            validate_status "$STATUS" || exit 1
            HAS_ACTION=true
            shift
            ;;
        --add-blocker)
            ADD_BLOCKER="$2"
            HAS_ACTION=true
            shift
            ;;
        --remove-blocker)
            REMOVE_BLOCKER="$2"
            HAS_ACTION=true
            shift
            ;;
        --update-doc)
            UPDATE_DOC="$2"
            HAS_ACTION=true
            shift
            ;;
        --doc-status)
            DOC_STATUS="$2"
            validate_doc_status "$DOC_STATUS" || exit 1
            shift
            ;;
        --updated-by)
            UPDATED_BY="$2"
            shift
            ;;
        --add-implementation-summary)
            ADD_IMPL_SUMMARY="$2"
            HAS_ACTION=true
            shift
            ;;
        --summary-phase)
            SUMMARY_PHASE="$2"
            validate_summary_phase "$SUMMARY_PHASE" || exit 1
            shift
            ;;
        --summary-scope)
            SUMMARY_SCOPE="$2"
            shift
            ;;
        --summary-text)
            SUMMARY_TEXT="$2"
            shift
            ;;
        --help)
            print_usage
            exit 0
            ;;
        *)
            log_error "Unknown parameter passed: $1"
            print_usage
            exit 1
            ;;
    esac
    shift
done

if [[ -z "$SPEC_PATH" ]]; then
    log_error "Missing required argument: --spec <path>"
    print_usage
    exit 1
fi

# Validate --doc-status is only used with --update-doc (check before HAS_ACTION)
if [[ -n "$DOC_STATUS" && -z "$UPDATE_DOC" ]]; then
    log_error "--doc-status can only be used with --update-doc"
    exit 1
fi

if [[ "$HAS_ACTION" == "false" ]]; then
    log_info "No updates requested. Exiting."
    exit 0
fi

# Validate document update parameters
if [[ -n "$UPDATE_DOC" ]]; then
    if [[ -z "$UPDATED_BY" ]]; then
        log_error "--update-doc requires --updated-by parameter"
        exit 1
    fi
fi

# Validate implementation summary parameters (all 4 must be provided together)
if [[ -n "$ADD_IMPL_SUMMARY" || -n "$SUMMARY_PHASE" || -n "$SUMMARY_SCOPE" || -n "$SUMMARY_TEXT" ]]; then
    if [[ -z "$ADD_IMPL_SUMMARY" || -z "$SUMMARY_PHASE" || -z "$SUMMARY_SCOPE" || -z "$SUMMARY_TEXT" ]]; then
        log_error "Implementation summary registration requires all 4 parameters:"
        log_error "  --add-implementation-summary <file>"
        log_error "  --summary-phase <phase>"
        log_error "  --summary-scope <scope>"
        log_error "  --summary-text <text>"
        exit 1
    fi
    if [[ -z "$UPDATED_BY" ]]; then
        log_error "Implementation summary registration requires --updated-by parameter"
        exit 1
    fi
fi

# Resolve full path (if relative path provided)
if [[ ! "$SPEC_PATH" = /* ]]; then
    SPEC_PATH="$(pwd)/$SPEC_PATH"
fi

META_FILE="$SPEC_PATH/$META_FILENAME"

if [[ ! -f "$META_FILE" ]]; then
    log_error "meta.json not found at: $META_FILE"
    exit 1
fi

# Create a temporary file
TEMP_FILE=$(mktemp)

# Build jq filter
JQ_FILTER="."

if [[ -n "$STATUS" ]]; then
    JQ_FILTER="$JQ_FILTER | .status = \"$STATUS\""
fi

if [[ -n "$ADD_BLOCKER" ]]; then
    # Ensure blockers array exists, then append
    JQ_FILTER="$JQ_FILTER | .blockers = ((.blockers // []) + [\"$ADD_BLOCKER\"])"
fi

if [[ -n "$REMOVE_BLOCKER" ]]; then
    # Remove item from array if it exists
    JQ_FILTER="$JQ_FILTER | .blockers = ((.blockers // []) - [\"$REMOVE_BLOCKER\"])"
fi

if [[ -n "$UPDATE_DOC" ]]; then
    # Get current timestamp in ISO 8601 format with timezone
    CURRENT_TIMESTAMP=$(get_iso_timestamp)

    # Escape the document filename for use in jq (handle special chars like dots)
    DOC_KEY="$UPDATE_DOC"

    # Determine status to use (provided or default)
    DOC_STATUS_VALUE="${DOC_STATUS:-planned}"

    # Check if document entry already exists
    DOC_EXISTS=$(jq -r ".documents[\"$DOC_KEY\"] | if . then \"yes\" else \"no\" end" "$META_FILE")

    # Implementation summaries are immutable — reduced schema, no update fields
    if [[ "$DOC_KEY" == implementation-summaries/* ]]; then
        if [[ "$DOC_EXISTS" == "no" ]]; then
            JQ_FILTER="$JQ_FILTER | .documents[\"$DOC_KEY\"] = {
                \"status\": \"completed\",
                \"created\": \"$CURRENT_TIMESTAMP\",
                \"created_by\": \"$UPDATED_BY\"
            }"
        fi
        # If already exists, do nothing — immutable
    elif [[ "$DOC_EXISTS" == "no" ]]; then
        # Create new document entry with status field
        JQ_FILTER="$JQ_FILTER | .documents[\"$DOC_KEY\"] = {
            \"status\": \"$DOC_STATUS_VALUE\",
            \"created\": \"$CURRENT_TIMESTAMP\",
            \"created_by\": \"$UPDATED_BY\",
            \"last_updated\": \"$CURRENT_TIMESTAMP\",
            \"updated_by\": \"$UPDATED_BY\"
        }"
    else
        # Update existing document entry (timestamps always updated)
        JQ_FILTER="$JQ_FILTER | .documents[\"$DOC_KEY\"].last_updated = \"$CURRENT_TIMESTAMP\" |
                   .documents[\"$DOC_KEY\"].updated_by = \"$UPDATED_BY\""
        # Update status only if explicitly provided
        if [[ -n "$DOC_STATUS" ]]; then
            JQ_FILTER="$JQ_FILTER | .documents[\"$DOC_KEY\"].status = \"$DOC_STATUS\""
        fi
    fi
fi

# Handle implementation summary registration
if [[ -n "$ADD_IMPL_SUMMARY" ]]; then
    # Get current timestamp in ISO 8601 format with timezone
    CURRENT_TIMESTAMP=$(get_iso_timestamp)

    # Build the summary object and append to array
    # Use jq's --argjson for proper JSON construction
    JQ_FILTER="$JQ_FILTER | .implementation_summaries = ((.implementation_summaries // []) + [{
        \"file\": \"$ADD_IMPL_SUMMARY\",
        \"created\": \"$CURRENT_TIMESTAMP\",
        \"created_by\": \"$UPDATED_BY\",
        \"phase\": \"$SUMMARY_PHASE\",
        \"scope\": \"$SUMMARY_SCOPE\",
        \"summary\": \"$SUMMARY_TEXT\"
    }])"
fi

# Apply changes using jq
if jq "$JQ_FILTER" "$META_FILE" > "$TEMP_FILE"; then
    mv "$TEMP_FILE" "$META_FILE"
    log_info "Updated $META_FILE successfully."
else
    log_error "Failed to update JSON. Aborting."
    rm "$TEMP_FILE"
    exit 1
fi

# Handle automatic folder moves for deployed/archived statuses
if [[ -n "$STATUS" ]]; then
    if [[ "$STATUS" == "deployed" || "$STATUS" == "archived" ]]; then
        # Get spec folder name (e.g., "003-meta-json-system") - needed for both move and hook
        SPEC_FOLDER_NAME=$(basename "$SPEC_PATH")

        # Determine project root - needed for both move and hook
        CURRENT_PARENT=$(dirname "$SPEC_PATH")
        PROJECT_ROOT="$CURRENT_PARENT"
        while [[ "$PROJECT_ROOT" != "/" && $(basename "$PROJECT_ROOT") != "spectri" ]]; do
            PROJECT_ROOT=$(dirname "$PROJECT_ROOT")
        done
        if [[ $(basename "$PROJECT_ROOT") == "spectri" ]]; then
            PROJECT_ROOT=$(dirname "$PROJECT_ROOT")
        else
            log_error "Could not determine project root. Expected to find 'spectri/' directory."
            exit 1
        fi

        # Determine target folder
        if [[ "$STATUS" == "deployed" ]]; then
            TARGET_PARENT="spectri/specs/04-deployed"
        else
            TARGET_PARENT="spectri/specs/05-archived"
        fi

        # Check if already in target location
        if [[ "$CURRENT_PARENT" == *"/$TARGET_PARENT" ]]; then
            log_info "Spec is already in $TARGET_PARENT/ folder. No move needed."
        else
            # Create target directory if it doesn't exist
            TARGET_DIR="$PROJECT_ROOT/$TARGET_PARENT"
            mkdir -p "$TARGET_DIR"

            # Full target path
            TARGET_PATH="$TARGET_DIR/$SPEC_FOLDER_NAME"

            # Check if target already exists
            if [[ -d "$TARGET_PATH" ]]; then
                log_error "Target folder already exists: $TARGET_PATH"
                log_error "Cannot move spec. Please resolve the conflict manually."
                exit 1
            fi

            # Move the spec folder
            log_info "Moving spec folder to $TARGET_PARENT/..."
            if mv "$SPEC_PATH" "$TARGET_PATH"; then
                log_info "Successfully moved spec to: $TARGET_PATH"
                log_info "meta.json status and location are now in sync."
            else
                log_error "Failed to move spec folder. Status updated but folder not moved."
                log_error "Please move manually: mv \"$SPEC_PATH\" \"$TARGET_PATH\""
                exit 1
            fi
        fi
    fi

    # Hook: Check for deferred issues when spec is deployed
    if [[ "$STATUS" == "deployed" ]]; then
        # Extract spec number from folder name (e.g., "031" from "031-issue-management-triage")
        SPEC_NUMBER=$(basename "$SPEC_FOLDER_NAME" | grep -oE '^[0-9]+')

        if [[ -n "$SPEC_NUMBER" ]]; then
            # Determine issues folder location
            DEFERRED_DIR="$PROJECT_ROOT/spectri/issues/deferred-to-spec"
            RESOLVED_DIR="$PROJECT_ROOT/spectri/issues/resolved"

            if [[ -d "$DEFERRED_DIR" ]]; then
                log_info "Checking for deferred issues related to spec $SPEC_NUMBER..."

                # Find issues that reference this spec number in related_specs array
                MATCHING_ISSUES=()
                while IFS= read -r -d '' issue_file; do
                    # Extract related_specs array and check if it contains our spec number
                    if grep -q "related_specs:.*\b$SPEC_NUMBER\b" "$issue_file" 2>/dev/null; then
                        MATCHING_ISSUES+=("$issue_file")
                    fi
                done < <(find "$DEFERRED_DIR" -maxdepth 1 -name "*.md" -type f -print0 2>/dev/null)

                if [[ ${#MATCHING_ISSUES[@]} -gt 0 ]]; then
                    log_info "Found ${#MATCHING_ISSUES[@]} deferred issue(s) related to spec $SPEC_NUMBER"
                    echo ""

                    for issue_file in "${MATCHING_ISSUES[@]}"; do
                        ISSUE_SLUG=$(basename "$issue_file" .md)
                        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        echo "Spec $SPEC_NUMBER deployed. Found deferred issue:"
                        echo "  File: $(basename "$issue_file")"
                        echo ""

                        # Show issue summary
                        echo "Issue Summary:"
                        sed -n '/^## Issue Summary/,/^## /p' "$issue_file" | sed '$d' | tail -n +2
                        echo ""

                        # Interactive prompt
                        while true; do
                            read -r -p "Review and resolve this issue? [y/n/s(kip)] " response
                            case "$response" in
                                y|Y|yes|Yes)
                                    # Update status to resolved
                                    CURRENT_DATE=$(get_date_timestamp)

                                    # Update frontmatter: status -> resolved, set closed date, update status to spec-updated first
                                    if sed_inplace \
                                        -e "s/^status: .*/status: resolved/" \
                                        -e "s/^closed: .*/closed: $CURRENT_DATE/" \
                                        "$issue_file"; then

                                        # Move to resolved
                                        mkdir -p "$RESOLVED_DIR"
                                        if mv "$issue_file" "$RESOLVED_DIR/"; then
                                            log_info "✓ Issue resolved and moved to spectri/issues/resolved/"
                                        else
                                            log_error "Failed to move issue to resolved folder"
                                        fi
                                    else
                                        log_error "Failed to update issue frontmatter"
                                    fi
                                    break
                                    ;;
                                n|N|no|No)
                                    log_info "Keeping issue deferred (spec work incomplete)"
                                    break
                                    ;;
                                s|S|skip|Skip)
                                    log_info "Skipping this issue"
                                    break
                                    ;;
                                *)
                                    echo "Invalid response. Please enter y, n, or s."
                                    ;;
                            esac
                        done
                        echo ""
                    done

                    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    echo ""
                fi
            fi
        fi
    fi
fi

# Auto-regenerate registry and roadmap files
# Run silently - only show errors
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REGISTRY_SCRIPT="$SCRIPT_DIR/generate-registry.sh"

if [[ -x "$REGISTRY_SCRIPT" ]]; then
    if ! "$REGISTRY_SCRIPT" > /dev/null 2>&1; then
        log_error "WARNING: Registry generation failed. Run manually: $REGISTRY_SCRIPT" >&2
    fi
fi
