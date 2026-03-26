#!/usr/bin/env bash
# create-llm-plan.sh - Copy an LLM plan into the spectri llm-plans directory
#
# Copies a plan from its original location (e.g. ~/.claude/plans/) into
# spectri/coordination/llm-plans/ with agent name embedded in the filename.
#
# Usage:
#   create-llm-plan.sh --title "Plan Title" --slug "plan-slug" --original "~/.claude/plans/foo.md" --agent claude [options] [--json]
#
# Exit codes:
#   0 - Success
#   1 - Invalid arguments
#   2 - Source file not found
#   3 - Filesystem error

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/logging.sh"
source "$SCRIPT_DIR/../../lib/timestamp-utils.sh"
source "$SCRIPT_DIR/../../lib/filename-utils.sh"
source "$SCRIPT_DIR/../../lib/common.sh"

REPO_ROOT="$(get_repo_root)"
PLANS_BASE="$REPO_ROOT/spectri/coordination/llm-plans"

VALID_AGENTS=("claude" "qwen" "gemini" "opencode")

# ============================================================================
# Utility Functions
# ============================================================================

usage() {
    cat <<EOF
Usage: create-llm-plan.sh --title "Title" --slug "slug" --original "/path/to/plan.md" --agent <agent> [options] [--json]

Required:
  --title      Plan title
  --slug       Kebab-case slug for filename (e.g., "speckit-command-drift-review")
  --original   Path to the original plan file (will be copied, not moved)
  --agent      Agent that created the plan: claude, qwen, gemini, opencode

Optional:
  --source     Prompt file that initiated this plan (relative path from repo root)
  --workstream Workstream info (e.g., "1 of 3 (Series Name)")
  --reviewed-by Review info (e.g., "4 sub-agents (3 explore, 1 plan review)")
  --json       Output result as JSON

Examples:
  create-llm-plan.sh --title "SpecKit Command Drift Review" --slug "speckit-command-drift-review" \\
    --original "~/.claude/plans/tingly-tinkering-seal.md" --agent claude \\
    --source "spectri/coordination/prompts/2026-02-18-fix-script-and-template-drift.md" \\
    --workstream "1 of 1 (SpecKit Command Drift Review)" \\
    --reviewed-by "4 sub-agents (3 explore, 1 plan review)"

Output:
  New plans are created at spectri/coordination/llm-plans/YYYY-MM-DD-{agent}-{slug}.md
  Agent subfolders ({agent}-plans/) are retained for raw native plan archives only.
EOF
}

validate_agent() {
    local agent="$1"
    for valid_agent in "${VALID_AGENTS[@]}"; do
        if [[ "$agent" == "$valid_agent" ]]; then
            return 0
        fi
    done
    log_error "Invalid agent: $agent"
    log_error "Valid agents: ${VALID_AGENTS[*]}"
    return 1
}

# Extract body from a markdown file (everything after frontmatter)
# Frontmatter is delimited by --- on first line and next ---
extract_body() {
    local file="$1"
    local in_frontmatter=false
    local frontmatter_ended=false
    local line_num=0

    while IFS= read -r line; do
        line_num=$((line_num + 1))
        if [[ $line_num -eq 1 ]] && [[ "$line" == "---" ]]; then
            in_frontmatter=true
            continue
        fi
        if $in_frontmatter && [[ "$line" == "---" ]]; then
            frontmatter_ended=true
            continue
        fi
        if $frontmatter_ended || ! $in_frontmatter; then
            echo "$line"
        fi
    done < "$file"
}

# ============================================================================
# Main Logic
# ============================================================================

main() {
    local title=""
    local slug=""
    local original=""
    local agent=""
    local source_prompt=""
    local workstream=""
    local reviewed_by=""
    local json_output=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --title)
                title="$2"
                shift 2
                ;;
            --slug)
                slug="$2"
                shift 2
                ;;
            --original)
                original="$2"
                shift 2
                ;;
            --agent)
                agent="$2"
                shift 2
                ;;
            --source)
                source_prompt="$2"
                shift 2
                ;;
            --workstream)
                workstream="$2"
                shift 2
                ;;
            --reviewed-by)
                reviewed_by="$2"
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
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    # Validate required arguments
    if [[ -z "$title" ]]; then
        log_error "Missing required argument: --title"
        usage
        exit 1
    fi

    if [[ -z "$slug" ]]; then
        log_error "Missing required argument: --slug"
        usage
        exit 1
    fi

    if [[ -z "$original" ]]; then
        log_error "Missing required argument: --original"
        usage
        exit 1
    fi

    if [[ -z "$agent" ]]; then
        log_error "Missing required argument: --agent"
        usage
        exit 1
    fi

    # Validate agent
    if ! validate_agent "$agent"; then
        exit 1
    fi

    # Expand ~ in original path
    original="${original/#\~/$HOME}"

    # Validate source file exists
    if [[ ! -f "$original" ]]; then
        log_error "Original plan file not found: $original"
        exit 2
    fi

    # Target directory is root llm-plans/ (not agent subfolder)
    local target_dir="$PLANS_BASE"

    # Create target directory if it doesn't exist
    if ! mkdir -p "$target_dir"; then
        log_error "Failed to create directory: $target_dir"
        exit 3
    fi

    # Generate filename
    local date_prefix
    date_prefix="$(get_date_timestamp)"
    local filename="${date_prefix}-${agent}-${slug}.md"
    local filepath="$target_dir/$filename"

    # Check if file already exists
    if [[ -f "$filepath" ]]; then
        log_error "Plan file already exists: $filepath"
        exit 3
    fi

    # Get timestamps
    local now
    now="$(get_iso_timestamp)"

    # Build frontmatter
    local frontmatter="---
Date Created: $now
Date Updated: $now
Title: $title
Original: $original"

    if [[ -n "$source_prompt" ]]; then
        frontmatter+="
Source: $source_prompt"
    fi

    if [[ -n "$workstream" ]]; then
        frontmatter+="
Workstream: $workstream"
    fi

    if [[ -n "$reviewed_by" ]]; then
        frontmatter+="
Reviewed By: $reviewed_by"
    fi

    frontmatter+="
---"

    # Extract body from original plan (strip its frontmatter)
    local body
    body="$(extract_body "$original")"

    # Write the new plan file
    {
        echo "$frontmatter"
        echo "$body"
    } > "$filepath" || {
        log_error "Failed to write plan file: $filepath"
        exit 3
    }

    # Stage the file
    if has_git; then
        git add "$filepath" 2>/dev/null || true
    fi

    # Output result
    local relative_path="${filepath#$REPO_ROOT/}"

    if $json_output; then
        cat <<EOF
{
  "filename": "$filename",
  "path": "$filepath",
  "relative_path": "$relative_path",
  "agent": "$agent",
  "original": "$original",
  "title": "$title"
}
EOF
    else
        echo "LLM plan created successfully"
        echo ""
        echo "Filename: $filename"
        echo "Path: $relative_path"
        echo "Agent: $agent"
        echo "Original: $original"
        echo ""
        echo "Original plan in ~/.claude/plans/ stays unchanged."
    fi
}

# Run main
main "$@"
