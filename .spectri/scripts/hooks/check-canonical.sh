#!/usr/bin/env bash
#
# check-canonical.sh - Verify canonical sources are staged when deployed files change
#
# Usage: Called from pre-commit hook
#   .spectri/scripts/hooks/check-canonical.sh --staged
#
# Protects:
#   - Commands: src/spectri_cli/canonical/commands/ -> .spectri/canonical/commands/ -> agent dirs
#   - Skills: src/spectri_cli/canonical/skills/ -> .spectri/canonical/skills/ -> agent dirs
#
# Bypass: SKIP_DEPLOY_CHECK=1

set -euo pipefail

# Source shared libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/logging.sh"

# Skip if bypass is set
if [ "${SKIP_DEPLOY_CHECK:-}" = "1" ]; then
    exit 0
fi

MISSING_CANONICAL=""

# =============================================================================
# COMMANDS PROTECTION
# =============================================================================
COMMAND_DEPLOYED_PATTERNS="^\.claude/commands/|^\.qwen/commands/|^\.gemini/commands/|^\.github/agents/|^\.opencode/commands/"

STAGED_COMMANDS=$(git diff --cached --name-only --diff-filter=ACM | \
    grep -E "$COMMAND_DEPLOYED_PATTERNS" | \
    grep -E '\.md$|\.toml$' | \
    grep -v 'AGENTS\.md' | \
    grep -v 'CLAUDE\.md' | \
    grep -v 'QWEN\.md' | \
    grep -v 'GEMINI\.md' || true)

if [ -n "$STAGED_COMMANDS" ]; then
    for deployed_file in $STAGED_COMMANDS; do
        filename=$(basename "$deployed_file")

        # Strip all known deploy-format suffixes to get canonical base
        base_name=$(echo "$filename" | sed -E 's/\.(agent\.md|toml|md)$//')

        # Extract family subdir from deployed path
        # e.g., .claude/commands/spectri-core/spec.plan.md → spectri-core
        family=$(basename "$(dirname "$deployed_file")")

        # Check .spectri/canonical/ (deployed copy)
        canonical_file=".spectri/canonical/commands/${family}/${base_name}.md"
        if [ -f "$canonical_file" ]; then
            if ! git diff --cached --name-only | grep -q "^${canonical_file}$"; then
                # Source not staged — only block if it has local changes (dirty).
                # If source is clean (matches HEAD), the build pipeline is propagating
                # already-committed changes to deployed dirs, which is legitimate.
                if git diff --name-only -- "$canonical_file" 2>/dev/null | grep -q .; then
                    MISSING_CANONICAL="${MISSING_CANONICAL}  [command] ${deployed_file}\n           -> ${canonical_file} (NOT staged)\n"
                fi
            fi
        fi

        # Check src/spectri_cli/canonical/ (package source)
        pkg_canonical_file="src/spectri_cli/canonical/commands/${family}/${base_name}.md"
        if [ -f "$pkg_canonical_file" ]; then
            if ! git diff --cached --name-only | grep -q "^${pkg_canonical_file}$"; then
                if git diff --name-only -- "$pkg_canonical_file" 2>/dev/null | grep -q .; then
                    MISSING_CANONICAL="${MISSING_CANONICAL}  [command] ${deployed_file}\n           -> ${pkg_canonical_file} (NOT staged)\n"
                fi
            fi
        fi

        # Warn if no canonical source exists at all for this deployed file
        if [ ! -f "$canonical_file" ] && [ ! -f "$pkg_canonical_file" ]; then
            MISSING_CANONICAL="${MISSING_CANONICAL}  [command] ${deployed_file}\n           -> No canonical source found (created outside build pipeline?)\n"
        fi
    done
fi

# =============================================================================
# SKILLS PROTECTION
# =============================================================================
SKILL_DEPLOYED_PATTERNS="^\.claude/skills/|^\.qwen/skills/|^\.gemini/skills/|^\.opencode/skills/"

STAGED_SKILLS=$(git diff --cached --name-only --diff-filter=ACM | \
    grep -E "$SKILL_DEPLOYED_PATTERNS" | \
    grep -E 'SKILL\.md$' || true)

if [ -n "$STAGED_SKILLS" ]; then
    for deployed_file in $STAGED_SKILLS; do
        # Extract skill folder name (e.g., .claude/skills/deployment/SKILL.md -> deployment)
        skill_name=$(echo "$deployed_file" | sed -E 's|^\.[^/]+/skills/([^/]+)/SKILL\.md$|\1|')

        # Check .spectri/canonical/ (deployed copy)
        canonical_file=".spectri/canonical/skills/${skill_name}/SKILL.md"
        if [ -f "$canonical_file" ]; then
            if ! git diff --cached --name-only | grep -q "^${canonical_file}$"; then
                if git diff --name-only -- "$canonical_file" 2>/dev/null | grep -q .; then
                    MISSING_CANONICAL="${MISSING_CANONICAL}  [skill] ${deployed_file}\n         -> ${canonical_file} (NOT staged)\n"
                fi
            fi
        fi

        # Check src/spectri_cli/canonical/ (package source)
        pkg_canonical_file="src/spectri_cli/canonical/skills/${skill_name}/SKILL.md"
        if [ -f "$pkg_canonical_file" ]; then
            if ! git diff --cached --name-only | grep -q "^${pkg_canonical_file}$"; then
                if git diff --name-only -- "$pkg_canonical_file" 2>/dev/null | grep -q .; then
                    MISSING_CANONICAL="${MISSING_CANONICAL}  [skill] ${deployed_file}\n         -> ${pkg_canonical_file} (NOT staged)\n"
                fi
            fi
        fi

        # Warn if no canonical source exists at all for this deployed file
        if [ ! -f "$canonical_file" ] && [ ! -f "$pkg_canonical_file" ]; then
            MISSING_CANONICAL="${MISSING_CANONICAL}  [skill] ${deployed_file}\n         -> No canonical source found (created outside build pipeline?)\n"
        fi
    done
fi

# =============================================================================
# REPORT
# =============================================================================
if [ -n "$MISSING_CANONICAL" ]; then
    echo "" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo -e "${RED}❌ COMMIT BLOCKED: Deployed files modified without canonical source${NC}" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "" >&2
    echo "Deployed files must not be edited directly." >&2
    echo "They are auto-generated from canonical sources." >&2
    echo "" >&2
    echo -e "$MISSING_CANONICAL" >&2
    echo "To fix:" >&2
    echo "  1. Revert deployed changes: git restore --staged <file> && git checkout -- <file>" >&2
    echo "  2. Edit the canonical source instead" >&2
    echo "  3. Run: scripts/build/build-sync-commit.sh" >&2
    echo "  4. Commit both canonical and deployed files together" >&2
    echo "" >&2
    echo -e "${YELLOW}Bypass (emergencies only):${NC} SKIP_DEPLOY_CHECK=1 git commit" >&2
    echo "" >&2
    exit 1
fi

exit 0
