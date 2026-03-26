#!/usr/bin/env bash
# verify-integrity.sh - Structural integrity verification for Spectri projects
#
# Detects structural drift across 4 categories:
#   1. Command sync (templates vs deployed)
#   2. Spec integrity (required files)
#   3. Convention enforcement (lowercase, frontmatter)
#   4. Cross-reference validation (broken links)
#
# Usage:
#   verify-integrity.sh [--verbose] [--category CAT] [--help]
#
# Exit codes:
#   0 = All checks passed
#   1 = One or more checks failed

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/logging.sh"

# Global state
VERBOSE=false
CATEGORY=""
ISSUES_FOUND=0
CHECKS_PASSED=0
CHECKS_FAILED=0

#######################################
# Print usage information
#######################################
usage() {
    cat <<EOF
Usage: verify-integrity.sh [OPTIONS]

Verify structural integrity of Spectri project.

OPTIONS:
  --verbose           Show all checks (not just failures)
  --category CAT      Run only specific category:
                      commands|specs|conventions|links
  --help              Show this help message

EXIT CODES:
  0 = All checks passed
  1 = One or more checks failed

EXAMPLES:
  # Run all checks
  ./verify-integrity.sh

  # Run with verbose output
  ./verify-integrity.sh --verbose

  # Run specific category only
  ./verify-integrity.sh --category commands
EOF
}

#######################################
# Parse command line arguments
#######################################
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --verbose)
                VERBOSE=true
                shift
                ;;
            --category)
                CATEGORY="$2"
                shift 2
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

    # Validate category if provided
    if [[ -n "$CATEGORY" ]]; then
        case "$CATEGORY" in
            commands|specs|conventions|links)
                ;;
            *)
                log_error "Invalid category: $CATEGORY"
                echo "Valid categories: commands, specs, conventions, links" >&2
                exit 1
                ;;
        esac
    fi
}

#######################################
# Report an issue
# Arguments:
#   $1 - Issue message
#######################################
report_issue() {
    local message="$1"
    echo -e "${RED}✗${NC} $message"
    ((ISSUES_FOUND++))
}

#######################################
# Report success
# Arguments:
#   $1 - Success message
#######################################
report_success() {
    local message="$1"
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${GREEN}✓${NC} $message"
    fi
}

#######################################
# Print section header
# Arguments:
#   $1 - Section name
#######################################
print_section() {
    local section="$1"
    echo ""
    echo "=== $section ==="
}

#######################################
# Check 1: Command Sync Verification
# Verify templates match deployed commands
#######################################
check_command_sync() {
    print_section "Command Sync"

    local repo_root="$1"
    local templates_dir="$repo_root/.spectri/canonical/commands"
    local deployed_dir="$repo_root/.claude/commands"
    local has_issues=false

    # Check if directories exist
    if [[ ! -d "$templates_dir" ]]; then
        report_issue "Command sync directory not found: $templates_dir"
        return
    fi
    if [[ ! -d "$deployed_dir" ]]; then
        report_issue "Deployed commands directory not found: $deployed_dir"
        return
    fi

    # Check templates have deployed counterparts
    while IFS= read -r -d '' template; do
        local basename=$(basename "$template")
        local deployed="$deployed_dir/$basename"

        if [[ ! -f "$deployed" ]]; then
            report_issue "Template not deployed: $basename"
            has_issues=true
        elif ! cmp -s "$template" "$deployed"; then
            report_issue "Out of sync: $basename"
            has_issues=true
        fi
    done < <(find "$templates_dir" -maxdepth 1 -name "*.md" -type f -print0 2>/dev/null || true)

    # Check deployed commands have template counterparts
    while IFS= read -r -d '' deployed; do
        local basename=$(basename "$deployed")
        local template="$templates_dir/$basename"

        if [[ ! -f "$template" ]]; then
            report_issue "Orphaned deployment: $basename"
            has_issues=true
        fi
    done < <(find "$deployed_dir" -maxdepth 1 -name "*.md" -type f -print0 2>/dev/null || true)

    if [[ "$has_issues" == "false" ]]; then
        report_success "All commands in sync"
    fi
}

#######################################
# Check 2: Spec Integrity Verification
# Verify all spec folders have required files
#######################################
check_spec_integrity() {
    print_section "Spec Integrity"

    local repo_root="$1"
    local specs_dir="$repo_root/spectri/specs"
    local has_issues=false

    if [[ ! -d "$specs_dir" ]]; then
        report_issue "Specs directory not found: $specs_dir"
        return
    fi

    # Find spec folders (NNN-* pattern, excluding deployed, archived)
    while IFS= read -r -d '' spec_dir; do
        local dirname=$(basename "$spec_dir")

        # Skip special directories
        if [[ "$dirname" == "deployed" || "$dirname" == "archived" ]]; then
            continue
        fi

        # Check for required files
        if [[ ! -f "$spec_dir/spec.md" ]]; then
            report_issue "Missing required file: spectri/specs/$dirname/spec.md"
            has_issues=true
        fi
        if [[ ! -f "$spec_dir/meta.json" ]]; then
            report_issue "Missing required file: spectri/specs/$dirname/meta.json"
            has_issues=true
        fi
    done < <(find "$specs_dir" -mindepth 1 -maxdepth 1 -type d -name '[0-9]*-*' -print0 2>/dev/null || true)

    # Also check deployed and archived folders
    for subfolder in deployed archived; do
        local subfolder_path="$specs_dir/$subfolder"
        if [[ -d "$subfolder_path" ]]; then
            while IFS= read -r -d '' spec_dir; do
                local dirname=$(basename "$spec_dir")

                if [[ ! -f "$spec_dir/spec.md" ]]; then
                    report_issue "Missing required file: spectri/specs/$subfolder/$dirname/spec.md"
                    has_issues=true
                fi
                if [[ ! -f "$spec_dir/meta.json" ]]; then
                    report_issue "Missing required file: spectri/specs/$subfolder/$dirname/meta.json"
                    has_issues=true
                fi
            done < <(find "$subfolder_path" -mindepth 1 -maxdepth 1 -type d -name '[0-9]*-*' -print0 2>/dev/null || true)
        fi
    done

    if [[ "$has_issues" == "false" ]]; then
        report_success "All specs have required files"
    fi
}

#######################################
# Check 3: Convention Enforcement
# Verify naming conventions and frontmatter
#######################################
check_conventions() {
    print_section "Convention Enforcement"

    local repo_root="$1"
    local specs_dir="$repo_root/spectri/specs"
    local has_issues=false

    if [[ ! -d "$specs_dir" ]]; then
        report_success "No specs directory (skipping)"
        return
    fi

    # Check for uppercase in folder names
    while IFS= read -r folder; do
        local basename=$(basename "$folder")

        # Skip if folder name is all lowercase or contains only allowed uppercase (like README)
        if [[ "$basename" =~ [A-Z] ]]; then
            local relative_path="${folder#$repo_root/}"
            report_issue "Naming violation: $relative_path should be lowercase"
            has_issues=true
        fi
    done < <(find "$specs_dir" -type d 2>/dev/null || true)

    # Check markdown files for frontmatter (in specs, not docs)
    while IFS= read -r mdfile; do
        # Skip certain files/directories
        local relative_path="${mdfile#$repo_root/}"

        # Only check files in spectri/specs/ directory
        if [[ ! "$relative_path" =~ ^spectri/specs/ ]]; then
            continue
        fi

        # Skip files in docs/, examples/, or other documentation directories
        if [[ "$relative_path" =~ /docs/ || "$relative_path" =~ /examples/ ]]; then
            continue
        fi

        # Check if file has frontmatter (starts with ---)
        if [[ -f "$mdfile" ]]; then
            local first_line=$(head -n 1 "$mdfile" 2>/dev/null || echo "")
            if [[ "$first_line" != "---" ]]; then
                report_issue "Missing frontmatter: $relative_path"
                has_issues=true
            fi
        fi
    done < <(find "$specs_dir" -type f -name "*.md" 2>/dev/null || true)

    if [[ "$has_issues" == "false" ]]; then
        report_success "All conventions followed"
    fi
}

#######################################
# Check 4: Cross-Reference Validation
# Verify internal markdown links resolve
#######################################
check_cross_references() {
    print_section "Cross-Reference Validation"

    local repo_root="$1"
    local specs_dir="$repo_root/spectri/specs"
    local has_issues=false

    if [[ ! -d "$specs_dir" ]]; then
        report_success "No specs directory (skipping)"
        return
    fi

    # Find all markdown files in specs
    while IFS= read -r mdfile; do
        local file_dir=$(dirname "$mdfile")
        local relative_path="${mdfile#$repo_root/}"

        # Extract markdown links: [text](path)
        # Look for relative paths (starting with ./ or ../ or no protocol)
        while IFS= read -r link; do
            # Skip empty lines
            [[ -z "$link" ]] && continue

            # Skip external URLs (http://, https://, mailto:, etc.)
            if [[ "$link" =~ ^[a-zA-Z]+: ]]; then
                continue
            fi

            # Skip anchors within same file (#section)
            if [[ "$link" =~ ^# ]]; then
                continue
            fi

            # Remove anchor from path if present
            local path="${link%%#*}"

            # Skip empty paths
            [[ -z "$path" ]] && continue

            # Resolve relative path
            local target_path
            if [[ "$path" == /* ]]; then
                # Absolute path from repo root
                target_path="$repo_root$path"
            else
                # Relative path from current file
                target_path="$file_dir/$path"
            fi

            # Normalize path (remove ./ and ../)
            target_path=$(cd "$file_dir" && realpath -m "$path" 2>/dev/null || echo "$target_path")

            # Check if target exists
            if [[ ! -e "$target_path" ]]; then
                report_issue "Broken link in $relative_path: $link not found"
                has_issues=true
            fi
        done < <(awk '{
            while (match($0, /\[[^\]]+\]\([^)]+\)/)) {
                link = substr($0, RSTART, RLENGTH)
                match(link, /\([^)]+\)/)
                url = substr(link, RSTART+1, RLENGTH-2)
                print url
                $0 = substr($0, RSTART + RLENGTH)
            }
        }' "$mdfile" 2>/dev/null || true)
    done < <(find "$specs_dir" -type f -name "*.md" 2>/dev/null || true)

    if [[ "$has_issues" == "false" ]]; then
        report_success "All internal links resolve"
    fi
}

#######################################
# Main verification logic
#######################################
main() {
    parse_args "$@"

    local repo_root
    repo_root=$(get_repo_root)

    echo "Spectri Structural Integrity Verification"
    echo "Repository: $repo_root"

    # Run checks based on category filter
    if [[ -z "$CATEGORY" || "$CATEGORY" == "commands" ]]; then
        check_command_sync "$repo_root"
        if [[ $ISSUES_FOUND -eq 0 ]]; then
            ((CHECKS_PASSED++))
        else
            ((CHECKS_FAILED++))
        fi
    fi

    if [[ -z "$CATEGORY" || "$CATEGORY" == "specs" ]]; then
        local before=$ISSUES_FOUND
        check_spec_integrity "$repo_root"
        if [[ $ISSUES_FOUND -eq $before ]]; then
            ((CHECKS_PASSED++))
        else
            ((CHECKS_FAILED++))
        fi
    fi

    if [[ -z "$CATEGORY" || "$CATEGORY" == "conventions" ]]; then
        local before=$ISSUES_FOUND
        check_conventions "$repo_root"
        if [[ $ISSUES_FOUND -eq $before ]]; then
            ((CHECKS_PASSED++))
        else
            ((CHECKS_FAILED++))
        fi
    fi

    if [[ -z "$CATEGORY" || "$CATEGORY" == "links" ]]; then
        local before=$ISSUES_FOUND
        check_cross_references "$repo_root"
        if [[ $ISSUES_FOUND -eq $before ]]; then
            ((CHECKS_PASSED++))
        else
            ((CHECKS_FAILED++))
        fi
    fi

    # Summary
    echo ""
    echo "=== Summary ==="
    echo "Passed: $CHECKS_PASSED categories"
    echo "Failed: $CHECKS_FAILED categories"

    if [[ $ISSUES_FOUND -eq 0 ]]; then
        echo -e "${GREEN}✓ All checks passed${NC}"
        exit 0
    else
        echo -e "${RED}✗ Found $ISSUES_FOUND issue(s)${NC}"
        exit 1
    fi
}

main "$@"
