#!/usr/bin/env bash
#
# find-related-artifacts.sh - Find coordination artifacts related to an issue
#
# Given an issue file, finds threads, prompts, and LLM plans that reference
# the issue or its related specs. For multi-issue artifacts, reports whether
# all referenced issues are resolved.
# Read-only: searches and reports only, never modifies files.
#
# Usage:
#   find-related-artifacts.sh --file <issue-file>          # Human-readable
#   find-related-artifacts.sh --file <issue-file> --json   # JSON output
#   find-related-artifacts.sh --help                       # Show this help
#
# Exit codes:
#   0 - Success (matches or no matches)
#   1 - Bad arguments
#   2 - File not found

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/logging.sh"
source "$SCRIPT_DIR/../../lib/common.sh"

# --- Cleanup ---
TMPDIR_ART=""
cleanup() {
    local exit_code=$?
    if [ -n "$TMPDIR_ART" ] && [ -d "$TMPDIR_ART" ]; then
        rm -rf "$TMPDIR_ART"
    fi
    exit $exit_code
}
trap cleanup EXIT INT TERM

# --- Defaults ---
INPUT_FILE=""
JSON_MODE=false

# --- Parse arguments ---
while [ $# -gt 0 ]; do
    case "$1" in
        --file)
            if [ $# -lt 2 ]; then
                log_error "--file requires a value"
                exit 1
            fi
            INPUT_FILE="$2"
            shift
            ;;
        --json)
            JSON_MODE=true
            ;;
        --help|-h)
            sed -n '3,16p' "$0" | sed 's/^# \?//'
            exit 0
            ;;
        *)
            log_error "Unknown argument '$1'"
            echo "Usage: $0 --file <issue-file> [--json]"
            exit 1
            ;;
    esac
    shift
done

# --- Validate ---
if [ -z "$INPUT_FILE" ]; then
    log_error "--file is required"
    echo "Usage: $0 --file <issue-file> [--json]"
    exit 1
fi

REPO_ROOT=$(get_repo_root)

# Resolve relative paths
if [[ "$INPUT_FILE" != /* ]]; then
    INPUT_FILE="$REPO_ROOT/$INPUT_FILE"
fi

if [ ! -f "$INPUT_FILE" ]; then
    log_error "File not found: $INPUT_FILE"
    exit 2
fi

TMPDIR_ART=$(mktemp -d)
RESULTS_FILE="$TMPDIR_ART/results"
touch "$RESULTS_FILE"

# --- Extract search terms ---
issue_basename=$(basename "$INPUT_FILE")
# Strip date prefix and .md extension for slug
issue_slug=$(echo "$issue_basename" | sed 's/^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-//' | sed 's/\.md$//')

# Parse related_specs from frontmatter (reuse parser from find-related-specs)
parse_frontmatter_array() {
    local file="$1"
    local field="$2"
    local in_frontmatter=false
    local frontmatter_ended=false
    local found_field=false
    local values=""

    while IFS= read -r line; do
        if [ "$frontmatter_ended" = "true" ]; then
            break
        fi
        if [ "$line" = "---" ]; then
            if [ "$in_frontmatter" = "true" ]; then
                frontmatter_ended=true
                continue
            else
                in_frontmatter=true
                continue
            fi
        fi
        if [ "$in_frontmatter" != "true" ]; then
            continue
        fi

        if [ "$found_field" = "true" ]; then
            case "$line" in
                "  - "* | "  -"*)
                    local val
                    val=$(echo "$line" | sed 's/^[[:space:]]*-[[:space:]]*//' | sed 's/^["'"'"']//;s/["'"'"']$//')
                    if [ -n "$val" ]; then
                        values="$values $val"
                    fi
                    continue
                    ;;
                *)
                    found_field=false
                    ;;
            esac
        fi

        case "$line" in
            "${field}:"*)
                found_field=true
                local rest
                rest=$(echo "$line" | sed "s/^${field}:[[:space:]]*//")
                if [ "$rest" = "[]" ] || [ -z "$rest" ]; then
                    continue
                fi
                rest=$(echo "$rest" | sed 's/^\[//;s/\]$//')
                local IFS=","
                for item in $rest; do
                    local clean
                    clean=$(echo "$item" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/^["'"'"']//;s/["'"'"']$//')
                    if [ -n "$clean" ]; then
                        values="$values $clean"
                    fi
                done
                ;;
        esac
    done < "$file"

    echo "$values"
}

related_specs=$(parse_frontmatter_array "$INPUT_FILE" "related_specs")

# Build search terms: issue filename, slug, spec names, spec numbers
search_terms="$issue_basename $issue_slug"
for spec in $related_specs; do
    search_terms="$search_terms $spec"
    # Extract numeric prefix if present
    spec_num=$(echo "$spec" | grep -oE '^[0-9]+' || true)
    if [ -n "$spec_num" ]; then
        # Only add if 3+ digits to avoid false positives
        if [ ${#spec_num} -ge 3 ]; then
            search_terms="$search_terms $spec_num"
        fi
    fi
done

# Files to exclude from search
EXCLUDE_FILES="AGENTS.md CLAUDE.md GEMINI.md QWEN.md SPECTRI.md"

# --- Extract status from frontmatter ---
get_status() {
    local file="$1"
    local in_frontmatter=false
    local status=""

    while IFS= read -r line; do
        if [ "$line" = "---" ]; then
            if [ "$in_frontmatter" = "true" ]; then
                break
            else
                in_frontmatter=true
                continue
            fi
        fi
        if [ "$in_frontmatter" != "true" ]; then
            continue
        fi
        # Check both lowercase and capitalized
        case "$line" in
            status:*|Status:*)
                status=$(echo "$line" | sed 's/^[sS]tatus:[[:space:]]*//' | sed 's/^["'"'"']//;s/["'"'"']$//')
                ;;
        esac
    done < "$file"

    echo "$status"
}

# --- Check if an issue is resolved ---
is_issue_resolved() {
    local issue_ref="$1"
    # Check if it exists in resolved/ or doesn't exist in open issues
    if ls "$REPO_ROOT/spectri/issues/resolved/"*"$issue_ref"* >/dev/null 2>&1; then
        echo "true"
    elif ls "$REPO_ROOT/spectri/issues/"*"$issue_ref"*.md >/dev/null 2>&1; then
        echo "false"
    else
        # Can't find it at all — treat as resolved (not blocking)
        echo "true"
    fi
}

# --- Search a directory for matches ---
search_directory() {
    local search_dir="$1"
    local artifact_type="$2"
    local resolve_cmd="$3"

    [ ! -d "$search_dir" ] && return

    # Find .md files, excluding resolved/ subdirectories and metadata files
    find "$search_dir" -name "*.md" -not -path "*/resolved/*" 2>/dev/null | while IFS= read -r artifact_file; do
        artifact_basename=$(basename "$artifact_file")

        # Skip metadata files
        skip=false
        for excl in $EXCLUDE_FILES; do
            if [ "$artifact_basename" = "$excl" ]; then
                skip=true
                break
            fi
        done
        [ "$skip" = "true" ] && continue

        # Search for any of our terms in this file
        matched_term=""
        for term in $search_terms; do
            if grep -q "$term" "$artifact_file" 2>/dev/null; then
                matched_term="$term"
                break
            fi
        done

        [ -z "$matched_term" ] && continue

        # Get status
        status=$(get_status "$artifact_file")

        # Skip resolved/completed/implemented artifacts
        case "$status" in
            resolved|completed|implemented) continue ;;
        esac

        # For prompts and plans: check if all referenced issues are resolved
        safe_to_resolve=""
        issue_refs=""
        if [ "$artifact_type" = "prompt" ] || [ "$artifact_type" = "plan" ]; then
            # Extract issue references from body (filenames matching YYYY-MM-DD-slug pattern)
            issue_refs=$(grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}-[a-z0-9-]+' "$artifact_file" 2>/dev/null | sort -u || true)
            if [ -n "$issue_refs" ]; then
                all_resolved=true
                while IFS= read -r ref; do
                    [ -z "$ref" ] && continue
                    resolved=$(is_issue_resolved "$ref")
                    if [ "$resolved" = "false" ] && [ "$ref" != "$issue_slug" ]; then
                        all_resolved=false
                    fi
                done <<< "$issue_refs"

                # The current issue counts as "about to be resolved"
                if [ "$all_resolved" = "true" ]; then
                    safe_to_resolve="YES"
                else
                    safe_to_resolve="NO"
                fi
            fi
        fi

        artifact_rel="${artifact_file#$REPO_ROOT/}"

        # Write result to file
        printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
            "$artifact_type" "$artifact_rel" "${status:-unknown}" \
            "$matched_term" "${safe_to_resolve:-}" "$resolve_cmd" \
            >> "$RESULTS_FILE"
    done
}

# --- Search coordination directories ---
COORD_DIR="$REPO_ROOT/spectri/coordination"

search_directory "$COORD_DIR/threads" "thread" "resolve-thread.sh"
search_directory "$COORD_DIR/prompts" "prompt" "resolve-prompt.sh --status implemented"
search_directory "$COORD_DIR/llm-plans" "plan" ""

# --- Output ---
result_count=0
if [ -f "$RESULTS_FILE" ]; then
    result_count=$(wc -l < "$RESULTS_FILE" | tr -d ' ')
fi

if $JSON_MODE; then
    printf '['

    first=true
    if [ "$result_count" -gt 0 ]; then
        while IFS=$'\t' read -r a_type a_path a_status a_match a_safe a_cmd; do
            if [ "$first" = "true" ]; then
                first=false
            else
                printf ','
            fi
            printf '{"type":"%s","path":"%s","status":"%s","matched_on":"%s"' \
                "$a_type" "$a_path" "$a_status" "$a_match"
            if [ -n "$a_safe" ]; then
                if [ "$a_safe" = "YES" ]; then
                    printf ',"safe_to_resolve":true'
                else
                    printf ',"safe_to_resolve":false'
                fi
            fi
            if [ -n "$a_cmd" ]; then
                printf ',"resolve_command":"%s"' "$a_cmd"
            fi
            printf '}'
        done < "$RESULTS_FILE"
    fi

    printf ']\n'
else
    if [ "$result_count" -eq 0 ]; then
        log_info "No matching artifacts found."
    else
        echo "Matching artifacts:"
        echo ""

        while IFS=$'\t' read -r a_type a_path a_status a_match a_safe a_cmd; do
            case "$a_type" in
                thread) echo "  Thread: $a_path" ;;
                prompt) echo "  Prompt: $a_path" ;;
                plan)   echo "  Plan: $a_path" ;;
            esac
            echo "    Status: $a_status"
            echo "    Matched on: \"$a_match\""
            if [ -n "$a_safe" ]; then
                echo "    All issues resolved: $a_safe — $([ "$a_safe" = "YES" ] && echo "safe to resolve" || echo "not safe to resolve")"
            fi
            if [ -n "$a_cmd" ]; then
                echo "    Action: resolve with $a_cmd"
            fi
            echo ""
        done < "$RESULTS_FILE"
    fi
fi
