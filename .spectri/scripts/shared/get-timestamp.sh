#!/usr/bin/env bash
#
# get-timestamp.sh - Get the current system timestamp
#
# Agents MUST call this script to obtain timestamps for frontmatter fields.
# Never fabricate, approximate, or invent timestamps — always call this script.
#
# Usage:
#   get-timestamp.sh              # ISO 8601 with timezone: YYYY-MM-DDTHH:MM:SS+HH:MM (default)
#   get-timestamp.sh --date       # Date only: YYYY-MM-DD
#   get-timestamp.sh --filename   # Filename-safe: YYYY-MM-DD-HHMM
#   get-timestamp.sh --all        # All three formats (labeled)
#   get-timestamp.sh --help       # Show this help
#
# Exit codes:
#   0 - Success
#   1 - Unknown option

set -euo pipefail

case "${1:-}" in
    --date)
        date +"%Y-%m-%d"
        ;;
    --filename)
        date +"%Y-%m-%d-%H%M"
        ;;
    --all)
        ISO=$(date +"%Y-%m-%dT%H:%M:%S%z" | sed 's/\([0-9]\{2\}\)$/:\1/')
        DATE=$(date +"%Y-%m-%d")
        FILENAME=$(date +"%Y-%m-%d-%H%M")
        echo "iso:      ${ISO}"
        echo "date:     ${DATE}"
        echo "filename: ${FILENAME}"
        ;;
    --help|-h)
        sed -n '3,12p' "$0" | sed 's/^# \?//'
        ;;
    --iso|'')
        date +"%Y-%m-%dT%H:%M:%S%z" | sed 's/\([0-9]\{2\}\)$/:\1/'
        ;;
    *)
        echo "Unknown option: $1" >&2
        echo "Usage: $0 [--iso | --date | --filename | --all | --help]" >&2
        exit 1
        ;;
esac
