---
managed_by: spectri
description: "Create or update the project constitution from interactive or provided principle inputs, ensuring all dependent templates stay in sync."
model: opus
family: spectri-trail
origin:
  source: github-spec-kit
  upstream_url: https://github.com/github/spec-kit/blob/main/templates/commands/constitution.md
  adaptations: "Renamed speckit→spectri, simplified checkpoint from 35 lines to 2 lines"
injections_applied:
  - user-input
  - frontmatter-update
  - summary-creation
  - finalization-verification
build_info:
  built_at: 2026-03-26T10:24:07Z
  manifest_version: 1.1.0
---
# Create or Update Project Constitution

<!-- INJECT: post-frontmatter -->

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

> **AGENT DIRECTIVE**: You are executing this command workflow, NOT modifying this command file. Follow the "Implementation Steps" section below to execute the requested operation. Do NOT attempt to edit files in `src/command-bases/` or rebuild command infrastructure.


## Outline

You are updating the project constitution at `spectri/constitution.md`. This file is a TEMPLATE containing placeholder tokens in square brackets (e.g. `[PROJECT_NAME]`, `[PRINCIPLE_1_NAME]`). Your job is to (a) collect/derive concrete values, (b) fill the template precisely, and (c) propagate any amendments across dependent artifacts.

Follow this execution flow:

1. Load the existing constitution template at `spectri/constitution.md`.
   - Identify every placeholder token of the form `[ALL_CAPS_IDENTIFIER]`.
   **IMPORTANT**: The user might require less or more principles than the ones used in the template. If a number is specified, respect that - follow the general template. You will update the doc accordingly.

2. Collect/derive values for placeholders:
   - If user input (conversation) supplies a value, use it.
   - Otherwise infer from existing repo context (README, docs, prior constitution versions if embedded).
   - For governance dates: `RATIFICATION_DATE` is the original adoption date (if unknown ask or mark TODO), `LAST_AMENDED_DATE` is today if changes are made, otherwise keep previous.
   - `CONSTITUTION_VERSION` must increment according to semantic versioning rules:
     - MAJOR: Backward incompatible governance/principle removals or redefinitions.
     - MINOR: New principle/section added or materially expanded guidance.
     - PATCH: Clarifications, wording, typo fixes, non-semantic refinements.
   - If version bump type ambiguous, propose reasoning before finalizing.

3. Draft the updated constitution content:
   - Replace every placeholder with concrete text (no bracketed tokens left except intentionally retained template slots that the project has chosen not to define yet—explicitly justify any left).
   - Preserve heading hierarchy and comments can be removed once replaced unless they still add clarifying guidance.
   - Ensure each Principle section: succinct name line, paragraph (or bullet list) capturing non‑negotiable rules, explicit rationale if not obvious.
   - Ensure Governance section lists amendment procedure, versioning policy, and compliance review expectations.

<!-- INJECT: post-header -->

## Frontmatter Update

After creating or modifying documents, update the YAML frontmatter:

- **Date Created**: Set on new documents (ISO 8601 with timezone)
- **Date Updated**: Update on every modification
- **created_by** / **updated_by**: Use `$AGENT_SESSION_ID` format

Example:
```yaml
---
Date Created: 2026-01-14T15:30:00+11:00
Date Updated: 2026-01-14T16:45:00+11:00
created_by: Claude Cerulean Pangolin 1420
updated_by: Claude Vermillion Axolotl 1645
---
```

4. Consistency propagation checklist (convert prior checklist into active validations):
   - Read `.spectri/templates/spectri-core/plan-template.md` and ensure any "Constitution Check" or rules align with updated principles.
   - Read `.spectri/templates/spectri-core/spec-template.md` for scope/requirements alignment—update if constitution adds/removes mandatory sections or constraints.
   - Read `.spectri/templates/spectri-core/tasks-template.md` and ensure task categorization reflects new or removed principle-driven task types (e.g., observability, versioning, testing discipline).
   - Read each command file in `.spectri/canonical/commands/*.md` (including this one) to verify no outdated references (agent-specific names like CLAUDE only) remain when generic guidance is required.
   - Read any runtime guidance docs (e.g., `README.md`, `docs/quickstart.md`, or agent-specific guidance files if present). Update references to principles changed.

5. Produce a Sync Impact Report (prepend as an HTML comment at top of the constitution file after update):
   - Version change: old → new
   - List of modified principles (old title → new title if renamed)
   - Added sections
   - Removed sections
   - Templates requiring updates (✅ updated / ⚠ pending) with file paths
   - Follow-up TODOs if any placeholders intentionally deferred.

6. Validation before final output:
   - No remaining unexplained bracket tokens.
   - Version line matches report.
   - Dates ISO format YYYY-MM-DD.
   - Principles are declarative, testable, and free of vague language ("should" → replace with MUST/SHOULD rationale where appropriate).

7. Write the completed constitution back to `spectri/constitution.md` (overwrite).

8. Output a final summary to the user with:
   - New version and bump rationale.
   - Any files flagged for manual follow-up.
   - Suggested commit message (e.g., `docs: amend constitution to vX.Y.Z (principle additions + governance update)`).

<!-- INJECT: post-execution -->

---

**MANDATORY COMPLETION STEPS** - Execute ALL before ending this command:

1. **Create implementation summary**:
   ```bash
   bash .spectri/scripts/spectri-trail/create-implementation-summary.sh \
     --spec "$SPEC_FOLDER" \
     --scope "constitution" \
     --session-id "$AGENT_SESSION_ID" \
     --agent-name "$AGENT_NAME" \
     --session-start "$SESSION_START"
   ```

2. **Commit all changes**:
   `git add . && git commit -m "feat(spec-NNN): [description]"`

Do NOT skip these steps. The summary script also updates meta.json automatically.

Formatting & Style Requirements:

- Use Markdown headings exactly as in the template (do not demote/promote levels).
- Wrap long rationale lines to keep readability (<100 chars ideally) but do not hard enforce with awkward breaks.
- Keep a single blank line between sections.
- Avoid trailing whitespace.

If the user supplies partial updates (e.g., only one principle revision), still perform validation and version decision steps.

If critical info missing (e.g., ratification date truly unknown), insert `TODO(<FIELD_NAME>): explanation` and include in the Sync Impact Report under deferred items.

Do not create a new template; always operate on the existing `spectri/constitution.md` file.
<!-- INJECT: post-finalization -->

## Finalization Checklist

Before completing this command, verify:

- [ ] **Implementation summary created**: `bash .spectri/scripts/spectri-trail/create-implementation-summary.sh --spec "$SPEC_FOLDER" --scope "[scope]"`
- [ ] **meta.json updated** (when applicable): `bash .spectri/scripts/shared/update-spec-meta.sh --spec "$SPEC_FOLDER" --updated-by "[session-id]"` (Only update meta.json when command modifies spec state, not during implementation phases)
- [ ] **Work committed to git**: Commit using appropriate commands
