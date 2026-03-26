# [THREADS/] CONTINUATION CONTEXT
<!-- target: spectri/coordination/threads/ -->

Threads capture continuation context for multi-agent handoffs within a single spec's work. When a spec requires multiple sessions or passes between agents, threads preserve what was attempted, what's unfinished, and what decisions are pending.

## When to Use

Create threads when:
- A spec requires more than one session to complete
- Work passes from one agent to another
- Complex implementation has multiple phases with gaps
- You need to return to work after context loss

Use threads for spec-specific work only. Use session summaries for broader agent communication.

## Folder Structure

Each spec has its own thread folder: `spectri/coordination/threads/NNN-spec-slug/`

Within folder: Individual `.md` files

## File Naming

Single pattern: `YYYY-MM-DD-title-slug.md`

The slug portion is the title converted to lowercase with hyphens replacing special characters. Examples:
- `2026-01-19-frontmatter-validation-infrastructure.md`
- `2026-02-05-triage-results.md`

## Required Structure

### Frontmatter
```yaml
---
title: "Thread title"
date_created: "YYYY-MM-DDTHH:MM:SS+11:00"
context: "constitution" | "spec-specific" | "general"
spec: "NNN-feature-name"
status: "active" | "completed"
created_by: "Agent Name (session-id)"
user: "username"

# Processing metadata (filled when thread is completed)
response_notes: ""
processed_by: ""
processed_date: ""
---
```

**Frontmatter Notes:**
- `context` valid values: `constitution`, `spec-specific`, `general`
- Processing metadata section is for internal tracking — rarely used in practice
- Threads remain as `.md` files with `status: active` in frontmatter

### Body Sections
1. **What Was Being Attempted** — Work in progress when thread created
2. **Unfinished Business** — Incomplete tasks, blocked work, partial implementations
3. **Open Questions** — Decisions pending, clarifications needed
4. **Decisions Pending** — Items requiring user or agent input
5. **Next Actions** — Specific steps to continue work
6. **TODO** — Greppable marker for outstanding work. May contain specific items or simply "Work with user to complete the work described above." Purpose is discoverability via `grep -ri "TODO" spectri/coordination/threads/`, not to duplicate detail from other sections.

**Optional Sections** (add when needed):
- Critical Files Reference — Paths to important implementation files
- Context for Next Agent — What the next agent needs to know
- Additional metadata relevant to specific situation

## Status Lifecycle

- **Active** — Work in progress or blocked (`status: active` in frontmatter, `.md` extension)
- **Completed** — Work finished, thread resolved (`status: completed` in frontmatter, renamed to `.md.resolved`)

## Completion Protocol

When work described in a thread is completed:
1. Update frontmatter: set `status: completed`, fill `response_notes`, `processed_by`, `processed_date`
2. Rename file from `.md` to `.md.resolved`

## Handoff Protocol

When passing work to another agent:
1. Update thread with current state
2. Include thread location in agent handoff prompt
3. Next agent reads thread before continuing
