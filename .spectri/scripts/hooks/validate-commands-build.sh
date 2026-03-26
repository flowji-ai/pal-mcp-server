#!/usr/bin/env bash
#
# check-commands-build.sh - Pre-commit hook to verify commands match build output
#
# Usage:
#   check-commands-build.sh
#
# This script is intended to be called from a git pre-commit hook.
# It runs build-commands.sh --check to verify that committed command files
# match what would be generated from the component system.
#
# Exit codes:
#   0 - All commands match
#   1 - Commands differ from build output (commit should be blocked)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/logging.sh"
source "$SCRIPT_DIR/../../lib/common.sh"

REPO_ROOT=$(get_repo_root)

log_info "Checking that commands match component build output..."

if ! "$REPO_ROOT/scripts/build/build-commands.sh" --check; then
    echo ""
    log_error "Command files differ from component build output."
    echo ""
    echo "To fix this:"
    echo "  1. Run: bash scripts/build/build-commands.sh"
    echo "  2. Stage the updated command files"
    echo "  3. Commit again"
    echo ""
    exit 1
fi

log_success "Commands build check passed."
exit 0
