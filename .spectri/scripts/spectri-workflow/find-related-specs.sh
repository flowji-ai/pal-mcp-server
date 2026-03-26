#!/usr/bin/env bash
#
# find-related-specs.sh - Find specs that may govern code affected by an issue
#
# Given an issue file (or any markdown file with related_specs/related_files
# frontmatter), finds specs in spectri/specs/ that may govern the affected code.
# Read-only: searches and reports only, never modifies files.
#
# Usage:
#   find-related-specs.sh --file <issue-file>          # Human-readable output
#   find-related-specs.sh --file <issue-file> --json   # JSON output
#   find-related-specs.sh --help                       # Show this help
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
TMPDIR_MATCH=""
cleanup() {
    local exit_code=$?
    if [ -n "$TMPDIR_MATCH" ] && [ -d "$TMPDIR_MATCH" ]; then
        rm -rf "$TMPDIR_MATCH"
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
            sed -n '3,14p' "$0" | sed 's/^# \?//'
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

SPECS_DIR="$REPO_ROOT/spectri/specs"

# Create temp dir for match details
TMPDIR_MATCH=$(mktemp -d)

# --- Frontmatter array parser ---
# Handles three formats:
#   1. Empty: field: []
#   2. Inline: field: ["val1", "val2"]
#   3. Multi-line YAML: field:\n  - val1\n  - val2
parse_frontmatter_array() {
    local file="$1"
    local field="$2"
    local in_frontmatter=false
    local frontmatter_ended=false
    local found_field=false
    local values=""

    while IFS= read -r line; do
        # Track frontmatter boundaries
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

        # If we found our field and this is a continuation line (indented with -)
        if [ "$found_field" = "true" ]; then
            # Check if line starts with whitespace followed by -
            case "$line" in
                "  - "* | "  -"*)
                    # Multi-line YAML item: strip leading "  - " and quotes
                    local val
                    val=$(echo "$line" | sed 's/^[[:space:]]*-[[:space:]]*//' | sed 's/^["'"'"']//;s/["'"'"']$//')
                    if [ -n "$val" ]; then
                        values="$values $val"
                    fi
                    continue
                    ;;
                *)
                    # Not a continuation — new field
                    found_field=false
                    ;;
            esac
        fi

        # Look for the field
        case "$line" in
            "${field}:"*)
                found_field=true
                local rest
                rest=$(echo "$line" | sed "s/^${field}:[[:space:]]*//")
                # Check for empty array
                if [ "$rest" = "[]" ] || [ -z "$rest" ]; then
                    continue
                fi
                # Inline array: ["val1", "val2"] or [val1, val2]
                rest=$(echo "$rest" | sed 's/^\[//;s/\]$//')
                # Split on commas, strip quotes and whitespace
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

# --- Extract listed specs from frontmatter ---
listed_specs_raw=$(parse_frontmatter_array "$INPUT_FILE" "related_specs")

# Resolve listed specs to full paths
listed_specs=""
for spec_ref in $listed_specs_raw; do
    local_found=""
    # Try exact match first
    for dir in "$SPECS_DIR"/0[0-5]-*/"$spec_ref"; do
        if [ -d "$dir" ]; then
            local_found="$dir"
            break
        fi
    done
    # Try prefix match (e.g., "004" matches "004-sync-command")
    if [ -z "$local_found" ]; then
        for dir in "$SPECS_DIR"/0[0-5]-*/"$spec_ref"-*; do
            if [ -d "$dir" ]; then
                local_found="$dir"
                break
            fi
        done
    fi
    if [ -n "$local_found" ]; then
        local_rel="${local_found#$REPO_ROOT/}"
        listed_specs="$listed_specs $local_rel"
    fi
done

# --- Extract search terms ---
# From related_files frontmatter
related_files=$(parse_frontmatter_array "$INPUT_FILE" "related_files")

# From issue body (after frontmatter): file paths
body_paths=""
in_frontmatter=false
frontmatter_ended=false
while IFS= read -r line; do
    if [ "$line" = "---" ]; then
        if [ "$in_frontmatter" = "true" ]; then
            frontmatter_ended=true
            continue
        else
            in_frontmatter=true
            continue
        fi
    fi
    if [ "$frontmatter_ended" = "true" ]; then
        # Extract file paths from body
        paths=$(echo "$line" | grep -oE '(src/|spectri/|\.spectri/|tests/)[^ `"'"'"'\)>,]+' 2>/dev/null || true)
        for p in $paths; do
            if [ ${#p} -ge 8 ]; then
                body_paths="$body_paths $p"
            fi
        done
    fi
done < "$INPUT_FILE"

# Combine all search terms (deduplicated)
all_terms=""
for term in $related_files $body_paths; do
    case " $all_terms " in
        *" $term "*) continue ;;
    esac
    all_terms="$all_terms $term"
done

# --- Discovery search ---
discovered_specs=""

if [ -n "$all_terms" ]; then
    spec_files=$(find "$SPECS_DIR"/0[0-5]-*/*/spec.md 2>/dev/null || true)

    for spec_file in $spec_files; do
        spec_dir=$(dirname "$spec_file")
        spec_rel="${spec_dir#$REPO_ROOT/}"
        spec_basename=$(basename "$spec_dir")

        # Skip specs already in listed_specs
        case " $listed_specs " in
            *" $spec_rel "*) continue ;;
        esac

        match_count=0
        has_full_path_match=false
        match_file="$TMPDIR_MATCH/$spec_basename"

        for term in $all_terms; do
            matches=$(grep -n "$term" "$spec_file" 2>/dev/null || true)
            if [ -n "$matches" ]; then
                count=$(echo "$matches" | wc -l | tr -d ' ')
                match_count=$((match_count + count))
                first_line=$(echo "$matches" | head -1 | cut -d: -f1)
                # Write match details to temp file (one per line: term<TAB>line)
                printf '%s\t%s\n' "$term" "$first_line" >> "$match_file"

                case "$term" in
                    */*) has_full_path_match=true ;;
                esac
            fi
        done

        # Filter: require 2+ matches or 1 full path match
        if [ "$match_count" -ge 2 ] || [ "$has_full_path_match" = "true" ]; then
            discovered_specs="$discovered_specs $spec_rel"
        else
            # Clean up match file for non-qualifying specs
            rm -f "$match_file"
        fi
    done
fi

# --- Output ---
if $JSON_MODE; then
    printf '{'

    # Listed specs
    printf '"listed":['
    first=true
    for spec in $listed_specs; do
        if [ "$first" = "true" ]; then
            first=false
        else
            printf ','
        fi
        printf '"%s"' "$spec"
    done
    printf '],'

    # Discovered specs
    printf '"discovered":['
    first=true
    for spec in $discovered_specs; do
        if [ "$first" = "true" ]; then
            first=false
        else
            printf ','
        fi
        spec_basename=$(basename "$spec")
        printf '{"path":"%s","matches":[' "$spec"
        match_file="$TMPDIR_MATCH/$spec_basename"
        mfirst=true
        if [ -f "$match_file" ]; then
            while IFS=$'\t' read -r term line_num; do
                [ -z "$term" ] && continue
                if [ "$mfirst" = "true" ]; then
                    mfirst=false
                else
                    printf ','
                fi
                printf '{"term":"%s","file":"spec.md","line":%s}' "$term" "$line_num"
            done < "$match_file"
        fi
        printf '],"action":"add to issue frontmatter related_specs if governing"}'
    done
    printf ']'

    printf '}\n'
else
    has_output=false

    if [ -n "$listed_specs" ]; then
        has_output=true
        echo "Already listed in related_specs:"
        for spec in $listed_specs; do
            echo "  ✓ $spec"
        done
        echo ""
    fi

    if [ -n "$discovered_specs" ]; then
        has_output=true
        echo "Newly discovered — add to related_specs if governing:"
        for spec in $discovered_specs; do
            echo "  ? $spec"
            spec_basename=$(basename "$spec")
            match_file="$TMPDIR_MATCH/$spec_basename"
            if [ -f "$match_file" ]; then
                while IFS=$'\t' read -r term line_num; do
                    [ -z "$term" ] && continue
                    echo "    Matched: \"$term\" in spec.md line $line_num"
                done < "$match_file"
            fi
        done
        echo ""
    fi

    if [ "$has_output" = "false" ]; then
        log_info "No related specs found."
    fi
fi
