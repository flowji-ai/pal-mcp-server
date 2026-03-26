#!/usr/bin/env bash
# Update manually-installed Spectri projects with latest changes
#
# USAGE:
#   update-manual-installs.sh <project-path> [--since YYYY-MM-DD]
#
# EXAMPLES:
#   update-manual-installs.sh ~/projects/my-project --since 2026-01-15
#   update-manual-installs.sh /path/to/project
#
# DESCRIPTION:
#   This is an ONGOING UTILITY for keeping manually-installed Spectri projects
#   synchronized with spectri updates. Even after `spec init` automation is
#   implemented, manual installations will continue to exist for projects that
#   prefer manual control or don't use the package distribution.
#
# WHAT IT DOES:
#   1. Identifies files changed in spectri since last update
#   2. Copies only changed files to target project
#   3. Preserves user customizations (settings.local.json, user commands)
#   4. Provides clear audit trail of what was updated
#
# SAFETY:
#   - Never overwrites user-created commands
#   - Never overwrites .claude/settings.local.json
#   - Never modifies PROJECT-SPECIFIC sections in AGENTS.md
#   - Shows what will be updated before copying
#   - Requires confirmation for destructive operations

set -euo pipefail

# Get spectri source directory (where this script lives)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared libraries
source "$SCRIPT_DIR/../../lib/logging.sh"
SPECFLOW_SOURCE="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Configuration
# Files that should NEVER be overwritten during updates
PROTECTED_FILES=(
    ".claude/settings.local.json"  # User's local settings
    "AGENTS.md"                     # Root AGENTS.md has project-specific content
)

# spectri/specs/AGENTS.md is NOT protected - it's Spectri-owned template content
# and should be updated when the template changes

PROTECTED_PATTERNS=(
    "# PROJECT-SPECIFIC"
    "<!-- PROJECT-SPECIFIC"
)

# Usage
usage() {
    cat << EOF
Usage: $(basename "$0") <project-path> [--since YYYY-MM-DD]

Update manually-installed Spectri project with latest changes.

Arguments:
  project-path    Path to target project with manual Spectri installation
  --since         Only update files changed since this date (default: 7 days ago)

Examples:
  $(basename "$0") ~/projects/my-project --since 2026-01-15
  $(basename "$0") /path/to/project

This is an ongoing utility for keeping manual installations synchronized.
EOF
    exit 1
}

# Parse arguments
if [[ $# -lt 1 ]]; then
    usage
fi

PROJECT_PATH="$1"
SINCE_DATE=""

shift
while [[ $# -gt 0 ]]; do
    case $1 in
        --since)
            SINCE_DATE="$2"
            shift 2
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            ;;
    esac
done

# Validate project path
if [[ ! -d "$PROJECT_PATH" ]]; then
    echo -e "${RED}Error: Project path does not exist: $PROJECT_PATH${NC}"
    exit 1
fi

# Verify it's a Spectri project
if [[ ! -d "$PROJECT_PATH/.spectri" ]] || [[ ! -d "$PROJECT_PATH/.claude/commands" ]]; then
    echo -e "${RED}Error: $PROJECT_PATH does not appear to be a Spectri project${NC}"
    echo "Missing .spectri/ or .claude/commands/ directories"
    exit 1
fi

# Set default since date if not provided
if [[ -z "$SINCE_DATE" ]]; then
    SINCE_DATE=$(date -v-7d +%Y-%m-%d 2>/dev/null || date -d "7 days ago" +%Y-%m-%d)
    echo -e "${BLUE}No --since date provided, using: $SINCE_DATE${NC}"
fi

# Validate date format
if ! date -j -f "%Y-%m-%d" "$SINCE_DATE" >/dev/null 2>&1 && ! date -d "$SINCE_DATE" >/dev/null 2>&1; then
    echo -e "${RED}Error: Invalid date format. Use YYYY-MM-DD${NC}"
    exit 1
fi

echo -e "${GREEN}Spectri Manual Installation Updater${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Source:  $SPECFLOW_SOURCE"
echo "Target:  $PROJECT_PATH"
echo "Since:   $SINCE_DATE"
echo ""

# Get changed files since date
cd "$SPECFLOW_SOURCE"

CHANGED_FILES=()
DEPLOYABLE_PATHS=(
    "src/spectri_cli/templates"
    "src/spectri_cli/scripts/bash"
    ".spectri/canonical/commands"
    ".claude/commands"
    ".claude/skills"
    ".qwen"
    ".gemini"
    ".github/agents"
)

echo -e "${BLUE}Scanning for changes since $SINCE_DATE...${NC}"
echo ""

for path in "${DEPLOYABLE_PATHS[@]}"; do
    if [[ -d "$SPECFLOW_SOURCE/$path" ]]; then
        while IFS= read -r file; do
            if [[ -n "$file" ]]; then
                CHANGED_FILES+=("$file")
            fi
        done < <(git log --since="$SINCE_DATE" --name-only --pretty=format: -- "$path" | sort -u)
    fi
done

if [[ ${#CHANGED_FILES[@]} -eq 0 ]]; then
    echo -e "${GREEN}✓ No changes found since $SINCE_DATE${NC}"
    echo "Project is up to date!"
    exit 0
fi

echo -e "${YELLOW}Found ${#CHANGED_FILES[@]} changed file(s):${NC}"
for file in "${CHANGED_FILES[@]}"; do
    echo "  - $file"
done
echo ""

# Categorize files
TEMPLATES=()
SCRIPTS=()
COMMANDS_SYNC=()
COMMANDS=()
SKILLS=()
AGENTS=()

for file in "${CHANGED_FILES[@]}"; do
    if [[ "$file" =~ ^src/spectri_cli/templates/ ]]; then
        TEMPLATES+=("$file")
    elif [[ "$file" =~ ^src/spectri_cli/scripts/(spectri-[^/]+|shared|hooks)/ ]]; then
        SCRIPTS+=("$file")
    elif [[ "$file" =~ ^\.spectri/canonical/commands/ ]]; then
        COMMANDS_SYNC+=("$file")
    elif [[ "$file" =~ ^\.claude/commands/ ]]; then
        COMMANDS+=("$file")
    elif [[ "$file" =~ ^\.claude/skills/ ]]; then
        SKILLS+=("$file")
    elif [[ "$file" =~ ^\.qwen/ ]] || [[ "$file" =~ ^\.gemini/ ]] || [[ "$file" =~ ^\.github/agents/ ]]; then
        AGENTS+=("$file")
    fi
done

# Show what will be updated
echo -e "${BLUE}Update plan:${NC}"
[[ ${#TEMPLATES[@]} -gt 0 ]] && echo -e "  ${GREEN}Templates:${NC} ${#TEMPLATES[@]} file(s)"
[[ ${#SCRIPTS[@]} -gt 0 ]] && echo -e "  ${GREEN}Scripts:${NC} ${#SCRIPTS[@]} file(s)"
[[ ${#COMMANDS_SYNC[@]} -gt 0 ]] && echo -e "  ${GREEN}Command Sync:${NC} ${#COMMANDS_SYNC[@]} file(s)"
[[ ${#COMMANDS[@]} -gt 0 ]] && echo -e "  ${GREEN}Commands:${NC} ${#COMMANDS[@]} file(s)"
[[ ${#SKILLS[@]} -gt 0 ]] && echo -e "  ${GREEN}Skills:${NC} ${#SKILLS[@]} file(s)"
[[ ${#AGENTS[@]} -gt 0 ]] && echo -e "  ${GREEN}Agent Formats:${NC} ${#AGENTS[@]} file(s)"
echo ""

# Ask for confirmation
read -p "Proceed with update? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Update cancelled${NC}"
    exit 0
fi

# Function to copy file with safety checks
safe_copy() {
    local src="$1"
    local dst="$2"

    # Check if file is protected
    for protected in "${PROTECTED_FILES[@]}"; do
        if [[ "$dst" == *"$protected" ]]; then
            echo -e "  ${YELLOW}⊘ Skipped (protected):${NC} $protected"
            return
        fi
    done

    # Check for user-created commands (not in COMMANDS list)
    if [[ "$dst" =~ \.claude/commands/ ]] && [[ ! -f "$src" ]]; then
        echo -e "  ${YELLOW}⊘ Skipped (user command):${NC} $(basename "$dst")"
        return
    fi

    # Create parent directory if needed
    mkdir -p "$(dirname "$dst")"

    # Copy file
    cp "$src" "$dst"

    # Preserve execute permissions for scripts
    if [[ "$src" =~ \.sh$ ]]; then
        chmod +x "$dst"
    fi

    echo -e "  ${GREEN}✓ Updated:${NC} ${dst#$PROJECT_PATH/}"
}

# Copy templates
if [[ ${#TEMPLATES[@]} -gt 0 ]]; then
    echo -e "\n${BLUE}Updating templates...${NC}"
    for file in "${TEMPLATES[@]}"; do
        src="$SPECFLOW_SOURCE/$file"
        dst="$PROJECT_PATH/.spectri/templates/$(basename "$file")"
        safe_copy "$src" "$dst"
    done
fi

# Copy scripts
if [[ ${#SCRIPTS[@]} -gt 0 ]]; then
    echo -e "\n${BLUE}Updating scripts...${NC}"
    for file in "${SCRIPTS[@]}"; do
        src="$SPECFLOW_SOURCE/$file"
        # Extract group folder from path: src/spectri_cli/scripts/GROUP/file.sh -> GROUP
        group=$(echo "$file" | sed 's|^src/spectri_cli/scripts/\([^/]*\)/.*|\1|')
        dst="$PROJECT_PATH/.spectri/scripts/$group/$(basename "$file")"
        safe_copy "$src" "$dst"
    done
fi

# Copy canonical/commands
if [[ ${#COMMANDS_SYNC[@]} -gt 0 ]]; then
    echo -e "\n${BLUE}Updating canonical/commands...${NC}"
    for file in "${COMMANDS_SYNC[@]}"; do
        src="$SPECFLOW_SOURCE/$file"
        dst="$PROJECT_PATH/$file"
        safe_copy "$src" "$dst"
    done
fi

# Copy commands
if [[ ${#COMMANDS[@]} -gt 0 ]]; then
    echo -e "\n${BLUE}Updating commands...${NC}"
    for file in "${COMMANDS[@]}"; do
        src="$SPECFLOW_SOURCE/$file"
        dst="$PROJECT_PATH/$file"
        safe_copy "$src" "$dst"
    done
fi

# Copy skills
if [[ ${#SKILLS[@]} -gt 0 ]]; then
    echo -e "\n${BLUE}Updating skills...${NC}"
    for file in "${SKILLS[@]}"; do
        src="$SPECFLOW_SOURCE/$file"
        dst="$PROJECT_PATH/$file"
        safe_copy "$src" "$dst"
    done
fi

# Copy agent formats
if [[ ${#AGENTS[@]} -gt 0 ]]; then
    echo -e "\n${BLUE}Updating agent formats...${NC}"
    for file in "${AGENTS[@]}"; do
        src="$SPECFLOW_SOURCE/$file"
        dst="$PROJECT_PATH/$file"
        safe_copy "$src" "$dst"
    done
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ Update complete!${NC}"
echo ""
echo "Updated project: $PROJECT_PATH"
echo "Files updated: $((${#TEMPLATES[@]} + ${#SCRIPTS[@]} + ${#COMMANDS_SYNC[@]} + ${#COMMANDS[@]} + ${#SKILLS[@]} + ${#AGENTS[@]}))"
echo ""
echo "Next steps:"
echo "  1. Review changes in your project"
echo "  2. Test affected commands/scripts"
echo "  3. Commit the updates"
echo ""
