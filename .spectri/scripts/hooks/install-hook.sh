#!/usr/bin/env bash
#
# install-hook.sh - Install AGENTS.md enforcement pre-commit hook
#
# Usage:
#   .spectri/scripts/hooks/install-hook.sh [--uninstall] [--force]
#
# Options:
#   --uninstall   Remove the hook instead of installing
#   --force       Overwrite existing hook without prompting
#   --help        Show this help message
#
# This script copies the pre-commit.hook template to .git/hooks/pre-commit

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/logging.sh"
source "$SCRIPT_DIR/../../lib/common.sh"

REPO_ROOT=$(get_repo_root)
HOOK_SOURCE="$SCRIPT_DIR/../../templates/spectri-spectri/pre-commit.hook"
HOOK_TARGET="$REPO_ROOT/.git/hooks/pre-commit"

print_success() { printf "${GREEN}✅ %s${NC}\n" "$1"; }
print_warning() { printf "${YELLOW}⚠️  %s${NC}\n" "$1"; }
print_error() { printf "${RED}❌ %s${NC}\n" "$1" >&2; }

show_help() {
    sed -n '2,/^$/p' "$0" | sed 's/^#//' | sed 's/^ //'
}

install_hook() {
    local force="${1:-false}"

    # Check if hook source exists
    if [[ ! -f "$HOOK_SOURCE" ]]; then
        print_error "Hook script not found: $HOOK_SOURCE"
        exit 1
    fi

    # Check if .git/hooks directory exists
    if [[ ! -d "$REPO_ROOT/.git/hooks" ]]; then
        print_error "Git hooks directory not found. Is this a git repository?"
        exit 1
    fi

    # Check for existing hook
    if [[ -f "$HOOK_TARGET" ]] || [[ -L "$HOOK_TARGET" ]]; then
        if [[ "$force" != "true" ]]; then
            print_warning "Pre-commit hook already exists at $HOOK_TARGET"
            read -p "Overwrite? (y/N) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "Installation cancelled."
                exit 0
            fi
        fi
        rm -f "$HOOK_TARGET"
    fi

    # Copy template to hook target (avoids stale symlinks when template is updated)
    cp "$HOOK_SOURCE" "$HOOK_TARGET"
    chmod +x "$HOOK_TARGET"

    print_success "Pre-commit hook installed!"
    echo ""
    echo "The hook will now run all checks:"
    echo "  • Multi-spec commit detection"
    echo "  • Implementation summary immutability"
    echo "  • AGENTS.md enforcement"
    echo "  • Canonical source protection"
    echo "  • Implementation summary requirement"
    echo "  • Timestamp pattern validation"
    echo ""
    echo "To uninstall: $0 --uninstall"
}

uninstall_hook() {
    if [[ -f "$HOOK_TARGET" ]] || [[ -L "$HOOK_TARGET" ]]; then
        # Check if it's our hook (look for Spectri identifier in content)
        if [[ -L "$HOOK_TARGET" ]]; then
            local link_target
            link_target=$(readlink "$HOOK_TARGET" || true)
            if [[ "$link_target" == *"check-agent-plans.sh" ]] || [[ "$link_target" == *"pre-commit.hook" ]]; then
                rm -f "$HOOK_TARGET"
                print_success "Pre-commit hook uninstalled"
            else
                print_warning "Existing hook may not be the Spectri pre-commit hook"
                print_warning "Target: $link_target"
                read -p "Remove anyway? (y/N) " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    rm -f "$HOOK_TARGET"
                    print_success "Pre-commit hook removed"
                fi
            fi
        elif grep -q "Multi-spec commit detection\|implementation summary immutability" "$HOOK_TARGET" 2>/dev/null; then
            rm -f "$HOOK_TARGET"
            print_success "Pre-commit hook uninstalled"
        else
            print_warning "Existing hook may not be the Spectri pre-commit hook"
            read -p "Remove anyway? (y/N) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm -f "$HOOK_TARGET"
                print_success "Pre-commit hook removed"
            fi
        fi
    else
        print_warning "No pre-commit hook found"
    fi
}

main() {
    local uninstall=false
    local force=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                show_help
                exit 0
                ;;
            --uninstall)
                uninstall=true
                shift
                ;;
            --force|-f)
                force=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    if [[ "$uninstall" == "true" ]]; then
        uninstall_hook
    else
        install_hook "$force"
    fi
}

main "$@"
