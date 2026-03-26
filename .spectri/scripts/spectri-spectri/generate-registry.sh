#!/usr/bin/env bash

# generate-registry.sh
#
# Purpose: Auto-generate registry and roadmap files for Spectri
#
# Generates two markdown files:
#   - spectri/specs/_registry/specs.md - All specs grouped by status with phase tracking
#   - ROADMAP.md - Priority-ordered implementation plan
#
# Files regenerate automatically whenever meta.json files change.
#
# Usage: ./generate-registry.sh
#
# Note: This script is bash 3.x compatible (macOS default).
# Ported from zsh version on 2026-01-25.

set -euo pipefail

# Enable nullglob to handle empty globs gracefully
shopt -s nullglob

# Source shared libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/logging.sh"
source "$SCRIPT_DIR/../../lib/common.sh"

# Check for jq dependency
if ! command -v jq &> /dev/null; then
    echo -e "${RED}ERROR:${NC} jq is required but not installed." >&2
    echo "Install with: brew install jq (macOS) or apt-get install jq (Linux)" >&2
    exit 1
fi

# Configuration
REPO_ROOT=$(get_repo_root)
REGISTRY_DIR="${REPO_ROOT}/spectri/specs/_registry"
ROADMAP_FILE="${REPO_ROOT}/spectri/specs/ROADMAP.md"
PRIORITY_FILE="${REPO_ROOT}/.spectri/manifests/roadmap.json"

# Create registry directory if it doesn't exist
mkdir -p "$REGISTRY_DIR"

# Create temp directory for file-based aggregation (bash 3.x lacks associative arrays)
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Get current timestamp in ISO 8601 format with timezone
get_timestamp() {
    date "+%Y-%m-%dT%H:%M:%S%z" | sed 's/\([0-9][0-9]\)$/:\1/'
}

# Derive workflow phase from document status fields
derive_phase() {
    local meta_file="$1"
    local lifecycle_status=$(jq -r '.status // "draft"' "$meta_file")

    # Check deployed/archived first
    if [[ "$lifecycle_status" == "deployed" ]]; then echo "deployed"; return; fi
    if [[ "$lifecycle_status" == "archived" ]]; then echo "archived"; return; fi

    # Check document statuses (up-to-date and complete both count as done)
    local spec_status=$(jq -r '.documents["spec.md"].status // "missing"' "$meta_file")
    local plan_status=$(jq -r '.documents["plan.md"].status // "missing"' "$meta_file")
    local tasks_status=$(jq -r '.documents["tasks.md"].status // "missing"' "$meta_file")

    # Derive phase from document completeness
    if [[ "$spec_status" == "missing" ]] || [[ "$spec_status" != "complete" && "$spec_status" != "up-to-date" ]]; then echo "specification"; return; fi
    if [[ "$plan_status" == "missing" ]] || [[ "$plan_status" != "complete" && "$plan_status" != "up-to-date" ]]; then echo "planning"; return; fi
    if [[ "$tasks_status" == "missing" ]] || [[ "$tasks_status" != "complete" && "$tasks_status" != "up-to-date" ]]; then echo "tasking"; return; fi

    # All docs complete - check lifecycle status
    if [[ "$lifecycle_status" == "in-progress" ]]; then echo "implementing"; return; fi
    echo "ready-to-implement"
}

# Derive title from folder name if not in meta.json
# E.g., "042-issue-management-skill" → "Issue Management Skill"
derive_title_from_folder() {
    local folder_name="$1"
    # Remove leading spec number (001-, 042-, etc.)
    local name_part=$(echo "$folder_name" | sed 's/^[0-9]\{3\}-//')
    # Replace hyphens with spaces and title case each word
    echo "$name_part" | tr '-' ' ' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1'
}

# Extract spec ID from folder path
get_spec_id() {
    local folder="$1"
    basename "$folder" | grep -oE '^[0-9]{3}' || echo "???"
}

# Format date for display (YYYY-MM-DD)
format_date() {
    local iso_date="$1"
    echo "$iso_date" | cut -d'T' -f1
}

# Count blockers in meta.json
count_blockers() {
    local meta_file="$1"
    jq -r '.blockers // [] | length' "$meta_file"
}

# Discover all spec meta.json files and write to temp files by status
discover_specs() {
    # Clear any existing temp files
    rm -f "$TEMP_DIR"/spec_status_*.txt

    # Scan all stage-based folders
    local stage_folders=(
        "00-backlog"
        "01-drafting"
        "02-implementing"
        "03-blocked"
        "04-deployed"
        "05-archived"
    )

    for stage in "${stage_folders[@]}"; do
        local stage_path="$REPO_ROOT/spectri/specs/$stage"
        if [[ -d "$stage_path" ]]; then
            for meta_file in "$stage_path"/*/meta.json; do
                if [[ -f "$meta_file" ]]; then
                    local spec_status=$(jq -r '.status // "draft"' "$meta_file" 2>/dev/null || echo "unknown")
                    echo "$meta_file" >> "$TEMP_DIR/spec_status_${spec_status}.txt"
                fi
            done
        fi
    done

    # Backward compatibility: also scan old flat structure if it exists
    for meta_file in "$REPO_ROOT"/spectri/specs/*/meta.json; do
        # Skip if it's in a stage folder (already scanned above)
        if [[ ! "$meta_file" =~ /spectri/specs/0[0-5]- ]]; then
            if [[ -f "$meta_file" ]]; then
                local spec_status=$(jq -r '.status // "draft"' "$meta_file" 2>/dev/null || echo "unknown")
                echo "$meta_file" >> "$TEMP_DIR/spec_status_${spec_status}.txt"
            fi
        fi
    done
}

# Generate specs registry
generate_specs_registry() {
    echo -e "${BLUE}INFO:${NC} Generating specs registry..." >&2
    local output_file="${REGISTRY_DIR}/specs.md"
    local timestamp=$(get_timestamp)

    # First discover all specs
    discover_specs

    cat > "$output_file" <<EOF
# Spec Registry

> Last generated: $timestamp by generate-registry.sh

This registry shows all specs grouped by lifecycle status. The **Phase** column indicates workflow progress:

- **specification**: Writing spec.md
- **planning**: spec.md done, writing plan.md
- **tasking**: plan.md done, writing tasks.md
- **ready-to-implement**: All docs complete, awaiting implementation
- **implementing**: In active development
- **deployed**: Feature complete and released
- **archived**: Deprecated or superseded

EOF

    # Generate tables for each status
    local statuses=("draft" "in-progress" "deployed" "archived")
    local status_labels=("Draft" "In Progress" "Deployed" "Archived")

    local i=0
    while [[ $i -lt ${#statuses[@]} ]]; do
        local current_status="${statuses[$i]}"
        local label="${status_labels[$i]}"

        echo "" >> "$output_file"
        echo "## $label" >> "$output_file"
        echo "" >> "$output_file"
        echo "| ID | Name | Phase | Created | Updated | Blockers |" >> "$output_file"
        echo "|----|------|-------|---------|---------|----------|" >> "$output_file"

        # Check if temp file exists for this status
        local temp_file="$TEMP_DIR/spec_status_${current_status}.txt"
        local found=false

        if [[ -f "$temp_file" ]]; then
            while IFS= read -r meta_file; do
                if [[ -f "$meta_file" ]]; then
                    found=true
                    local spec_dir=$(dirname "$meta_file")
                    local spec_name=$(basename "$spec_dir")
                    local spec_id=$(get_spec_id "$spec_dir")
                    local title=$(jq -r '.title // null' "$meta_file")
                    # Fallback to derived title from folder name if no title in meta.json
                    if [[ "$title" == "null" || -z "$title" ]]; then
                        title=$(derive_title_from_folder "$spec_name")
                    fi
                    local phase=$(derive_phase "$meta_file")
                    local created=$(jq -r '.created // "N/A"' "$meta_file" | cut -d'T' -f1)
                    local updated=$(jq -r '.last_updated // .created // "N/A"' "$meta_file" | cut -d'T' -f1)
                    local blockers=$(count_blockers "$meta_file")

                    # Create relative link to spec folder - include stage folder for stage-based layout
                    # Extract actual stage folder from path (e.g., "01-drafting", "04-deployed")
                    local stage_folder=$(basename "$(dirname "$spec_dir")")
                    local rel_path
                    if [[ "$stage_folder" =~ ^0[0-5]- ]]; then
                        rel_path="../${stage_folder}/${spec_name}/"
                    else
                        # Backward compat: flat structure (no stage folder)
                        rel_path="../${spec_name}/"
                    fi

                    echo "| $spec_id | [$title]($rel_path) | $phase | $created | $updated | $blockers |" >> "$output_file"
                fi
            done < "$temp_file"
        fi

        if [[ "$found" == "false" ]]; then
            echo "| - | - | - | - | - | - |" >> "$output_file"
        fi

        i=$((i + 1))
    done

    echo "" >> "$output_file"
    echo -e "${GREEN}SUCCESS:${NC} Generated $output_file" >&2
}

# Generate ROADMAP.md from priority list
generate_roadmap() {
    echo -e "${BLUE}INFO:${NC} Generating roadmap..." >&2
    local timestamp=$(get_timestamp)

    # Check if priority file exists
    if [[ ! -f "$PRIORITY_FILE" ]]; then
        echo -e "${YELLOW}WARNING:${NC} Priority file not found at $PRIORITY_FILE" >&2
        echo "Skipping ROADMAP.md generation" >&2
        return
    fi

    cat > "$ROADMAP_FILE" <<EOF
---
Date Created: $timestamp
Date Updated: $timestamp
Purpose: Spec implementation priority order for agents
---

# Spectri Roadmap

**This document contains ONLY future specs in priority order.**

When starting new work, agents should check this file to determine which spec to work on next. Implemented features are documented in [CHANGELOG.md](CHANGELOG.md).

**This file is auto-generated from \`.spectri/manifests/roadmap.json\` and spec meta.json files.**
**To update priorities:** Edit \`.spectri/manifests/roadmap.json\` (or use \`jq\` for programmatic updates) and run \`.spectri/scripts/spectri-spectri/generate-registry.sh\`

---

| Priority | Spec | Description | Stage | Dependencies |
|----------|------|-------------|-------|--------------|
EOF

    local priority=1

    # Read priority list from JSON and build roadmap
    local spec_nums
    spec_nums=$(jq -r '.roadmap[]' "$PRIORITY_FILE" 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        echo "WARNING: Failed to parse JSON from $PRIORITY_FILE" >&2
        echo "Skipping ROADMAP.md generation" >&2
        return
    fi

    # Process each spec number from the JSON array
    while IFS= read -r spec_num; do
        # Skip if spec_num is empty
        [[ -z "$spec_num" ]] && continue

        # Find meta.json for this spec (skip if in deployed/archived)
        local meta_file=""
        for f in "$REPO_ROOT"/spectri/specs/${spec_num}-*/meta.json; do
            if [[ -f "$f" ]] && [[ "$f" != *"/deployed/"* ]] && [[ "$f" != *"/archived/"* ]]; then
                meta_file="$f"
                break
            fi
        done

        # Skip if not found or in deployed/archived
        if [[ -z "$meta_file" ]] || [[ "$meta_file" =~ /deployed/ ]] || [[ "$meta_file" =~ /archived/ ]]; then
            continue
        fi

        # Extract metadata
        local title=$(jq -r '.title // null' "$meta_file")
        local description=$(jq -r '.description // "N/A"' "$meta_file")
        local spec_lifecycle_status=$(jq -r '.status // "draft"' "$meta_file")

        # Get spec folder name from meta_file path
        local spec_folder=$(basename "$(dirname "$meta_file")")
        # Fallback to derived title from folder name if no title in meta.json
        if [[ "$title" == "null" || -z "$title" ]]; then
            title=$(derive_title_from_folder "$spec_folder")
        fi

        # Extract dependencies from related_specs
        local deps=$(jq -r '.related_specs // [] | join(", ")' "$meta_file")
        [[ -z "$deps" ]] && deps="-"

        # Build table row with markdown link
        echo "| $priority | [$spec_folder]($spec_folder/) | $description | $spec_lifecycle_status | $deps |" >> "$ROADMAP_FILE"

        ((priority++))
    done <<< "$spec_nums"

    cat >> "$ROADMAP_FILE" <<EOF

---

**Last updated:** $timestamp by generate-registry.sh
EOF
    echo -e "${GREEN}SUCCESS:${NC} Generated $ROADMAP_FILE" >&2
}

# Main execution
main() {
    echo -e "${BLUE}INFO:${NC} Starting registry generation..." >&2

    generate_specs_registry

    generate_roadmap

    echo -e "${GREEN}SUCCESS:${NC} Registry generation complete!" >&2
}

# Run main function
main "$@"
