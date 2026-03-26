#!/usr/bin/env bash
#
# check-skill-references.sh - Validate canonical SKILL.md files when staged
#
# Usage:
#   check-skill-references.sh [--staged]
#
# Called from the pre-commit hook when SKILL.md files are staged.
# Runs tests/unit/test_skill_references.py to catch broken path references
# and missing frontmatter fields before they propagate to deployed skills.
#
# Exit codes:
#   0 - All references valid (or no SKILL.md files staged)
#   1 - Broken references or invalid frontmatter detected

set -euo pipefail

STAGED_ONLY=false
if [[ "${1:-}" == "--staged" ]]; then
    STAGED_ONLY=true
fi

# Only run if canonical SKILL.md files are staged
if [[ "$STAGED_ONLY" == true ]]; then
    STAGED_SKILLS=$(git diff --cached --name-only 2>/dev/null | grep -E 'canonical/skills/.*/SKILL\.md' || true)
    if [[ -z "$STAGED_SKILLS" ]]; then
        exit 0
    fi
fi

# Run the skill references test module
if ! uv run pytest tests/unit/test_skill_references.py -q --tb=short 2>&1; then
    echo "" >&2
    echo "Pre-commit check failed: canonical SKILL.md files have broken references or invalid frontmatter." >&2
    echo "Fix the issues above before committing." >&2
    exit 1
fi

exit 0
