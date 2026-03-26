#!/usr/bin/env bash

# detect-phase.sh
# Detect current Spectri workflow phase by checking filesystem
#
# Usage:
#   ./detect-phase.sh [spec-number]
#   ./detect-phase.sh 042
#   ./detect-phase.sh        # auto-detect latest spec
#
# Output:
#   Phase name, completion status, and suggested next action

set -e

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Find project root by looking for .spectri directory (works from any skill location)
PROJECT_ROOT="$SCRIPT_DIR"
while [[ "$PROJECT_ROOT" != "/" && ! -d "$PROJECT_ROOT/.spectri" ]]; do
    PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
if [[ ! -d "$PROJECT_ROOT/.spectri" ]]; then
    echo -e "\033[0;31mCould not find project root (no .spectri directory found)\033[0m"
    exit 1
fi

SPECS_DIR="$PROJECT_ROOT/spectri/specs"
CONSTITUTION="$PROJECT_ROOT/spectri/constitution.md"

# --- Colors ---
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# --- Functions ---
print_phase() {
    local phase="$1"
    local status="$2"
    local suggestion="$3"

    echo -e "${BOLD}Phase:${NC} ${BLUE}$phase${NC}"
    echo -e "${BOLD}Status:${NC} $status"
    echo -e "${BOLD}Suggestion:${NC} $suggestion"
}

count_tasks() {
    local tasks_file="$1"
    local total=0
    local completed=0

    if [[ -f "$tasks_file" ]]; then
        total=$(grep -c '^\s*- \[' "$tasks_file" 2>/dev/null || echo "0")
        completed=$(grep -c '^\s*- \[x\]' "$tasks_file" 2>/dev/null || echo "0")
    fi

    echo "$completed/$total"
}

find_latest_spec() {
    # Find the highest-numbered spec folder across all stage folders
    local latest=""
    local highest=0

    # Search within stage folders (01-drafting through 05-archived)
    for dir in "$SPECS_DIR"/0[0-5]-*/[0-9]*/; do
        if [[ -d "$dir" ]]; then
            local num=$(basename "$dir" | grep -oE '^[0-9]+' || echo "0")
            if [[ "$num" -gt "$highest" ]]; then
                highest=$num
                latest=$(basename "$dir")
            fi
        fi
    done

    echo "$latest"
}

# --- Main ---
SPEC_NUM="${1:-}"

# Auto-detect spec if not provided
if [[ -z "$SPEC_NUM" ]]; then
    SPEC_NUM=$(find_latest_spec)
    if [[ -z "$SPEC_NUM" ]]; then
        echo -e "${RED}No specs found in $SPECS_DIR${NC}"
        exit 1
    fi
    echo -e "${YELLOW}Auto-detected spec:${NC} $SPEC_NUM"
fi

# Find spec folder (handle both "042" and "042-feature-name" formats)
# Search across all stage folders
SPEC_FOLDER=""
for dir in "$SPECS_DIR"/0[0-5]-*/${SPEC_NUM}*/; do
    if [[ -d "$dir" ]]; then
        SPEC_FOLDER="$dir"
        break
    fi
done

if [[ -z "$SPEC_FOLDER" || ! -d "$SPEC_FOLDER" ]]; then
    echo -e "${RED}Spec folder not found for: $SPEC_NUM${NC}"
    exit 1
fi

SPEC_NAME=$(basename "$SPEC_FOLDER")
echo -e "\n${BOLD}Analyzing:${NC} $SPEC_NAME"
echo "─────────────────────────────────"

# Check each phase
HAS_CONSTITUTION=false
HAS_SPEC=false
HAS_PLAN=false
HAS_TASKS=false
TASKS_COMPLETE=false

[[ -f "$CONSTITUTION" ]] && HAS_CONSTITUTION=true
[[ -f "$SPEC_FOLDER/spec.md" ]] && HAS_SPEC=true
[[ -f "$SPEC_FOLDER/plan.md" ]] && HAS_PLAN=true
[[ -f "$SPEC_FOLDER/tasks.md" ]] && HAS_TASKS=true

# Check task completion
if $HAS_TASKS; then
    TASK_STATUS=$(count_tasks "$SPEC_FOLDER/tasks.md")
    COMPLETED=$(echo "$TASK_STATUS" | cut -d'/' -f1)
    TOTAL=$(echo "$TASK_STATUS" | cut -d'/' -f2)

    if [[ "$TOTAL" -gt 0 && "$COMPLETED" -eq "$TOTAL" ]]; then
        TASKS_COMPLETE=true
    fi
fi

# Print artifact status
echo -e "\n${BOLD}Artifacts:${NC}"
$HAS_CONSTITUTION && echo -e "  ${GREEN}✓${NC} constitution.md" || echo -e "  ${RED}✗${NC} constitution.md"
$HAS_SPEC && echo -e "  ${GREEN}✓${NC} spec.md" || echo -e "  ${RED}✗${NC} spec.md"
$HAS_PLAN && echo -e "  ${GREEN}✓${NC} plan.md" || echo -e "  ${RED}✗${NC} plan.md"
if $HAS_TASKS; then
    echo -e "  ${GREEN}✓${NC} tasks.md ($TASK_STATUS tasks)"
else
    echo -e "  ${RED}✗${NC} tasks.md"
fi

echo ""

# Determine current phase and suggestion
if ! $HAS_CONSTITUTION; then
    print_phase "Constitution" \
        "No governing principles established" \
        "Run /spec.constitution to establish project principles"
elif ! $HAS_SPEC; then
    print_phase "Specify" \
        "Ready to document requirements" \
        "Run /spec.specify to create spec.md"
elif ! $HAS_PLAN; then
    print_phase "Plan" \
        "Spec exists, needs implementation design" \
        "Run /spec.plan to create plan.md"
elif ! $HAS_TASKS; then
    print_phase "Tasks" \
        "Plan exists, needs task breakdown" \
        "Run /spec.tasks to create tasks.md"
elif ! $TASKS_COMPLETE; then
    PERCENT=$((COMPLETED * 100 / TOTAL))
    print_phase "Implement" \
        "$COMPLETED of $TOTAL tasks complete ($PERCENT%)" \
        "Continue implementation or run /spec.implement"
else
    print_phase "Complete" \
        "All tasks completed" \
        "Run /spec.health to validate, then archive or deploy"
fi

echo ""
