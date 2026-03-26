# Plan Conventions

Conventions for authoring LLM plans, derived from analysis of 60 Claude Code plan files. These conventions complement the workflow guidance in `creating-a-plan.md`, `migrating-a-plan.md`, and `implementing-a-plan.md`.

## The Universal Skeleton

Every plan MUST follow this three-part structure:

1. **Context** — what problem, what exists now, why this work matters
2. **Steps** — what to do, organised as phases or flat steps
3. **Verification** — how to confirm the work is complete and correct

This skeleton appeared in 60/60 analysed plans. Everything else is optional scaffolding around this core.

## Section Requirements

### Required

| Section | Guidance |
|---------|----------|
| **Context** | What problem this plan solves and what currently exists. An agent with zero codebase context must understand the situation after reading this section alone. |
| **Steps / Phases** | The work itself. See execution structure below. |
| **Verification** | Completion criteria. See verification format below. |

### Recommended

| Section | When to Include |
|---------|-----------------|
| **Scope boundaries** | When there is realistic risk of scope creep. Express through exclusion — state what the plan will NOT do, what files it will NOT touch, what is DEFERRED. Exclusion statements are more effective than exhaustive inclusion lists. |
| **File references** | When modifying more than 3 files. Use a dedicated section with a table: File / Action (Create, Modify, Delete) / Notes. |
| **Commit strategy** | When the plan produces more than one commit. Use conventional commit format (`feat:`, `fix:`, `docs:`, `chore:`). Prefer inline **COMMIT** markers at the end of each step over a separate commit strategy section. |

### Optional (include when the situation warrants)

| Section | When to Include |
|---------|-----------------|
| **Confirmed decisions** | When design choices were made during planning that the implementing agent needs to respect, not revisit |
| **Current state analysis** | When the existing system is complex enough that the implementing agent needs orientation beyond what Context provides |
| **Risk / rollback** | For production deployments or destructive operations |
| **Error recovery** | When specific failure modes are known and have distinct recovery paths |
| **Prerequisites** | When the plan depends on work completed in a prior plan or external action |
| **Execution mode** | When the plan should be executed interactively rather than autonomously, or when parallel agent delegation is part of the design |
| **Open questions** | When genuinely unresolved items remain — not as a dumping ground for future work |

## Execution Structure

Choose the structure that fits the task:

| Structure | When to Use | Step Count |
|-----------|-------------|------------|
| **Flat numbered steps** | Single-concern plans (renames, audits, single-file changes) | 3-8 steps |
| **Named phases with sub-steps** | Multi-file changes, migrations, pipeline work — the default for most plans | 3-6 phases |
| **Parallel agent delegation** | Research collection, audits across many files — where work can genuinely run concurrently | 2-3 phases |
| **Artifact-organised** | Targeted edits to specific files where the file IS the organising unit, not the sequence | 2-5 parts |

Named phases with sub-steps is the most common pattern (33/60 plans). Default to this unless the task clearly fits another structure.

## Directional by Default

Spectri plans MUST be directional. This is the project's normative stance, not a suggestion. The implementing agent reads the plan with zero codebase context and decides how to write the code.

### What directional means

- Describes **what** to accomplish, **why** it matters, and **what success looks like**
- Points to skills and commands by name — does not enumerate their steps
- Contains no code blocks, no line number references, no exact bash commands
- Each step describes an outcome, not an implementation

### When prescriptive elements are justified

Occasionally, a specific step within an otherwise directional plan requires precision. Five factors indicate when prescriptive content is justified for a **specific step** (not the whole plan):

| Factor | Stays Directional | Justifies Prescriptive |
|--------|-------------------|----------------------|
| **Handoff intent** | Same-session or same-agent execution | Cross-session handoff to a cold agent |
| **Risk of improvisation** | Agent can safely explore alternatives | Wrong interpretation causes breakage |
| **Content type** | Prose, documentation, design artifacts | Exact config value or error message |
| **Task novelty** | Implementing agent needs to make design decisions | Author has already solved the problem |
| **Scope breadth** | Many files with a repeating pattern | 1-3 files with exact targeted edits |

When a plan contains both directional and prescriptive steps (hybrid), each step should be as directional as its specific factor profile allows. Do not make an entire plan prescriptive because one step requires precision.

### Prescriptive elements — graduated scale

When a step genuinely requires prescriptive content, prefer these mechanisms in order (least to most prescriptive):

1. **Behavioural description with constraints** — "Update X to do Y, ensuring Z is not affected"
2. **Before/after description** — describe the current state and desired state without code
3. **Pattern description** — describe the pattern to follow, not the exact code
4. **Exact content** — only when the content is the deliverable itself (e.g., a specific error message, a specific config value)

Avoid: line number references (they go stale), full file rewrites, exact bash commands (unless the command IS the deliverable).

### Quick check for directional quality

| Check | Pass? |
|-------|-------|
| No code blocks | |
| No line number references | |
| No enumerated skill/command steps (point to the skill, don't list its steps) | |
| Each step describes an outcome, not an implementation | |
| An agent with zero codebase context could understand what to do | |

## Verification Format

Use **numbered criteria** as the standard format:

```markdown
## Verification

1. [Criterion that can be objectively checked]
2. [Criterion that can be objectively checked]
3. [Criterion that can be objectively checked]
```

Each criterion should be independently verifiable — an agent can check it without running all other criteria first. Criteria should describe observable outcomes, not restate the steps.

When a criterion requires a specific command to verify, include it inline. Verification commands are acceptable even in directional plans — they are checks, not implementation:

```markdown
3. No stale references remain — `grep -rn 'old-pattern' src/` returns no results
```

Avoid checkbox format (`- [ ]`) in verification — agents use TodoWrite for progress tracking, and checkboxes in the plan file create ambiguity about whether the agent or the plan owns the state.

## Execution Log

Every plan MUST include an `## Execution Log` section (empty when authored, populated during implementation). This section is the audit trail for verification compliance.

The implementing agent appends entries after each step using the format:

```markdown
### [Agent Session ID] — Step [N] — [Date]
[What was done, verification results, blockers, deviations from plan]
```

**Why this matters:** Plans with verification requirements become unauditable without an execution log. A reviewer cannot distinguish "verification was done but not recorded" from "verification was skipped." The execution log closes this gap.

Rules:
- Each agent adds new entries; do not edit previous entries
- Include verification evidence — test output summaries, command results, pass/fail status
- Record blockers and deviations, not just successes
- When the plan resolves, the execution log becomes the permanent audit trail

See `implementing-a-plan.md` Step 5 for the full execution log workflow.

## Commit Conventions

When specifying commits in plans:

- Use **COMMIT** markers inline at the end of each step, not a separate commit strategy section
- Use conventional commit format: `type(scope): description`
- One commit per logical unit of work, not per file
- Include the staging scope — what gets staged with this commit

```markdown
### Step 3: Update path constants

Add `PKG_DIR` and `PKG_CANONICAL_DIR` constants to `lib/paths.sh` and equivalent constants to `src/spectri_cli/paths.py`.

**COMMIT**: Stage `lib/paths.sh` and `src/spectri_cli/paths.py` and commit.
```

Conventional type guidance (`feat:`, `fix:`, `docs:`) is acceptable in COMMIT markers. Do NOT specify exact commit message text — the implementing agent writes the message based on what they actually changed.

## Dependency Expression

Default to implicit sequential ordering (steps execute top to bottom). Add explicit dependency notation only when:

- Steps can be executed in parallel
- Steps can be executed in any order
- A step is blocked by something outside the plan

When needed, use a brief dependency note at the start of the step:

```markdown
### Step 5: Update documentation

**Parallelisable**: All changes in this step are independent.
```

or:

```markdown
### Step 4: Run migration

**Blocked by**: Step 3 must complete and pass verification.
```

Do not add dependency annotations to steps that simply follow the previous step sequentially — that is the default assumption.

## Frontmatter

All plans created through the Spectri `create-llm-plan.sh` script receive standardised frontmatter automatically. When authoring plan content (the body), do not duplicate frontmatter fields in the plan text.

## Length Guidance

If a plan exceeds 500 lines, consider whether it should be split into sequential plans.

## Decision Documentation

When a plan records design decisions (not all do), use a dedicated **Confirmed Decisions** section in the framing area (before steps). Format as a numbered list with brief rationale:

```markdown
## Confirmed Decisions

1. **Forward-only sync** — all build output flows from `src/` to `.spectri/`, never reverse. Matches the existing pattern for scripts, lib, and templates.
2. **Clean-before-build** — `rm -rf` output dir before building. Prevents stale files from removed commands persisting.
```

This section communicates "these are settled — do not revisit" to the implementing agent. If decisions are genuinely open, they belong in an **Open Questions** section instead.
