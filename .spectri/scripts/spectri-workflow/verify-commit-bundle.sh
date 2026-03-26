#!/usr/bin/env bash
#
# verify-commit-bundle.sh - Verify staged changes form a complete commit bundle
#
# Before committing, verifies that staged changes form a complete bundle for
# the given workflow mode. Checks for required pieces (issue moved, spec+summary
# pairing) and warns about potential missing pieces.
# Read-only: inspects git staging area only, never modifies files.
#
# Usage:
#   verify-commit-bundle.sh --mode resolve-issue --file <issue-file>  # Check issue bundle
#   verify-commit-bundle.sh --mode code-change                        # Check code change
#   verify-commit-bundle.sh --mode implement-task [--file <tasks.md>] # Check task bundle
#   verify-commit-bundle.sh --json --mode ...                         # JSON output
#   verify-commit-bundle.sh --help                                    # Show this help
#
# Exit codes:
#   0 - All checks pass (warnings don't affect exit code)
#   1 - Bad arguments
#   2 - File not found
#   3 - Required check failed

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/logging.sh"
source "$SCRIPT_DIR/../../lib/common.sh"

# --- Defaults ---
MODE=""
INPUT_FILE=""
JSON_MODE=false

# --- Parse arguments ---
while [ $# -gt 0 ]; do
    case "$1" in
        --mode)
            if [ $# -lt 2 ]; then
                log_error "--mode requires a value"
                exit 1
            fi
            MODE="$2"
            shift
            ;;
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
            sed -n '3,19p' "$0" | sed 's/^# \?//'
            exit 0
            ;;
        *)
            log_error "Unknown argument '$1'"
            echo "Usage: $0 --mode <resolve-issue|code-change|implement-task> [--file <file>] [--json]"
            exit 1
            ;;
    esac
    shift
done

# --- Validate ---
if [ -z "$MODE" ]; then
    log_error "--mode is required"
    echo "Usage: $0 --mode <resolve-issue|code-change|implement-task> [--file <file>] [--json]"
    exit 1
fi

case "$MODE" in
    resolve-issue|code-change|implement-task) ;;
    *)
        log_error "Invalid mode: $MODE (must be resolve-issue, code-change, or implement-task)"
        exit 1
        ;;
esac

REPO_ROOT=$(get_repo_root)

if [ -n "$INPUT_FILE" ]; then
    if [[ "$INPUT_FILE" != /* ]]; then
        INPUT_FILE="$REPO_ROOT/$INPUT_FILE"
    fi
    if [ ! -f "$INPUT_FILE" ]; then
        log_error "File not found: $INPUT_FILE"
        exit 2
    fi
fi

# --- Frontmatter array parser ---
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

# --- Get staged files ---
# Handle R100 (rename) entries by normalizing to D+A pairs
staged_files=""
staged_deleted=""
staged_added=""
staged_modified=""
staged_renamed_from=""
staged_renamed_to=""

while IFS=$'\t' read -r status_code old_path new_path; do
    [ -z "$status_code" ] && continue
    case "$status_code" in
        R*)
            # Rename: treat as delete old + add new
            staged_deleted="$staged_deleted $old_path"
            staged_added="$staged_added $new_path"
            staged_renamed_from="$staged_renamed_from $old_path"
            staged_renamed_to="$staged_renamed_to $new_path"
            staged_files="$staged_files $old_path $new_path"
            ;;
        D)
            staged_deleted="$staged_deleted $old_path"
            staged_files="$staged_files $old_path"
            ;;
        A)
            staged_added="$staged_added $old_path"
            staged_files="$staged_files $old_path"
            ;;
        M)
            staged_modified="$staged_modified $old_path"
            staged_files="$staged_files $old_path"
            ;;
        *)
            staged_files="$staged_files $old_path"
            ;;
    esac
done <<< "$(cd "$REPO_ROOT" && git diff --cached --name-status 2>/dev/null || true)"

# --- Check results storage ---
# Each check: name|status|detail
checks=""
has_required_failure=false

add_check() {
    local name="$1"
    local status="$2"
    local detail="$3"
    checks="$checks
$name|$status|$detail"
    if [ "$status" = "FAIL" ]; then
        has_required_failure=true
    fi
}

# --- Mode: resolve-issue ---
if [ "$MODE" = "resolve-issue" ]; then
    if [ -z "$INPUT_FILE" ]; then
        log_error "--file is required for resolve-issue mode"
        exit 1
    fi

    issue_basename=$(basename "$INPUT_FILE")

    # Check: Issue moved to resolved/
    issue_deleted=false
    issue_added_resolved=false
    for f in $staged_deleted; do
        case "$f" in
            spectri/issues/"$issue_basename") issue_deleted=true ;;
        esac
    done
    for f in $staged_added; do
        case "$f" in
            spectri/issues/resolved/"$issue_basename") issue_added_resolved=true ;;
        esac
    done

    # Also check renames directly
    for f in $staged_renamed_to; do
        case "$f" in
            spectri/issues/resolved/"$issue_basename") issue_added_resolved=true; issue_deleted=true ;;
        esac
    done

    if [ "$issue_deleted" = "true" ] && [ "$issue_added_resolved" = "true" ]; then
        add_check "Issue moved to resolved/" "PASS" ""
    else
        add_check "Issue moved to resolved/" "FAIL" "Issue file must be moved to spectri/issues/resolved/"
    fi

    # Check spec-related items using related_specs
    related_specs=$(parse_frontmatter_array "$INPUT_FILE" "related_specs")

    if [ -n "$related_specs" ]; then
        # Check if any spec files are staged
        spec_staged=false
        spec_folders=""
        for f in $staged_files; do
            case "$f" in
                spectri/specs/0[0-5]-*/*/spec.md|spectri/specs/0[0-5]-*/*/plan.md|spectri/specs/0[0-5]-*/*/tasks.md)
                    spec_staged=true
                    spec_folder=$(dirname "$f")
                    case " $spec_folders " in
                        *" $spec_folder "*) ;;
                        *) spec_folders="$spec_folders $spec_folder" ;;
                    esac
                    ;;
            esac
        done

        if [ "$spec_staged" = "true" ]; then
            add_check "Related spec staged" "PASS" ""

            # Check summary for each staged spec folder
            for folder in $spec_folders; do
                summary_staged=false
                for f in $staged_files; do
                    case "$f" in
                        "$folder"/implementation-summaries/*.md) summary_staged=true; break ;;
                    esac
                done
                folder_name=$(basename "$folder")
                if [ "$summary_staged" = "true" ]; then
                    add_check "Summary staged for $folder_name" "PASS" ""
                else
                    add_check "Summary staged for $folder_name" "FAIL" "Implementation summary required when spec is staged"
                fi

                # Check meta.json
                meta_staged=false
                for f in $staged_files; do
                    case "$f" in
                        "$folder"/meta.json) meta_staged=true; break ;;
                    esac
                done
                if [ "$meta_staged" = "true" ]; then
                    add_check "meta.json staged for $folder_name" "PASS" ""
                else
                    add_check "meta.json staged for $folder_name" "WARN" "Consider running /spec.update-meta"
                fi
            done
        else
            add_check "Related spec staged" "WARN" "Issue has related_specs but no spec files are staged — verify if behaviour changed"
        fi
    fi
fi

# --- Mode: code-change ---
if [ "$MODE" = "code-change" ]; then
    # Check spec-related items
    spec_staged=false
    spec_folders=""
    for f in $staged_files; do
        case "$f" in
            spectri/specs/0[0-5]-*/*/spec.md|spectri/specs/0[0-5]-*/*/plan.md|spectri/specs/0[0-5]-*/*/tasks.md)
                spec_staged=true
                spec_folder=$(dirname "$f")
                case " $spec_folders " in
                    *" $spec_folder "*) ;;
                    *) spec_folders="$spec_folders $spec_folder" ;;
                esac
                ;;
        esac
    done

    if [ "$spec_staged" = "true" ]; then
        add_check "Spec staged" "PASS" ""

        for folder in $spec_folders; do
            summary_staged=false
            for f in $staged_files; do
                case "$f" in
                    "$folder"/implementation-summaries/*.md) summary_staged=true; break ;;
                esac
            done
            folder_name=$(basename "$folder")
            if [ "$summary_staged" = "true" ]; then
                add_check "Summary staged for $folder_name" "PASS" ""
            else
                add_check "Summary staged for $folder_name" "FAIL" "Implementation summary required when spec is staged"
            fi

            meta_staged=false
            for f in $staged_files; do
                case "$f" in
                    "$folder"/meta.json) meta_staged=true; break ;;
                esac
            done
            if [ "$meta_staged" = "true" ]; then
                add_check "meta.json staged for $folder_name" "PASS" ""
            else
                add_check "meta.json staged for $folder_name" "WARN" "Consider running /spec.update-meta"
            fi
        done
    fi
fi

# --- Mode: implement-task ---
if [ "$MODE" = "implement-task" ]; then
    # Check spec-related items (same as code-change)
    spec_staged=false
    spec_folders=""
    for f in $staged_files; do
        case "$f" in
            spectri/specs/0[0-5]-*/*/spec.md|spectri/specs/0[0-5]-*/*/plan.md|spectri/specs/0[0-5]-*/*/tasks.md)
                spec_staged=true
                spec_folder=$(dirname "$f")
                case " $spec_folders " in
                    *" $spec_folder "*) ;;
                    *) spec_folders="$spec_folders $spec_folder" ;;
                esac
                ;;
        esac
    done

    if [ "$spec_staged" = "true" ]; then
        add_check "Spec staged" "PASS" ""

        for folder in $spec_folders; do
            summary_staged=false
            for f in $staged_files; do
                case "$f" in
                    "$folder"/implementation-summaries/*.md) summary_staged=true; break ;;
                esac
            done
            folder_name=$(basename "$folder")
            if [ "$summary_staged" = "true" ]; then
                add_check "Summary staged for $folder_name" "PASS" ""
            else
                add_check "Summary staged for $folder_name" "FAIL" "Implementation summary required when spec is staged"
            fi

            meta_staged=false
            for f in $staged_files; do
                case "$f" in
                    "$folder"/meta.json) meta_staged=true; break ;;
                esac
            done
            if [ "$meta_staged" = "true" ]; then
                add_check "meta.json staged for $folder_name" "PASS" ""
            else
                add_check "meta.json staged for $folder_name" "WARN" "Consider running /spec.update-meta"
            fi
        done
    fi

    # Check tasks.md staged with [x] mark
    if [ -n "$INPUT_FILE" ]; then
        tasks_basename=$(basename "$INPUT_FILE")
        tasks_staged=false
        for f in $staged_files; do
            case "$f" in
                *"$tasks_basename") tasks_staged=true; break ;;
            esac
        done

        if [ "$tasks_staged" = "true" ]; then
            # Check if the staged version has a [x] mark
            tasks_rel="${INPUT_FILE#$REPO_ROOT/}"
            staged_content=$(cd "$REPO_ROOT" && git show ":$tasks_rel" 2>/dev/null || true)
            if echo "$staged_content" | grep -q '\[x\]'; then
                add_check "tasks.md staged with completed task" "PASS" ""
            else
                add_check "tasks.md staged with completed task" "FAIL" "tasks.md must have at least one [x] marked task"
            fi
        else
            add_check "tasks.md staged" "FAIL" "tasks.md should be staged with completed task marked [x]"
        fi
    fi
fi

# --- Check for unstaged tracked changes (all modes) ---
unstaged=$(cd "$REPO_ROOT" && git diff --name-only 2>/dev/null || true)
if [ -n "$unstaged" ]; then
    unstaged_list=$(echo "$unstaged" | tr '\n' ', ' | sed 's/,$//')
    add_check "No unstaged tracked changes" "WARN" "Unstaged changes in: $unstaged_list"
fi

# --- Calculate result ---
warn_count=0
fail_count=0
pass_count=0
while IFS='|' read -r c_name c_status c_detail; do
    [ -z "$c_name" ] && continue
    case "$c_status" in
        PASS) pass_count=$((pass_count + 1)) ;;
        WARN) warn_count=$((warn_count + 1)) ;;
        FAIL) fail_count=$((fail_count + 1)) ;;
    esac
done <<< "$checks"

if [ "$has_required_failure" = "true" ]; then
    result="FAIL"
else
    result="PASS"
fi

# --- Output ---
if $JSON_MODE; then
    printf '{"mode":"%s","checks":[' "$MODE"

    first=true
    while IFS='|' read -r c_name c_status c_detail; do
        [ -z "$c_name" ] && continue
        if [ "$first" = "true" ]; then
            first=false
        else
            printf ','
        fi
        printf '{"name":"%s","status":"%s"' "$c_name" "$c_status"
        if [ -n "$c_detail" ]; then
            printf ',"detail":"%s"' "$c_detail"
        fi
        printf '}'
    done <<< "$checks"

    printf '],"result":"%s"}\n' "$result"
else
    echo "Bundle verification ($MODE):"
    echo ""

    while IFS='|' read -r c_name c_status c_detail; do
        [ -z "$c_name" ] && continue
        case "$c_status" in
            PASS) echo "  ✓ $c_name" ;;
            WARN) echo "  ⚠ $c_name$([ -n "$c_detail" ] && echo ": $c_detail")" ;;
            FAIL) echo "  ✗ $c_name$([ -n "$c_detail" ] && echo ": $c_detail")" ;;
        esac
    done <<< "$checks"

    echo ""
    if [ "$result" = "PASS" ]; then
        if [ "$warn_count" -gt 0 ]; then
            echo "Result: PASS ($warn_count warning(s))"
        else
            echo "Result: PASS"
        fi
    else
        echo "Result: FAIL ($fail_count required check(s) failed)"
    fi
fi

# Exit with appropriate code
if [ "$has_required_failure" = "true" ]; then
    exit 3
fi
exit 0
