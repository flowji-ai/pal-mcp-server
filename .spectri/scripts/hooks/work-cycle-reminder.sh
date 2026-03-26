#!/usr/bin/env bash
#
# work-cycle-reminder.sh - Print work cycle reminder questions to stdout
#
# Usage:
#   work-cycle-reminder.sh
#
# Always exits 0 — never blocks commits.
# Inspects staged files and prints context-appropriate reminder questions.
# Because Claude Code's Bash tool captures hook stdout in the tool result,
# agents see these reminders before the commit lands.
#
# Contexts detected:
#   1. Code/implementation files staged (src/, scripts/, tests/)
#   2. Spec files staged (spectri/specs/)
#   3. Issue files staged (spectri/issues/)
#
# Multiple contexts can trigger in a single commit.

STAGED_FILES=$(git diff --cached --name-only 2>/dev/null)

if [[ -z "$STAGED_FILES" ]]; then
    exit 0
fi

# Track which contexts apply
HAS_CODE=false
HAS_SPECS=false
HAS_ISSUES=false

while IFS= read -r f; do
    if [[ "$f" =~ ^(src|scripts|tests)/ ]]; then
        HAS_CODE=true
    fi
    if [[ "$f" =~ ^spectri/specs/ ]]; then
        HAS_SPECS=true
    fi
    if [[ "$f" =~ ^spectri/issues/ ]]; then
        HAS_ISSUES=true
    fi
done <<< "$STAGED_FILES"

# Print reminders if any context matched
if [[ "$HAS_CODE" == false && "$HAS_SPECS" == false && "$HAS_ISSUES" == false ]]; then
    exit 0
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Work Cycle Reminders"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ "$HAS_CODE" == true ]]; then
    echo ""
    echo "[Code/implementation files staged]"
    echo "  - Do your code changes require that we update any specs as the source of truth?"
    echo "  - If so, have you updated the corresponding spec(s) and run /spec.summary to summarise your work?"
    echo "  - Do your code changes require that you update any necessary tests?"
    echo "  - If so, have you updated the tests and run them to ensure they pass?"
fi

if [[ "$HAS_SPECS" == true ]]; then
    echo ""
    echo "[Spec files staged]"
    echo "  - Does the work you just completed require this or other specs to move to a new stage?"
    echo "  - If so, have you run update-spec-meta.sh to update the frontmatter and move the spec(s) to the correct folder?"
fi

if [[ "$HAS_ISSUES" == true ]]; then
    echo ""
    echo "[Issue files staged]"
    echo "  - Does the code you have fixed while resolving this issue require updates to any related spec documentation?"
    echo "  - If so, have you updated the corresponding spec(s) and created the related implementation summaries using /spec.summary?"
fi

echo ""

exit 0
