---
name: spectri-skill-creation
description: "Use when creating a new skill, or auditing or rewriting a skill that forms part of the Spectri framework."
metadata:
  version: "1.0"
  date-created: "2026-03-05"
  date-updated: "2026-03-05"
  created-by: "claude-opus-4-6"
  managed-by: "spectri"
  ships-with-product: "false"
  spectri-pattern: "TODO"
---

# Spectri Skill Creation

Spectri-specific context for creating or rewriting framework skills. This skill is an adjunct to `skill-management` — it provides the where and how-to-deploy, not the creation workflow itself.

<HARD-GATE>
Load the `skill-management` skill before proceeding. This skill provides Spectri-specific paths and deployment — `skill-management` provides the creation workflow.
</HARD-GATE>

## Source Location

All Spectri framework skills live in the canonical source folder:

```
src/spectri_cli/canonical/skills/<skill-name>/
├── SKILL.md              # The skill (synced/deployed)
├── references/            # Reference files (synced/deployed)
│   └── *.md
└── skill-brief/           # Development-only (NOT shipped)
    ├── skill-brief.md
    ├── baseline-failures.md
    └── *-FOR-REFERENCE.md
```

<CRITICAL>
MUST NOT create skills directly in `.claude/skills/`, `.qwen/skills/`, or any other agent directory. These are deployment targets — they get overwritten by build/sync.
</CRITICAL>

Spectri framework skills have **no prototypes/version folder**. Unlike global skills, there is no `v1-2026-XX-XX/` directory. The canonical folder IS the single version.

## Creating a New Skill

1. Follow `skill-management` for the full creation workflow
2. When `skill-management` asks for a path, use `src/spectri_cli/canonical/skills/<skill-name>/`
3. After all `skill-management` steps complete, deploy with `scripts/build/build-sync-commit.sh`

The `skill-brief/` folder is excluded from deployment — it stays in source only.

## Rewriting an Existing Skill (Rehash)

When a skill needs a full rewrite rather than incremental edits:

1. Move existing files into `skill-brief/` with `-FOR-REFERENCE` suffix:
   - `SKILL.md` → `skill-brief/SKILL-previous-version-FOR-REFERENCE.md`
   - Each reference file → `skill-brief/<name>-FOR-REFERENCE.md`
2. Follow `skill-management` to create the skill fresh, using FOR-REFERENCE files as context
3. Deploy with `scripts/build/build-sync-commit.sh`

**Terminal state:** Skill created/rewritten in canonical source, built, synced, and committed via `scripts/build/build-sync-commit.sh`.
