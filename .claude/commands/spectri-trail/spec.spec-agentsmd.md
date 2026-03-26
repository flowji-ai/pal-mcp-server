---
managed_by: spectri
description: "Create or update spec-level AGENTS.md to track incomplete work state for multi-agent handoffs"
model: sonnet
family: spectri-trail
origin:
  source: spectri
injections_applied:
  - user-input
  - finalization-verification
build_info:
  built_at: 2026-03-26T07:35:29Z
  manifest_version: 1.1.0
---
# Per-Spec AGENTS.md Management

<!-- INJECT: post-frontmatter -->

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).


## Purpose

Create, update, or delete per-spec AGENTS.md files that track incomplete work state for multi-agent collaboration. These minimal (3-15 line) files document where work paused, what's blocking, and what to do next.

## When to Use

- Work paused due to blocker (dependency, missing info, user decision needed)
- Next steps ambiguous from existing docs
- Deliberate pause before handoff to another agent

## Workflow

### 1. Validate Location

Check current working directory:
- **Must be in**: `spectri/specs/NNN-name/` folder
- **If not**: Display error "Must be run from spectri/specs/NNN-name/ folder"

### 2. Analyze Spec State

Examine the spec folder to determine:
- Which files exist (spec.md, plan.md, tasks.md, AGENTS.md)
- Current phase: specification → planning → tasks → implementation → complete
- Completion indicators (task counts, incomplete markers)
- Dependencies (from meta.json related_specs)
- Blockers (from meta.json blockers)

### 3. Check AGENTS.md Status

**If AGENTS.md exists**: Go to Update Flow (step 4a)
**If AGENTS.md doesn't exist**: Go to Create Flow (step 4b)

### 4a. Update Flow (AGENTS.md exists)

1. Read current AGENTS.md content
2. Propose new content based on current state
3. Display both current and proposed content
4. Prompt user:
   - **[A]ccept**: Replace with proposed content
   - **[E]dit**: Modify proposed content interactively
   - **[K]eep**: Keep current content unchanged
   - **[D]elete**: Remove AGENTS.md (work is clear now)
   - **[C]ancel**: Exit without changes

### 4b. Create Flow (AGENTS.md doesn't exist)

1. Run clarity test: Are next steps obvious from existing docs?
2. **If clear**: Report "Next steps clear, AGENTS.md not needed" and exit
3. **If ambiguous**: Propose AGENTS.md content
4. Display proposed content
5. Prompt user:
   - **[A]ccept**: Create AGENTS.md with proposed content
   - **[E]dit**: Modify content before creating
   - **[C]ancel**: Exit without creating

### 5. Handle User Choice

Execute selected action:
- Write/update AGENTS.md file
- Or delete file
- Or exit without changes

## Content Format

AGENTS.md files are minimal (3-15 lines):

```
{Current location - where work paused}
Blocked: {What's preventing progress} (if applicable)
Next: {Specific next action to take}

{Optional additional context}
```

**Example**:
```
Planning paused at section 4
Blocked: Spec 009 must complete first
Next: Check ../009-sync-canonical/meta.json then resume planning
```

## State Detection Logic

**Current Phase Detection**:
- No spec.md → "specification"
- No plan.md → "planning"
- No tasks.md → "tasks"
- Has incomplete tasks → "implementation"
- All tasks complete → "complete"

**Clarity Test** (is AGENTS.md needed?):
- Phase is "complete" → NOT needed
- No blockers AND few remaining tasks → NOT needed
- Blockers exist → NEEDED
- Dependencies blocking → NEEDED
- Incomplete markers in files → NEEDED

## Error Handling

- Location validation fails → Show error with correct usage
- File operations fail → Report specific error
- User cancels → Exit gracefully with message

## Success Messages

- Created: "✓ AGENTS.md created successfully."
- Updated: "✓ AGENTS.md updated successfully."
- Deleted: "✓ AGENTS.md deleted."
- Unchanged: "✓ AGENTS.md unchanged."
- Not needed: "✓ Next steps are clear from existing docs. AGENTS.md not needed at this time."

<!-- INJECT: post-execution -->

<!-- INJECT: post-finalization -->

## Finalization Checklist

Before completing this command, verify:

- [ ] **Implementation summary created**: `bash .spectri/scripts/spectri-trail/create-implementation-summary.sh --spec "$SPEC_FOLDER" --scope "[scope]"`
- [ ] **meta.json updated** (when applicable): `bash .spectri/scripts/shared/update-spec-meta.sh --spec "$SPEC_FOLDER" --updated-by "[session-id]"` (Only update meta.json when command modifies spec state, not during implementation phases)
- [ ] **Work committed to git**: Commit using appropriate commands
