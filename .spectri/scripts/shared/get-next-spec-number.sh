#!/usr/bin/env bash
#
# get-next-spec-number.sh - Centralized spec number calculation
#
# Scans all stage folders (spectri/specs/0[0-5]-*/) to find the highest existing
# spec number and returns the next available number (zero-padded to 3 digits).
#
# Usage:
#   get-next-spec-number.sh              # Returns next available number (e.g., 056)
#   get-next-spec-number.sh --current    # Returns highest existing number (e.g., 055)
#   get-next-spec-number.sh --json       # Returns JSON: {"next":"056","current":"055"}
#   get-next-spec-number.sh --help       # Show this help
#
# Exit codes:
#   0 - Success
#   1 - Error (e.g., specs directory not found)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/logging.sh"
source "$SCRIPT_DIR/../../lib/common.sh"

# --- Defaults ---
MODE="next"
JSON_MODE=false

# --- Parse arguments ---
while [ $# -gt 0 ]; do
    case "$1" in
        --current) MODE="current" ;;
        --json)    JSON_MODE=true ;;
        --help|-h)
            sed -n '3,15p' "$0" | sed 's/^# \?//'
            exit 0
            ;;
        *)
            log_error "Unknown argument '$1'"
            echo "Usage: $0 [--current] [--json] [--help]"
            exit 1
            ;;
    esac
    shift
done

# --- Find repo root ---
REPO_ROOT=$(get_repo_root)

SPECS_DIR="$REPO_ROOT/spectri/specs"

if [ ! -d "$SPECS_DIR" ]; then
    log_error "spectri/specs/ directory not found at $SPECS_DIR"
    exit 1
fi

# --- Calculate highest spec number across all stage folders ---
HIGHEST=$(
    find "$SPECS_DIR"/0[0-5]-*/ -maxdepth 1 -type d -name '[0-9][0-9][0-9]-*' 2>/dev/null \
    | sed 's|.*/\([0-9]*\)-.*|\1|' \
    | sort -n \
    | tail -1
)

# Default to 0 if no specs found
HIGHEST=$((10#${HIGHEST:-0}))
NEXT=$((HIGHEST + 1))

# --- Output ---
HIGHEST_PAD=$(printf "%03d" "$HIGHEST")
NEXT_PAD=$(printf "%03d" "$NEXT")

if $JSON_MODE; then
    printf '{"next":"%s","current":"%s"}\n' "$NEXT_PAD" "$HIGHEST_PAD"
else
    case "$MODE" in
        current) echo "$HIGHEST_PAD" ;;
        next)    echo "$NEXT_PAD" ;;
    esac
fi
