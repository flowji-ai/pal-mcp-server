#!/usr/bin/env bash
set -euo pipefail

# resolve-issue.sh - Mark an issue as resolved and move to spectri/issues/resolved/
# Usage: resolve-issue.sh <issue-file> [--commit-hash <hash>] [--spec-needs-update] [--notes "resolution notes"]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/resolve-common.sh"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"

ISSUE_FILE=""
COMMIT_HASH=""
SPEC_NEEDS_UPDATE="false"
NOTES=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --commit-hash)
      COMMIT_HASH="$2"
      shift 2
      ;;
    --spec-needs-update)
      SPEC_NEEDS_UPDATE="true"
      shift
      ;;
    --notes)
      NOTES="$2"
      shift 2
      ;;
    *)
      if [ -z "$ISSUE_FILE" ]; then
        ISSUE_FILE="$1"
        shift
      else
        log_error "Unknown argument: $1"
        echo "Usage: resolve-issue.sh <issue-file> [--commit-hash <hash>] [--spec-needs-update] [--notes \"resolution notes\"]"
        exit 1
      fi
      ;;
  esac
done

if [ -z "$ISSUE_FILE" ]; then
  log_error "Issue file required"
  echo "Usage: resolve-issue.sh <issue-file> [--commit-hash <hash>] [--spec-needs-update] [--notes \"resolution notes\"]"
  exit 1
fi

# Resolve relative paths
if [[ ! "$ISSUE_FILE" = /* ]]; then
  ISSUE_FILE="$PROJECT_ROOT/spectri/issues/$ISSUE_FILE"
fi

if [ ! -f "$ISSUE_FILE" ]; then
  log_error "Issue file not found: $ISSUE_FILE"
  exit 1
fi

BASENAME=$(basename "$ISSUE_FILE")
RESOLVED_DIR="$PROJECT_ROOT/spectri/issues/resolved"
CLOSED_DATE=$(get_date_timestamp)

# Interactive prompts if not provided via arguments
if [ -z "$COMMIT_HASH" ]; then
  echo "Enter commit hash(es) that resolved this issue (comma-separated if multiple):"
  read -r COMMIT_HASH
fi

if [ -z "$NOTES" ]; then
  echo "Enter resolution notes (or press Enter to skip):"
  read -r NOTES
fi

if [ "$SPEC_NEEDS_UPDATE" = "false" ]; then
  echo "Does this fix reveal that related specs need updates? [y/N]"
  read -r RESPONSE
  if [[ "$RESPONSE" =~ ^[Yy]$ ]]; then
    SPEC_NEEDS_UPDATE="true"
  fi
fi

# Update frontmatter using shared functions
resolve_update_frontmatter "$ISSUE_FILE" "status" "resolved"
resolve_update_frontmatter "$ISSUE_FILE" "closed" "$CLOSED_DATE"
resolve_update_frontmatter "$ISSUE_FILE" "spec_needs_update" "$SPEC_NEEDS_UPDATE"

# Update Resolution section — preserve existing content if agent has filled it in
if grep -q "^## Resolution" "$ISSUE_FILE"; then
  REPL_TMP=$(mktemp)
  printf '%s\n' "$COMMIT_HASH" > "$REPL_TMP"
  printf '%s\n' "$SPEC_NEEDS_UPDATE" >> "$REPL_TMP"
  printf '%s\n' "${NOTES:-Issue resolved}" >> "$REPL_TMP"
  python3 - "$ISSUE_FILE" "$REPL_TMP" <<'PYEOF'
import sys
issue_file, data_file = sys.argv[1], sys.argv[2]
with open(issue_file) as f:
    lines = f.readlines()
with open(data_file) as f:
    data_lines = f.read().strip().split('\n')
commit_hash = data_lines[0] if len(data_lines) > 0 else ''
spec_update = data_lines[1] if len(data_lines) > 1 else 'false'
notes = data_lines[2] if len(data_lines) > 2 else 'Issue resolved'
spec_text = 'Yes - spec needs updates' if spec_update == 'true' else 'No - no spec changes needed'

# Extract existing Resolution section content
in_resolution = False
existing_content = []
for line in lines:
    if line.startswith('## Resolution'):
        in_resolution = True
        continue
    if in_resolution and line.startswith('## '):
        break
    if in_resolution:
        existing_content.append(line)

# Check if content is just the placeholder template
existing_text = ''.join(existing_content).strip()
is_placeholder = not existing_text or '[Filled when resolved]' in existing_text

if is_placeholder:
    # Replace with script metadata
    repl = f'## Resolution\n\n- Commit(s): {commit_hash}\n- Spec updates required: {spec_text}\n- Notes: {notes}\n'
else:
    # Preserve existing content as-is
    repl = '## Resolution\n' + ''.join(existing_content)

result = []
skip = False
for line in lines:
    if line.startswith('## Resolution'):
        result.append(repl if repl.endswith('\n') else repl + '\n')
        skip = True
        continue
    if skip and line.startswith('## '):
        skip = False
    if not skip:
        result.append(line)
with open(issue_file, 'w') as f:
    f.write(''.join(result))
PYEOF
  rm -f "$REPL_TMP"
else
  log_warn "No Resolution section found in issue file"
fi

# Move to resolved/ using shared function
resolve_move_to_resolved "$ISSUE_FILE" "$RESOLVED_DIR"

resolve_print_summary "Issue" "$BASENAME" "resolved" "$CLOSED_DATE" "spectri/issues/resolved" "${NOTES:-Issue resolved}"

if [ "$SPEC_NEEDS_UPDATE" = "true" ]; then
  echo ""
  echo "Remember to update related specs or create follow-up issue for spec updates"
fi
