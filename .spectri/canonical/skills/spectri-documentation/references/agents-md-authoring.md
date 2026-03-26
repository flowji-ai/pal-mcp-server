---
managed_by: spectri
name: agents-md-authoring
description: Use when creating, editing, or reviewing AGENTS.md files at any directory level.
---

# AGENTS.md Authoring

## When to Use This Skill

Activate when:
- Creating or editing any AGENTS.md file
- Reviewing AGENTS.md for bloat or duplication
- Deciding what content belongs in AGENTS.md vs elsewhere

## Key Concept: Signposting, Not Duplication

AGENTS.md has **two jobs ONLY**:

1. **Point to tooling** - Reference commands/scripts/specs (one line each)
2. **Behavioral corrections** - MUST/MUST NOT rules (only if agents frequently violate them)

**Size**: <200 lines (warn at 150)

**Rule**: Never duplicate content that exists in commands, skills, scripts, or specs.

## Content Decision Framework

| Content Type | Belongs In | AGENTS.md Treatment |
|--------------|------------|---------------------|
| Command usage instructions | Command files | Reference only: "Use `/command-name`" |
| Script implementation | Script files | Reference only: "Run script-name.sh" |
| Spec/feature details | spec.md/plan.md | Link only: "See spec NNN" |
| Workflow processes | Command/skill/script | Never duplicate |
| Setup instructions | README.md | Link only |
| Behavioral corrections (MUST/MUST NOT) | AGENTS.md | Include (if frequently violated) |
| Signposting (where tooling lives) | AGENTS.md | Include (one line reference) |

**Critical**: If content exists in a command, skill, script, or spec → reference it in one line, never duplicate.

## Anti-Patterns

**Don't duplicate command usage**:
- Explain how `/command-name` works with flags, options, and examples
- Reference: "Use `/command-name` for X. See `.claude/commands/` for all commands."

**Don't duplicate workflows**:
- Step-by-step process instructions that exist in commands/skills
- Decision context: "When X happens, use `/command-y`"

**Don't include directory trees**:
- List full folder structure with files (goes stale immediately)
- Abstract references: "Components in `src/components/`"

**Don't duplicate spec content**:
- Copy requirements, architecture, or implementation details from specs
- Link: "See [spec NNN](path/to/spec.md) for full workflow"

**Don't explain hook/automation mechanics**:
- Detailed explanation of how hooks work internally
- Note existence: "Pre-commit hook runs linting automatically"

**Don't mention skills**:
- Explain when skills activate or what they contain
- Skills auto-apply based on context - don't reference them at all
