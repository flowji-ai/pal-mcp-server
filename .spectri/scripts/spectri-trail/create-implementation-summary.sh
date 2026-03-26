#!/usr/bin/env bash
# create-implementation-summary.sh
# Generate implementation summary markdown file from template with auto-populated metadata
#
# Usage:
#   ./create-implementation-summary.sh --spec <folder> --scope <scope> \
#       --session-id <id> --agent-name <name> --session-start <ts> \
#       [--changes <description>] [--related-specs <refs>]
#
# Parameters:
#   --spec <folder>          Spec folder path (e.g., spectri/specs/04-deployed/004-implementation-summaries)
#   --scope <scope>          Scope declaration (format validation)
#   --session-id <id>        Agent session ID (e.g., "vermillion-caracal-1202")
#   --agent-name <name>      Full agent name (e.g., "Claude Vermillion Caracal 1202")
#   --session-start <ts>     Session start timestamp (ISO 8601)
#   --changes <description>  Optional: High-level summary of changes made (e.g., "Added Phase 5 for export")
#   --related-specs <refs>   Optional: Cross-references to related spec sections (e.g., "US4, FR-019, FR-020")
#
# Dependencies: jq, .spectri/lib/timestamp-utils.sh, .spectri/scripts/shared/update-spec-meta.sh

set -euo pipefail

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"
REPO_ROOT=$(get_repo_root)

TEMPLATE_FILE="$REPO_ROOT/.spectri/templates/spectri-trail/implementation-summary-template.md"
TIMESTAMP_UTILS="$REPO_ROOT/.spectri/lib/timestamp-utils.sh"
UPDATE_META_SCRIPT="$REPO_ROOT/.spectri/scripts/shared/update-spec-meta.sh"

# Source shared libraries
source "$REPO_ROOT/.spectri/lib/logging.sh"
source "$REPO_ROOT/.spectri/lib/filename-utils.sh"

# --- Functions ---

print_usage() {
    echo "Usage: $0 --spec <folder> --scope <scope> --session-id <id> --agent-name <name> --session-start <ts> [--changes <desc>] [--related-specs <refs>]"
    echo ""
    echo "Parameters:"
    echo "  --spec <folder>          Spec folder path (e.g., spectri/specs/04-deployed/004-implementation-summaries)"
    echo "  --scope <scope>          Scope declaration (single doc, pipe-separated, or task range)"
    echo "  --session-id <id>        Agent session ID (e.g., 'vermillion-caracal-1202')"
    echo "  --agent-name <name>      Full agent name (e.g., 'Claude Vermillion Caracal 1202')"
    echo "  --session-start <ts>     Session start timestamp (ISO 8601)"
    echo "  --changes <desc>         Optional: High-level summary of changes made"
    echo "  --related-specs <refs>   Optional: Cross-references to related spec sections"
    echo "  --help                   Show this help message"
}

# Validate scope format
# Valid formats:
#   - Single doc: "spec.md", "plan.md", "quickstart.md"
#   - Pipe-separated: "plan.md|research.md|tasks.md"
#   - Task range: "T001-T010", "T015-T021"
validate_scope() {
    local scope="$1"

    # Basic format validation (non-empty, reasonable characters)
    # Allow alphanumeric, dots, underscores, slashes, and pipes
    if [[ ! "$scope" =~ ^[a-zA-Z0-9._/-]+(\|[a-zA-Z0-9._/-]+)*$ ]]; then
        log_error "Invalid scope format: '$scope'. Use document names, task ranges, or pipe-separated components."
        return 1
    fi

    # Ensure scope is not empty
    if [[ -z "$scope" ]]; then
        log_error "Scope cannot be empty."
        return 1
    fi

    return 0
}

# Create implementation-summaries folder if missing
create_summaries_folder() {
    local spec_folder="$1"
    local summaries_folder="$spec_folder/implementation-summaries"

    if [[ ! -d "$summaries_folder" ]]; then
        log_info "Creating implementation-summaries folder..."
        mkdir -p "$summaries_folder"
        touch "$summaries_folder/.gitkeep"
        log_info "Created $summaries_folder with .gitkeep"
    fi
}


# --- Main Execution ---

# Source timestamp utilities
if [[ ! -f "$TIMESTAMP_UTILS" ]]; then
    log_error "Timestamp utilities not found: $TIMESTAMP_UTILS"
    exit 1
fi
source "$TIMESTAMP_UTILS"

# Initialize parameters
SPEC_FOLDER=""
SCOPE=""
SESSION_ID=""
AGENT_NAME=""
SESSION_START=""
CHANGES=""
RELATED_SPECS=""

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --spec)
            SPEC_FOLDER="$2"
            shift
            ;;
        --scope)
            SCOPE="$2"
            shift
            ;;
        --session-id)
            SESSION_ID="$2"
            shift
            ;;
        --agent-name)
            AGENT_NAME="$2"
            shift
            ;;
        --session-start)
            SESSION_START="$2"
            shift
            ;;
        --changes)
            CHANGES="$2"
            shift
            ;;
        --related-specs)
            RELATED_SPECS="$2"
            shift
            ;;
        --help)
            print_usage
            exit 0
            ;;
        *)
            log_error "Unknown parameter: $1"
            print_usage
            exit 1
            ;;
    esac
    shift
done

# Validate required parameters
if [[ -z "$SPEC_FOLDER" ]]; then
    log_error "Missing required parameter: --spec <folder>"
    print_usage
    exit 1
fi

if [[ -z "$SCOPE" ]]; then
    log_error "Missing required parameter: --scope <scope>"
    print_usage
    exit 1
fi

if [[ -z "$SESSION_ID" ]]; then
    log_error "Missing required parameter: --session-id <id>"
    print_usage
    exit 1
fi

if [[ -z "$AGENT_NAME" ]]; then
    log_error "Missing required parameter: --agent-name <name>"
    print_usage
    exit 1
fi

if [[ -z "$SESSION_START" ]]; then
    log_error "Missing required parameter: --session-start <ts>"
    print_usage
    exit 1
fi

# Resolve spec folder to absolute path if relative
if [[ ! "$SPEC_FOLDER" = /* ]]; then
    SPEC_FOLDER="$(cd "$SPEC_FOLDER" 2>/dev/null && pwd)" || {
        log_error "Spec folder not found: $SPEC_FOLDER"
        exit 1
    }
fi

# Validate spec folder exists
if [[ ! -d "$SPEC_FOLDER" ]]; then
    log_error "Spec folder not found: $SPEC_FOLDER"
    exit 1
fi

# Validate scope format
if ! validate_scope "$SCOPE"; then
    exit 1
fi

# Validate template exists
if [[ ! -f "$TEMPLATE_FILE" ]]; then
    log_error "Template not found: $TEMPLATE_FILE"
    exit 1
fi

# Defensive folder creation
create_summaries_folder "$SPEC_FOLDER"

# Generate timestamps
CURRENT_ISO_TIMESTAMP=$(get_iso_timestamp)
FILENAME_TIMESTAMP=$(get_filename_timestamp)

# Generate filename
SLUG=$(slugify "$SCOPE")
SUMMARY_FILENAME="${FILENAME_TIMESTAMP}_${SLUG}.md"
SUMMARY_PATH="$SPEC_FOLDER/implementation-summaries/$SUMMARY_FILENAME"

# Get username
USERNAME=$(whoami)

# Load template
TEMPLATE_CONTENT=$(<"$TEMPLATE_FILE")

# Replace template placeholders via direct substitution (no awk insertion)
SUMMARY_CONTENT="$TEMPLATE_CONTENT"
SUMMARY_CONTENT="${SUMMARY_CONTENT//{{ISO_TIMESTAMP}}/$CURRENT_ISO_TIMESTAMP}"
SUMMARY_CONTENT="${SUMMARY_CONTENT//\[AGENT_NAME\]/$AGENT_NAME}"
SUMMARY_CONTENT="${SUMMARY_CONTENT//\[USERNAME\]/$USERNAME}"
SUMMARY_CONTENT="${SUMMARY_CONTENT//\[SESSION_ID\]/$SESSION_ID}"
SUMMARY_CONTENT="${SUMMARY_CONTENT//\[SESSION_START\]/$SESSION_START}"
SUMMARY_CONTENT="${SUMMARY_CONTENT//\[SCOPE\]/$SCOPE}"

# Insert optional Changes and Related Specs fields into frontmatter after Scope line
if [[ -n "$CHANGES" || -n "$RELATED_SPECS" ]]; then
    EXTRA_FIELDS=""
    if [[ -n "$CHANGES" ]]; then
        EXTRA_FIELDS="${EXTRA_FIELDS}
Changes: $CHANGES"
    fi
    if [[ -n "$RELATED_SPECS" ]]; then
        EXTRA_FIELDS="${EXTRA_FIELDS}
Related Specs: $RELATED_SPECS"
    fi
    SUMMARY_CONTENT="${SUMMARY_CONTENT/Scope: $SCOPE/Scope: $SCOPE$EXTRA_FIELDS}"
fi

# If changes or related-specs provided, pre-populate the summary sections
if [[ -n "$CHANGES" || -n "$RELATED_SPECS" ]]; then
    # Pre-populate the Summary section with provided context
    PRE_POPULATED_SUMMARY=""
    if [[ -n "$CHANGES" ]]; then
        PRE_POPULATED_SUMMARY="**What changed**: $CHANGES"
    fi
    if [[ -n "$RELATED_SPECS" ]]; then
        if [[ -n "$PRE_POPULATED_SUMMARY" ]]; then
            PRE_POPULATED_SUMMARY="$PRE_POPULATED_SUMMARY

**Related spec sections**: $RELATED_SPECS"
        else
            PRE_POPULATED_SUMMARY="**Related spec sections**: $RELATED_SPECS"
        fi
    fi

    # Replace placeholder in template with pre-populated content
    SUMMARY_CONTENT="${SUMMARY_CONTENT//\[SUMMARY_PLACEHOLDER\]/$PRE_POPULATED_SUMMARY}"
else
    # No context provided - remove the placeholder line entirely
    SUMMARY_CONTENT="${SUMMARY_CONTENT//\[SUMMARY_PLACEHOLDER\]/}"
fi

# Write summary file
echo "$SUMMARY_CONTENT" > "$SUMMARY_PATH"

log_info "Implementation summary created: $SUMMARY_PATH"
log_info "Scope: $SCOPE"

# Register in meta.json (non-blocking)
RELATIVE_SUMMARY_PATH="implementation-summaries/$SUMMARY_FILENAME"

if [[ -f "$UPDATE_META_SCRIPT" ]]; then
    if bash "$UPDATE_META_SCRIPT" --spec "$SPEC_FOLDER" --update-doc "$RELATIVE_SUMMARY_PATH" --updated-by "$SESSION_ID" 2>&1; then
        log_info "Registered in meta.json: $RELATIVE_SUMMARY_PATH"
    else
        log_warn "Failed to register in meta.json. Summary file created successfully, but meta.json not updated."
        log_warn "You may need to manually register: $RELATIVE_SUMMARY_PATH"
    fi
else
    log_warn "update-spec-meta.sh not found. Summary created but not registered in meta.json."
fi

# Report success (exit 0 even if meta.json failed - non-blocking)
echo ""
echo "✅ Summary created successfully!"
echo "   File: $SUMMARY_PATH"
echo "   Scope: $SCOPE"
echo ""
echo "Next steps:"
echo "   1. Fill in narrative sections in the summary file"
echo "   2. Fill in the 'Files Modified' table"
echo "   3. Commit work + completed summary together"
echo ""

# Calculate relative path from repo root to summary file for handoff block
# Handle cross-platform differences for realpath command
if command -v grealpath >/dev/null 2>&1; then
    # GNU realpath (Linux) via Homebrew
    RELATIVE_SUMMARY_PATH=$(grealpath --relative-to="$REPO_ROOT" "$SUMMARY_PATH")
elif [[ "$OSTYPE" == "darwin"* ]] && command -v realpath >/dev/null 2>&1; then
    # Check if macOS has realpath with --relative-to (unlikely)
    if realpath --relative-to=. . >/dev/null 2>&1; then
        RELATIVE_SUMMARY_PATH=$(realpath --relative-to="$REPO_ROOT" "$SUMMARY_PATH")
    else
        # Fallback for macOS: manually compute relative path
        RELATIVE_SUMMARY_PATH="${SUMMARY_PATH#$REPO_ROOT/}"
    fi
else
    # Fallback for systems without realpath
    RELATIVE_SUMMARY_PATH="${SUMMARY_PATH#$REPO_ROOT/}"
fi

# Output handoff block for agents to include in chat
echo ""
echo "## Implementation Complete"
echo ""
echo "📄 **Summary**: [$RELATIVE_SUMMARY_PATH]($RELATIVE_SUMMARY_PATH)"
echo "🔗 **Commit**: \[COMMIT_HASH\] (\[commit message\])"
echo ""
echo "_Fill in \[COMMIT_HASH\] after committing_"
echo ""

exit 0