#!/bin/bash
# check-spec-current.sh
# Blocks implementation summary creation if spec.md has not been updated
# alongside other changes in the spec folder.
#
# Usage: check-spec-current.sh <spec-folder>
# Exit 0 = spec.md is current, proceed
# Exit 1 = spec.md is stale, block summary creation

set -uo pipefail

SPEC_FOLDER="${1:?Usage: check-spec-current.sh <spec-folder>}"

if [[ ! -d "$SPEC_FOLDER" ]]; then
    echo "ERROR: Spec folder not found: $SPEC_FOLDER" >&2
    exit 1
fi

# ── Check uncommitted changes (staged + unstaged) ────────────────────────────

# Files changed in the spec folder, excluding implementation-summaries/ and spec.md
OTHER_CHANGED=$(git status --porcelain "$SPEC_FOLDER" 2>/dev/null \
    | grep -v "implementation-summaries/" \
    | grep -v "spec\.md$" \
    | awk '{print $2}')

# Whether spec.md itself has uncommitted changes
SPEC_CHANGED=$(git status --porcelain "${SPEC_FOLDER}/spec.md" 2>/dev/null \
    | awk '{print $2}')

if [[ -n "$OTHER_CHANGED" && -z "$SPEC_CHANGED" ]]; then
    echo "ERROR: spec.md has not been updated to reflect changes in this spec folder." >&2
    echo "" >&2
    echo "Modified files that are not reflected in spec.md:" >&2
    echo "$OTHER_CHANGED" | while read -r f; do echo "  - $f" >&2; done
    echo "" >&2
    echo "Update spec.md so it reflects the current state of the work, then re-run /spec.summary." >&2
    exit 1
fi

# ── No uncommitted changes — check git log commit timestamps ─────────────────

if [[ -z "$OTHER_CHANGED" && -z "$SPEC_CHANGED" ]]; then

    # Unix timestamp of the most recent commit touching spec.md
    SPEC_TS=$(git log --format="%ct" -1 -- "${SPEC_FOLDER}/spec.md" 2>/dev/null | head -1)

    # Latest commit timestamp for any tracked file in the spec folder,
    # excluding spec.md and implementation-summaries/.
    OTHER_TS=$(git ls-files "$SPEC_FOLDER" 2>/dev/null \
        | grep -v "spec\.md$" \
        | grep -v "implementation-summaries/" \
        | while read -r f; do
            git log --format="%ct" -1 -- "$f" 2>/dev/null | head -1
          done \
        | sort -rn | head -1)

    # No other changes found at all — new spec or spec-only work, allow through
    if [[ -z "$OTHER_TS" ]]; then
        exit 0
    fi

    # spec.md was never committed — block
    if [[ -z "$SPEC_TS" ]]; then
        echo "ERROR: spec.md has never been committed in this spec folder." >&2
        echo "Update and commit spec.md before creating a summary." >&2
        exit 1
    fi

    # Other files were committed more recently than spec.md — block
    if [[ "$OTHER_TS" -gt "$SPEC_TS" ]]; then
        echo "ERROR: spec.md was last updated before recent changes were committed in this spec folder." >&2
        echo "spec.md may not reflect current reality. Update it, then re-run /spec.summary." >&2
        exit 1
    fi
fi

exit 0
