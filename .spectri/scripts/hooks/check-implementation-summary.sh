#!/usr/bin/env bash
# Check that spec folder commits include a STAGED implementation summary
# Excludes meta.json-only changes

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/logging.sh"

# Allow bypass
if [ "${SKIP_SUMMARY_CHECK:-}" = "1" ]; then
    exit 0
fi

# Get staged files
STAGED=$(git diff --cached --name-only)

# Find affected spec folders (stage-based structure)
# Pattern: spectri/specs/0N-stage/NNN-name/
SPEC_FOLDERS=$(echo "$STAGED" | grep -E '^spectri/specs/0[1-5]-[a-z]+/[0-9]{3}-' | cut -d'/' -f1-4 | sort -u || true)

if [[ -z "$SPEC_FOLDERS" ]]; then
    exit 0  # No spec folders affected
fi

# Check each affected spec folder
for folder in $SPEC_FOLDERS; do
    # Get files changed in this spec folder
    FOLDER_FILES=$(echo "$STAGED" | grep -E "^${folder}/" || true)

    # Check if ONLY meta.json changed (exclude from requirement)
    NON_META_FILES=$(echo "$FOLDER_FILES" | grep -v '/meta\.json$' | grep -v '/implementation-summaries/' || true)

    if [[ -z "$NON_META_FILES" ]]; then
        continue  # Only meta.json changed, no summary required
    fi

    # Check for staged summary
    SUMMARY_STAGED=$(echo "$STAGED" | grep -E "^${folder}/implementation-summaries/.*\.md$" || true)

    if [[ -z "$SUMMARY_STAGED" ]]; then
        echo ""
        log_error "Implementation summary required for $folder"
        echo ""
        echo "   You staged changes to this spec folder but no implementation summary."
        echo ""
        echo "   To fix:"
        echo "     1. Navigate to the spec folder"
        echo "     2. Run /spec.summary to document your changes"
        echo "     3. Stage the generated summary file"
        echo "     4. Commit again"
        echo ""
        echo "   To bypass (emergencies only): git commit --no-verify"
        echo "   Or set: SKIP_SUMMARY_CHECK=1 git commit"
        echo ""
        exit 1
    fi
done

exit 0
