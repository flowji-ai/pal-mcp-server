#!/usr/bin/env bash
# create-thread.sh - Create Thread files for unfinished work
#
# Usage:
#   create-thread.sh --title "Title" --context <context> [--spec <spec>] [--json]
#
# Exit codes:
#   0 - Success
#   1 - Invalid arguments
#   2 - Spec required but not found
#   3 - Template missing
#   4 - Filesystem error

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/logging.sh"
source "$SCRIPT_DIR/../../lib/timestamp-utils.sh"
source "$SCRIPT_DIR/../../lib/filename-utils.sh"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
TEMPLATE_PATH="$PROJECT_ROOT/.spectri/templates/spectri-trail/thread-template.md"
THREADS_BASE="$PROJECT_ROOT/spectri/coordination/threads"

# Valid contexts
VALID_CONTEXTS=("constitution" "spec-specific" "general")

# Contexts that require a spec
SPEC_REQUIRED_CONTEXTS=("spec-specific")

# ============================================================================
# Utility Functions
# ============================================================================

error() {
    log_error "$*"
}

usage() {
    cat <<EOF
Usage: create-thread.sh --title "Title" --context <context> [--spec <spec>] [--json]

Options:
  --title    Title for the thread (required, 3-7 words describing unfinished work)
  --context  Work context (required): constitution, spec-specific, general
  --spec     Spec identifier (e.g., 025-command-enhancements). Auto-detected if not provided.
  --json     Output result as JSON

Contexts:
  constitution  - Project setup and principles work (before specs exist) → spectri/coordination/threads/constitution/
  spec-specific - Work tied to a specific feature/spec → spectri/coordination/threads/NNN-spec-name/
  general       - Cross-cutting work not tied to a specific spec or constitution → spectri/coordination/threads/general/

Spec Detection (for spec-specific context):
  1. --spec argument (explicit)
  2. SPECIFY_SPEC environment variable
  3. Current directory (if inside spectri/specs/NNN-*/)
  4. Current git branch name (if matches NNN-spec-name)
  5. Error if none found

Examples:
  create-thread.sh --title "Update plan command improvements" --context spec-specific --spec 025-command-enhancements
  create-thread.sh --title "Define security principles" --context constitution
  create-thread.sh --title "Review feature ideas triage" --context general
EOF
}


# Validate context argument
validate_context() {
    local context="$1"
    for valid_context in "${VALID_CONTEXTS[@]}"; do
        if [[ "$context" == "$valid_context" ]]; then
            return 0
        fi
    done
    error "Invalid context: $context"
    error "Valid contexts: ${VALID_CONTEXTS[*]}"
    return 1
}

# Get routing directory for context
get_route_for_context() {
    local context="$1"
    case "$context" in
        constitution)
            echo "constitution"
            ;;
        spec-specific)
            echo "spec"
            ;;
        general)
            echo "general"
            ;;
        *)
            error "Unknown context: $context"
            return 1
            ;;
    esac
}

# Check if context requires a spec
context_requires_spec() {
    local context="$1"
    for required_context in "${SPEC_REQUIRED_CONTEXTS[@]}"; do
        if [[ "$context" == "$required_context" ]]; then
            return 0
        fi
    done
    return 1
}

# Detect spec from various sources
detect_spec() {
    local spec=""

    # 1. Check SPECIFY_SPEC environment variable
    if [[ -n "${SPECIFY_SPEC:-}" ]]; then
        spec="$SPECIFY_SPEC"
        echo "$spec"
        return 0
    fi

    # 2. Check if we're inside a spectri/specs/ directory
    local cwd="$PWD"
    if [[ "$cwd" == *"/spectri/specs/"* ]]; then
        # Extract spec identifier from path
        if [[ "$cwd" =~ /spectri/specs/(deployed/)?([0-9]{3}-[^/]+) ]]; then
            spec="${BASH_REMATCH[2]}"
            echo "$spec"
            return 0
        fi
    fi

    # 3. Check current git branch (if in git repo)
    if git rev-parse --git-dir >/dev/null 2>&1; then
        local branch
        branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
        if [[ "$branch" =~ ^[0-9]{3}- ]]; then
            # Branch starts with NNN- format
            spec="$branch"
            echo "$spec"
            return 0
        fi
    fi

    # No spec found
    return 1
}

# ============================================================================
# Main Logic
# ============================================================================

main() {
    local title=""
    local context=""
    local spec=""
    local spec_explicit=""
    local json_output=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --title)
                title="$2"
                shift 2
                ;;
            --context)
                context="$2"
                shift 2
                ;;
            --spec)
                spec="$2"
                spec_explicit="$2"
                shift 2
                ;;
            --json)
                json_output=true
                shift
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    # Validate required arguments
    if [[ -z "$title" ]]; then
        error "Missing required argument: --title"
        usage
        exit 1
    fi

    if [[ -z "$context" ]]; then
        error "Missing required argument: --context"
        usage
        exit 1
    fi

    # Validate context
    if ! validate_context "$context"; then
        exit 1
    fi

    # Detect spec if not explicitly provided
    if [[ -z "$spec_explicit" ]]; then
        if context_requires_spec "$context"; then
            if ! spec="$(detect_spec)"; then
                error "Context '$context' requires a spec, but none could be detected"
                error "Provide --spec explicitly or ensure you're inside a spectri/specs/ directory"
                exit 2
            fi
        fi
    fi

    # Determine routing directory
    local route
    route="$(get_route_for_context "$context")"
    local target_dir="$THREADS_BASE/$route"

    # For spec-specific context, use spec identifier as subdirectory
    if [[ "$route" == "spec" ]] && [[ -n "$spec" ]]; then
        target_dir="$THREADS_BASE/$spec"
    fi

    # Create target directory if it doesn't exist
    if ! mkdir -p "$target_dir"; then
        error "Failed to create directory: $target_dir"
        exit 4
    fi

    # Check template exists
    if [[ ! -f "$TEMPLATE_PATH" ]]; then
        error "Template not found: $TEMPLATE_PATH"
        exit 3
    fi

    # Get current date
    local date_prefix
    date_prefix="$(get_date_timestamp)"

    # Create slug from title
    local slug
    slug="$(slugify "$title")"

    # Create filename: YYYY-MM-DD-title-slug.md
    local filename="${date_prefix}-${slug}.md"
    local filepath="$target_dir/$filename"

    # Copy template and substitute placeholders
    local full_date
    full_date="$(get_iso_timestamp)"
    local content
    content=$(cat "$TEMPLATE_PATH")
    content=$(echo "$content" | sed "s|{{TITLE}}|${title}|g")
    content=$(echo "$content" | sed "s|{{DATE_ISO}}|${full_date}|g")
    content=$(echo "$content" | sed "s|{{CONTEXT}}|${context}|g")
    content=$(echo "$content" | sed "s|{{SPEC}}|${spec:-none}|g")
    content=$(echo "$content" | sed "s|{{AGENT_SESSION_ID}}|${AGENT_SESSION_ID:-unknown}|g")
    content=$(echo "$content" | sed "s|{{USER}}|${USER:-unknown}|g")
    if ! echo "$content" > "$filepath"; then
        error "Failed to write thread file: $filepath"
        exit 4
    fi

    # Output result
    if $json_output; then
        cat <<EOF
{
  "filename": "$filename",
  "path": "$filepath",
  "context": "$context",
  "spec": "${spec:-none}"
}
EOF
    else
        echo "✅ Thread created successfully"
        echo ""
        echo "Filename: $filename"
        echo "Path: $filepath"
        echo "Context: $context"
        if [[ -n "$spec" ]]; then
            echo "Spec: $spec"
        fi
        echo ""
        echo "Next steps:"
        echo "1. Open the file and fill in all sections:"
        echo "   - What Was Being Attempted"
        echo "   - Unfinished Business"
        echo "   - Open Questions"
        echo "   - Decisions Pending"
        echo "   - Next Actions"
        echo "2. Save when complete"
        echo "3. When work resumes and completes, update frontmatter and rename to .md.resolved"
    fi
}

# Run main
main "$@"
