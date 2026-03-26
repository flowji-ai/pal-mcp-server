#!/usr/bin/env bash
#
# validate-timestamp-patterns.sh - Block manual date formatting in scripts
#
# Usage: Called from pre-commit hook
#   .spectri/scripts/hooks/validate-timestamp-patterns.sh --staged
#
# Purpose: Enforce use of timestamp-utils.sh library functions instead of
#          manual date +%Y, date +%F, etc. commands in scripts.
#
# Library functions to use instead:
#   get_date_timestamp      → YYYY-MM-DD
#   get_filename_timestamp  → YYYY-MM-DD-HHMM
#   get_iso_timestamp       → YYYY-MM-DDTHH:MM:SS+HH:MM
#
# Bypass: SKIP_TIMESTAMP_CHECK=1

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/logging.sh"

# Skip if bypass is set
if [ "${SKIP_TIMESTAMP_CHECK:-}" = "1" ]; then
    exit 0
fi

# Get staged .sh files only in the scripts directory (not lib, not build)
STAGED_SCRIPTS=$(git diff --cached --name-only --diff-filter=ACM | \
    grep -E '^src/spectri_cli/scripts/.*\.sh$' || true)

if [ -z "$STAGED_SCRIPTS" ]; then
    exit 0
fi

VIOLATIONS=""

for script_file in $STAGED_SCRIPTS; do
    # Exempt: the timestamp utility itself (it IS the underlying date wrapper)
    # Exempt: this validator (its own echo examples would trigger a false positive)
    if [[ "$script_file" == *"/shared/get-timestamp.sh" ]] || \
       [[ "$script_file" == *"/hooks/validate-timestamp-patterns.sh" ]]; then
        continue
    fi

    # Get staged content (not working tree content)
    STAGED_CONTENT=$(git show ":${script_file}" 2>/dev/null || true)

    if [ -z "$STAGED_CONTENT" ]; then
        continue
    fi

    # Find date formatting commands (NOT epoch timing)
    # Match: date +%Y, date +%F, date +"%Y, date +'%Y, etc.
    # Match: date -Iseconds, date -I (ISO 8601 shorthand), date --iso-8601 (long form)
    # Skip: date +%s (epoch seconds), date +%s%3N (epoch millis)
    # Skip: comment lines (starting with #)
    MATCHES=$(echo "$STAGED_CONTENT" | grep -nE '^\s*[^#]*date (\+["%'"'"']?%[^s]|-I|--iso)' || true)

    if [ -n "$MATCHES" ]; then
        VIOLATIONS="${VIOLATIONS}\n  ${script_file}:\n"
        while IFS= read -r line; do
            VIOLATIONS="${VIOLATIONS}    ${line}\n"
        done <<< "$MATCHES"
    fi
done

if [ -n "$VIOLATIONS" ]; then
    echo "" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    log_error "Manual date formatting detected in staged scripts"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "" >&2
    echo "Use timestamp-utils.sh functions instead of manual date commands:" >&2
    echo "  date +%Y-%m-%d            -> get_date_timestamp" >&2
    echo "  date +%Y-%m-%d-%H%M       -> get_filename_timestamp" >&2
    echo "  date +%Y-%m-%dT%H:%M:%S%z -> get_iso_timestamp" >&2
    echo "  date -Iseconds            -> get_iso_timestamp" >&2
    echo "" >&2
    echo "Add to your script:" >&2
    echo "  source \"\$SCRIPT_DIR/../../lib/timestamp-utils.sh\"" >&2
    echo "" >&2
    echo "Violations found:" >&2
    printf "$VIOLATIONS" >&2
    echo "" >&2
    echo "Bypass (emergencies only): SKIP_TIMESTAMP_CHECK=1 git commit" >&2
    echo "" >&2
    exit 1
fi

exit 0
