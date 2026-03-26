#!/usr/bin/env bash
# suggest-adrs.sh - Apply decision clustering and significance testing
#
# Usage:
#   suggest-adrs.sh --decisions decisions.json [--json]
#
# Input:
#   JSON array of decisions from extract-decisions.sh
#
# Output:
#   JSON array of ADR suggestions with clustered decisions and significance justification
#   [
#     {
#       "title": "Backend Technology Stack",
#       "decisions": ["Use FastAPI", "Use Python 3.11", "Use Pydantic"],
#       "cluster_type": "technology_stack",
#       "significance": {
#         "impact": true,
#         "tradeoffs": true,
#         "questioning": true,
#         "justification": "Explanation of why this meets all 3 criteria"
#       }
#     }
#   ]
#
# Exit Codes:
#   0 - Success
#   1 - Missing required input
#   2 - Invalid JSON input
#   3 - No significant decisions found

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/logging.sh"

# Default values
DECISIONS_INPUT=""
JSON_OUTPUT=true

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
        --decisions)
            DECISIONS_INPUT="$2"
            shift 2
            ;;
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        --help|-h)
            echo "Usage: suggest-adrs.sh --decisions decisions.json [--json]"
            echo ""
            echo "Options:"
            echo "  --decisions FILE Path to decisions JSON file (required)"
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
if [[ -z "$DECISIONS_INPUT" ]]; then
    error_exit 1 "Missing required argument: --decisions"
fi

# Read decisions file
if [[ ! -f "$DECISIONS_INPUT" ]]; then
    error_exit 2 "Decisions file not found: $DECISIONS_INPUT"
fi

DECISIONS_JSON=$(cat "$DECISIONS_INPUT")

# Verify JSON is valid
if ! echo "$DECISIONS_JSON" | jq empty 2>/dev/null; then
    error_exit 2 "Invalid JSON in decisions file: $DECISIONS_INPUT"
fi

# Apply clustering algorithm
cluster_decisions() {
    local decisions_json="$1"

    # Technology stack keywords (from research.md)
    local frontend_keywords="react|vue|angular|next|tailwind|css|vercel|netlify|typescript|javascript"
    local backend_keywords="express|fastapi|django|flask|orm|database|python|node|java|go|rust"
    local mobile_keywords="ios|android|swift|kotlin|react-native|flutter"
    local data_keywords="postgresql|mysql|mongodb|redis|elasticsearch|cache|migration"

    # Functional area keywords (from research.md)
    local auth_keywords="auth|login|session|jwt|oauth|token|password"
    local deployment_keywords="ci|cd|docker|kubernetes|hosting|deploy|pipeline"
    local testing_keywords="test|unit|integration|e2e|coverage|mock"
    local monitoring_keywords="log|metric|trace|alert|observability|apm"

    # Extract decisions and apply clustering
    local clusters='[]'

    # Check for frontend stack
    local frontend_decisions=$(echo "$decisions_json" | jq -r --arg keywords "$frontend_keywords" '[.[] | select(.decision | test($keywords; "i"))]')
    if [[ $(echo "$frontend_decisions" | jq 'length') -ge 2 ]]; then
        local frontend_cluster=$(cat <<EOF
{
  "title": "Frontend Technology Stack",
  "decisions": $(echo "$frontend_decisions" | jq '[.[].decision]'),
  "cluster_type": "technology_stack",
  "significance": {
    "impact": true,
    "tradeoffs": true,
    "questioning": true,
    "justification": "Frontend stack decisions affect multiple components, involve framework tradeoffs, and will be questioned by new developers."
  }
}
EOF
)
        clusters=$(echo "$clusters" | jq --argjson cluster "$frontend_cluster" '. + [$cluster]')
    fi

    # Check for backend stack
    local backend_decisions=$(echo "$decisions_json" | jq -r --arg keywords "$backend_keywords" '[.[] | select(.decision | test($keywords; "i"))]')
    if [[ $(echo "$backend_decisions" | jq 'length') -ge 2 ]]; then
        local backend_cluster=$(cat <<EOF
{
  "title": "Backend Technology Stack",
  "decisions": $(echo "$backend_decisions" | jq '[.[].decision]'),
  "cluster_type": "technology_stack",
  "significance": {
    "impact": true,
    "tradeoffs": true,
    "questioning": true,
    "justification": "Backend stack decisions impact system architecture, involve significant tradeoffs, and establish patterns for future work."
  }
}
EOF
)
        clusters=$(echo "$clusters" | jq --argjson cluster "$backend_cluster" '. + [$cluster]')
    fi

    # Check for data architecture
    local data_decisions=$(echo "$decisions_json" | jq -r --arg keywords "$data_keywords" '[.[] | select(.decision | test($keywords; "i"))]')
    if [[ $(echo "$data_decisions" | jq 'length') -ge 2 ]]; then
        local data_cluster=$(cat <<EOF
{
  "title": "Data Architecture",
  "decisions": $(echo "$data_decisions" | jq '[.[].decision]'),
  "cluster_type": "technology_stack",
  "significance": {
    "impact": true,
    "tradeoffs": true,
    "questioning": true,
    "justification": "Data architecture decisions affect persistence layer, caching strategy, and future scalability."
  }
}
EOF
)
        clusters=$(echo "$clusters" | jq --argjson cluster "$data_cluster" '. + [$cluster]')
    fi

    # Check for authentication approach
    local auth_decisions=$(echo "$decisions_json" | jq -r --arg keywords "$auth_keywords" '[.[] | select(.decision | test($keywords; "i"))]')
    if [[ $(echo "$auth_decisions" | jq 'length') -ge 2 ]]; then
        local auth_cluster=$(cat <<EOF
{
  "title": "Authentication Approach",
  "decisions": $(echo "$auth_decisions" | jq '[.[].decision]'),
  "cluster_type": "functional_area",
  "significance": {
    "impact": true,
    "tradeoffs": true,
    "questioning": true,
    "justification": "Authentication decisions affect security posture, user experience, and system integration patterns."
  }
}
EOF
)
        clusters=$(echo "$clusters" | jq --argjson cluster "$auth_cluster" '. + [$cluster]')
    fi

    # Check for deployment strategy
    local deployment_decisions=$(echo "$decisions_json" | jq -r --arg keywords "$deployment_keywords" '[.[] | select(.decision | test($keywords; "i"))]')
    if [[ $(echo "$deployment_decisions" | jq 'length') -ge 2 ]]; then
        local deployment_cluster=$(cat <<EOF
{
  "title": "Deployment Strategy",
  "decisions": $(echo "$deployment_decisions" | jq '[.[].decision]'),
  "cluster_type": "functional_area",
  "significance": {
    "impact": true,
    "tradeoffs": true,
    "questioning": true,
    "justification": "Deployment decisions affect CI/CD pipeline, hosting costs, and operational complexity."
  }
}
EOF
)
        clusters=$(echo "$clusters" | jq --argjson cluster "$deployment_cluster" '. + [$cluster]')
    fi

    # Process standalone decisions that don't fit clusters
    # For now, skip standalone decisions to avoid ADR proliferation
    # (Can be added in future if needed)

    echo "$clusters"
}

# Apply significance testing (3-criteria test)
apply_significance_test() {
    local clusters="$1"

    # Filter clusters that meet all 3 criteria (impact, tradeoffs, questioning)
    # In our clustering logic, all clusters already meet these criteria
    # so we pass them through unchanged
    echo "$clusters" | jq '[.[] | select(.significance.impact == true and .significance.tradeoffs == true and .significance.questioning == true)]'
}

# Apply cluster size validation
validate_cluster_sizes() {
    local clusters="$1"
    local MAX_CLUSTER_SIZE=10
    local TYPICAL_MIN=3
    local TYPICAL_MAX=5

    # Add cluster_size_warning field to clusters exceeding limits
    echo "$clusters" | jq --argjson max "$MAX_CLUSTER_SIZE" --argjson typical_min "$TYPICAL_MIN" --argjson typical_max "$TYPICAL_MAX" '
        [.[] | . as $cluster |
         ($cluster.decisions | length) as $size |
         if $size > $max then
            $cluster + {"cluster_size_warning": "Cluster has \($size) decisions. Consider splitting into multiple ADRs for better readability."}
         elif $size < $typical_min then
            $cluster + {"cluster_size_note": "Cluster has only \($size) decisions. This may not warrant a full ADR."}
         elif $size > $typical_max then
            $cluster + {"cluster_size_note": "Cluster has \($size) decisions. This is acceptable but approaching the upper limit."}
         else
            $cluster
         end
        ]'
}

# Cluster decisions
CLUSTERS=$(cluster_decisions "$DECISIONS_JSON")

# Apply significance test
TESTED_CLUSTERS=$(apply_significance_test "$CLUSTERS")

# Validate cluster sizes
SUGGESTIONS=$(validate_cluster_sizes "$TESTED_CLUSTERS")

# Check if we have any suggestions
if [[ $(echo "$SUGGESTIONS" | jq 'length') -eq 0 ]]; then
    error_exit 3 "No significant decisions found after clustering and significance testing"
fi

# Output suggestions
echo "$SUGGESTIONS"

exit 0
