#!/usr/bin/env bash
#
# create-backlog-item.sh - Create a backlog item in spectri/specs/00-backlog/
#
# Creates a numbered backlog folder with either notes.md (freeform) or
# brief.md (structured template) and meta.json.
#
# Usage:
#   create-backlog-item.sh --type notes --short-name "my-idea" "Raw idea description"
#   create-backlog-item.sh --type brief --short-name "feature-x" "Feature X brief"
#   create-backlog-item.sh --json --type notes --short-name "slug" "description"
#   create-backlog-item.sh --help
#
# Exit codes:
#   0 - Success
#   1 - Error (missing args, bad type, etc.)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/logging.sh"
source "$SCRIPT_DIR/../../lib/filename-utils.sh"
source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/timestamp-utils.sh"

# --- Defaults ---
DOC_TYPE=""
SHORT_NAME=""
JSON_MODE=false
ARGS=()

# --- Parse arguments ---
i=1
while [ $i -le $# ]; do
    arg="${!i}"
    case "$arg" in
        --type)
            if [ $((i + 1)) -gt $# ]; then
                log_error "--type requires a value (notes or brief)"
                exit 1
            fi
            i=$((i + 1))
            DOC_TYPE="${!i}"
            ;;
        --short-name)
            if [ $((i + 1)) -gt $# ]; then
                log_error "--short-name requires a value"
                exit 1
            fi
            i=$((i + 1))
            SHORT_NAME="${!i}"
            ;;
        --json)
            JSON_MODE=true
            ;;
        --help|-h)
            sed -n '3,15p' "$0" | sed 's/^# \?//'
            exit 0
            ;;
        *)
            ARGS+=("$arg")
            ;;
    esac
    i=$((i + 1))
done

DESCRIPTION="${ARGS[*]}"

# --- Validate ---
if [ -z "$DOC_TYPE" ]; then
    log_error "--type is required (notes or brief)"
    exit 1
fi

case "$DOC_TYPE" in
    notes|brief) ;;
    *)
        log_error "Invalid type '$DOC_TYPE'. Must be 'notes' or 'brief'."
        exit 1
        ;;
esac

if [ -z "$SHORT_NAME" ] && [ -z "$DESCRIPTION" ]; then
    log_error "Provide --short-name or a description"
    exit 1
fi

# --- Resolve repo root ---
REPO_ROOT=$(get_repo_root)
cd "$REPO_ROOT"

SPECS_DIR="$REPO_ROOT/spectri/specs"
BACKLOG_DIR="$SPECS_DIR/00-backlog"
mkdir -p "$BACKLOG_DIR"

# --- Generate slug ---
if [ -z "$SHORT_NAME" ]; then
    SHORT_NAME=$(slugify "$DESCRIPTION")
fi
SLUG=$(slugify "$SHORT_NAME")

# --- Get next spec number ---
NEXT_NUM=$("$SCRIPT_DIR/../shared/get-next-spec-number.sh")

# --- Create folder ---
ITEM_DIR="$BACKLOG_DIR/${NEXT_NUM}-${SLUG}"

if [ -d "$ITEM_DIR" ]; then
    log_error "Directory already exists: $ITEM_DIR"
    exit 1
fi

mkdir -p "$ITEM_DIR"

# --- Create document ---
TIMESTAMP=$(get_iso_timestamp)

if [ "$DOC_TYPE" = "notes" ]; then
    cat > "$ITEM_DIR/notes.md" <<EOF
---
Date Created: $TIMESTAMP
Title: ${DESCRIPTION:-$SHORT_NAME}
Type: notes
---

# ${DESCRIPTION:-$SHORT_NAME}

EOF
elif [ "$DOC_TYPE" = "brief" ]; then
    cat > "$ITEM_DIR/brief.md" <<EOF
---
Date Created: $TIMESTAMP
Title: ${DESCRIPTION:-$SHORT_NAME}
Type: brief
---

# ${DESCRIPTION:-$SHORT_NAME}

## Problem Statement

<!-- What problem does this feature solve? Who experiences it? -->

## Directional Requirements

<!-- What should the solution roughly do? List capabilities, not implementation details. -->

## Context & References

<!-- Links to related research, brainstorms, threads, existing specs, or external resources. -->

## Open Questions

<!-- What needs to be answered before this can be specified? -->

EOF
fi

# --- Create meta.json ---
TEMPLATE="$REPO_ROOT/.spectri/templates/spectri-core/meta-template.json"
if [ -f "$TEMPLATE" ]; then
    sed -e "s|{{ISO_TIMESTAMP}}|${TIMESTAMP}|g" \
        -e "s|\[AGENT_SESSION_ID\]|Unknown|g" \
        "$TEMPLATE" > "$ITEM_DIR/meta.json"
else
    cat > "$ITEM_DIR/meta.json" <<EOF
{
  "status": "draft",
  "created": "$TIMESTAMP",
  "created_by": "Unknown",
  "documents": {},
  "implementation_summaries": [],
  "related_specs": [],
  "related_repos": [],
  "related_files": [],
  "blockers": [],
  "notes": ""
}
EOF
fi

# --- Auto-stage ---
if has_git; then
    git add "$ITEM_DIR"
fi

# --- Output ---
ITEM_REL="${ITEM_DIR#$REPO_ROOT/}"

if $JSON_MODE; then
    printf '{"item_dir":"%s","doc_type":"%s","spec_number":"%s","slug":"%s"}\n' \
        "$ITEM_REL" "$DOC_TYPE" "$NEXT_NUM" "$SLUG"
else
    echo "ITEM_DIR: $ITEM_REL"
    echo "DOC_TYPE: $DOC_TYPE"
    echo "SPEC_NUMBER: $NEXT_NUM"
fi
