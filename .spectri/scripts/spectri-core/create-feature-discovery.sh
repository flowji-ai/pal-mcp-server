#!/usr/bin/env bash
# create-feature-discovery.sh - Scaffold a feature-discovery.md from template
#
# Usage:
#   create-feature-discovery.sh --output <path> [--feature-name <name>] [--session-id <id>]
#
# Options:
#   --output <path>        Required. Output path for the feature discovery document
#   --feature-name <name>  Feature name for template placeholder replacement
#   --session-id <id>      Session ID for template placeholder replacement
#   --help, -h             Show this help message

set -e

SCRIPT_DIR_EARLY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR_EARLY/../../lib/logging.sh"
source "$SCRIPT_DIR_EARLY/../../lib/common.sh"
source "$SCRIPT_DIR_EARLY/../../lib/timestamp-utils.sh"

# Escape special characters for sed replacement
escape_sed() {
    printf '%s\n' "$1" | sed -e 's/[\/&|]/\\&/g'
}

OUTPUT_PATH=""
FEATURE_NAME=""
SESSION_ID=""

i=1
while [ $i -le $# ]; do
    arg="${!i}"
    case "$arg" in
        --output)
            if [ $((i + 1)) -gt $# ]; then
                log_error '--output requires a value'
                exit 1
            fi
            i=$((i + 1))
            next_arg="${!i}"
            if [[ "$next_arg" == --* ]]; then
                log_error '--output requires a value'
                exit 1
            fi
            OUTPUT_PATH="$next_arg"
            ;;
        --feature-name)
            if [ $((i + 1)) -gt $# ]; then
                log_error '--feature-name requires a value'
                exit 1
            fi
            i=$((i + 1))
            next_arg="${!i}"
            if [[ "$next_arg" == --* ]]; then
                log_error '--feature-name requires a value'
                exit 1
            fi
            FEATURE_NAME="$next_arg"
            ;;
        --session-id)
            if [ $((i + 1)) -gt $# ]; then
                log_error '--session-id requires a value'
                exit 1
            fi
            i=$((i + 1))
            next_arg="${!i}"
            if [[ "$next_arg" == --* ]]; then
                log_error '--session-id requires a value'
                exit 1
            fi
            SESSION_ID="$next_arg"
            ;;
        --help|-h)
            echo "Usage: $0 --output <path> [--feature-name <name>] [--session-id <id>]"
            echo ""
            echo "Options:"
            echo "  --output <path>        Required. Output path for the feature discovery document"
            echo "  --feature-name <name>  Feature name for template placeholder replacement"
            echo "  --session-id <id>      Session ID for template placeholder replacement"
            echo "  --help, -h             Show this help message"
            exit 0
            ;;
        *)
            log_error "Unknown argument: $arg"
            exit 1
            ;;
    esac
    i=$((i + 1))
done

if [ -z "$OUTPUT_PATH" ]; then
    log_error "--output is required"
    exit 1
fi

# Resolve repository root
REPO_ROOT=$(get_repo_root)

TEMPLATE="$REPO_ROOT/.spectri/templates/spectri-core/feature-discovery-template.md"

if [ ! -f "$TEMPLATE" ]; then
    log_error "Feature discovery template not found at $TEMPLATE"
    exit 1
fi

# Ensure output directory exists
mkdir -p "$(dirname "$OUTPUT_PATH")"

cp "$TEMPLATE" "$OUTPUT_PATH"

# Replace frontmatter placeholders
TIMESTAMP=$(get_iso_timestamp)
RESOLVED_SESSION_ID="${SESSION_ID:-Unknown}"
RESOLVED_FEATURE_NAME="${FEATURE_NAME:-Unknown}"

# Escape special characters for safe sed substitution
SAFE_SESSION_ID=$(escape_sed "$RESOLVED_SESSION_ID")
SAFE_FEATURE_NAME=$(escape_sed "$RESOLVED_FEATURE_NAME")

sed_inplace "s|{{ISO_TIMESTAMP}}|${TIMESTAMP}|g" "$OUTPUT_PATH"
sed_inplace "s|\[AGENT_SESSION_ID\]|${SAFE_SESSION_ID}|g" "$OUTPUT_PATH"
sed_inplace "s|\[FEATURE NAME\]|${SAFE_FEATURE_NAME}|g" "$OUTPUT_PATH"

echo "Feature discovery document created: $OUTPUT_PATH"
