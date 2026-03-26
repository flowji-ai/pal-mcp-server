#!/usr/bin/env bash

set -e

# Escape special characters for sed replacement
escape_sed() {
    printf '%s\n' "$1" | sed -e 's/[\/&|]/\\&/g'
}

# Parse command line arguments
JSON_MODE=false
SPEC_OVERRIDE=""
SESSION_ID=""
FEATURE_NAME=""
ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --json)
            JSON_MODE=true
            shift
            ;;
        --spec)
            SPEC_OVERRIDE="$2"
            shift 2
            ;;
        --session-id)
            SESSION_ID="$2"
            shift 2
            ;;
        --feature-name)
            FEATURE_NAME="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [--json] [--spec <spec-folder>] [--session-id <id>] [--feature-name <name>]"
            echo "  --json              Output results in JSON format"
            echo "  --spec <folder>     Specify spec folder directly (branchless mode)"
            echo "                      Examples: --spec 011-global-custom-agents"
            echo "                               --spec spectri/specs/011-global-custom-agents"
            echo "  --session-id <id>   Session ID for template placeholder replacement"
            echo "  --feature-name <n>  Feature name for template placeholder replacement"
            echo "  --help              Show this help message"
            exit 0
            ;;
        *)
            ARGS+=("$1")
            shift
            ;;
    esac
done

# Get script directory and load common functions
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/logging.sh"
source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/timestamp-utils.sh"

# Get all paths and variables from common functions
eval $(get_feature_paths "$SPEC_OVERRIDE")

# Check if we're on a proper feature branch (only for git repos, unless branchless mode)
check_feature_branch "$CURRENT_BRANCH" "$HAS_GIT" "$SKIP_BRANCH_CHECK" || exit 1

# Ensure the feature directory exists
mkdir -p "$FEATURE_DIR"

# Copy plan template if it exists
TEMPLATE="$REPO_ROOT/.spectri/templates/spectri-core/plan-template.md"
if [[ -f "$TEMPLATE" ]]; then
    cp "$TEMPLATE" "$IMPL_PLAN"

    # Replace frontmatter placeholders
    TIMESTAMP=$(get_iso_timestamp)
    RESOLVED_SESSION_ID="${SESSION_ID:-Unknown}"
    RESOLVED_FEATURE_NAME="${FEATURE_NAME:-Unknown}"
    BRANCH_NAME="$(basename "$FEATURE_DIR")"

    SAFE_SESSION_ID=$(escape_sed "$RESOLVED_SESSION_ID")
    SAFE_FEATURE_NAME=$(escape_sed "$RESOLVED_FEATURE_NAME")
    SAFE_BRANCH_NAME=$(escape_sed "$BRANCH_NAME")

    sed_inplace "s|{{ISO_TIMESTAMP}}|${TIMESTAMP}|g" "$IMPL_PLAN"
    sed_inplace "s|\[AGENT_SESSION_ID\]|${SAFE_SESSION_ID}|g" "$IMPL_PLAN"
    sed_inplace "s|\[FEATURE\]|${SAFE_FEATURE_NAME}|g" "$IMPL_PLAN"
    sed_inplace "s|\[###-feature-name\]|${SAFE_BRANCH_NAME}|g" "$IMPL_PLAN"

    echo "Copied plan template to $IMPL_PLAN (placeholders replaced)"
else
    echo "Warning: Plan template not found at $TEMPLATE"
    # Create a basic plan file if template doesn't exist
    touch "$IMPL_PLAN"
fi

# Output results
if $JSON_MODE; then
    printf '{"FEATURE_SPEC":"%s","IMPL_PLAN":"%s","SPECS_DIR":"%s","BRANCH":"%s","HAS_GIT":"%s"}\n' \
        "$FEATURE_SPEC" "$IMPL_PLAN" "$FEATURE_DIR" "$CURRENT_BRANCH" "$HAS_GIT"
else
    echo "FEATURE_SPEC: $FEATURE_SPEC"
    echo "IMPL_PLAN: $IMPL_PLAN"
    echo "SPECS_DIR: $FEATURE_DIR"
    echo "BRANCH: $CURRENT_BRANCH"
    echo "HAS_GIT: $HAS_GIT"
fi
