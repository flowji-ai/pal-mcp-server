#!/usr/bin/env bash
# extract-decisions.sh - Extract architectural decisions from plan.md
#
# Usage:
#   extract-decisions.sh --plan path/to/plan.md [--json]
#
# Output:
#   JSON array of decisions extracted from Technical Context section
#   [
#     {
#       "decision": "Use FastAPI for backend framework",
#       "section": "Technical Context",
#       "line": 42,
#       "context": "Need async Python web framework"
#     },
#     ...
#   ]
#
# Exit Codes:
#   0 - Success
#   1 - Missing required input
#   2 - File not found or not readable
#   3 - No Technical Context section found

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/logging.sh"

# Default values
PLAN_FILE=""
JSON_OUTPUT=false

# Error handling
error_exit() {
    local code=$1
    shift
    log_error "$*"
    exit "$code"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --plan)
            PLAN_FILE="$2"
            shift 2
            ;;
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        --help|-h)
            echo "Usage: extract-decisions.sh --plan path/to/plan.md [--json]"
            echo ""
            echo "Options:"
            echo "  --plan FILE      Path to plan.md file (required)"
            echo "  --json           Output JSON format (default: true)"
            echo "  --help           Show this help message"
            exit 0
            ;;
        *)
            error_exit 1 "Unknown option: $1"
            ;;
    esac
done

# Validate required arguments
if [[ -z "$PLAN_FILE" ]]; then
    error_exit 1 "Missing required argument: --plan"
fi

# Verify file exists and is readable
if [[ ! -f "$PLAN_FILE" ]]; then
    error_exit 2 "File not found: $PLAN_FILE"
fi

if [[ ! -r "$PLAN_FILE" ]]; then
    error_exit 2 "File not readable: $PLAN_FILE"
fi

# Extract decisions from Technical Context section
extract_decisions() {
    local file="$1"
    local in_section=false
    local line_num=0
    local decisions=()

    # Keywords that indicate architectural decisions
    local decision_keywords=(
        "Language" "Version" "Framework" "Library" "Dependencies"
        "Storage" "Database" "Cache" "Testing" "Platform"
        "Project Type" "Performance" "Constraints" "Scale"
        "Architecture" "Infrastructure" "Deployment" "API"
        "Authentication" "Authorization"
    )

    while IFS= read -r line; do
        ((line_num++)) || true

        # Detect Technical Context section
        if [[ "$line" =~ ^##[[:space:]]+Technical\ Context ]]; then
            in_section=true
            continue
        fi

        # Exit section on next heading
        if [[ "$in_section" = true ]] && [[ "$line" =~ ^##[[:space:]] ]] && [[ ! "$line" =~ ^##[[:space:]]+Technical\ Context ]]; then
            break
        fi

        # Extract decisions from Technical Context
        if [[ "$in_section" = true ]]; then
            # Look for decision patterns like "**Key**: Value" or "Key: Value"
            if [[ "$line" =~ ^\*\*([^*]+)\*\*:[[:space:]](.+)$ ]] || [[ "$line" =~ ^([^:]+):[[:space:]](.+)$ ]]; then
                local key="${BASH_REMATCH[1]}"
                local value="${BASH_REMATCH[2]}"

                # Check if key matches decision keywords
                for keyword in "${decision_keywords[@]}"; do
                    if [[ "$key" == *"$keyword"* ]]; then
                        # Extract decision text
                        local decision="Use $value"
                        local context="$key decision from Technical Context"

                        # Add to decisions array
                        decisions+=("{\"decision\":\"$decision\",\"section\":\"Technical Context\",\"line\":$line_num,\"context\":\"$context\"}")
                        break
                    fi
                done
            fi
        fi
    done < "$file"

    # Check if we found any decisions
    if [[ ${#decisions[@]} -eq 0 ]]; then
        error_exit 3 "No Technical Context section or decisions found in $file"
    fi

    # Output JSON array
    echo "["
    for i in "${!decisions[@]}"; do
        echo "  ${decisions[$i]}"
        if [[ $i -lt $((${#decisions[@]} - 1)) ]]; then
            echo ","
        fi
    done
    echo "]"
}

# Extract and output decisions
extract_decisions "$PLAN_FILE"

exit 0
