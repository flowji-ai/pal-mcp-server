---
managed_by: spectri
description: "Create GitHub issue from rapid capture (verbal/screenshot) or structured input"
model: sonnet
family: spectri-quality
origin:
  source: spectri
injections_applied:
  - user-input
build_info:
  built_at: 2026-03-26T05:51:02Z
  manifest_version: 1.1.0
---

<!-- INJECT: post-frontmatter -->

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

<!--
  COMMAND TYPE: Hybrid

  Thinking: Agent drafts summaries, evaluates priority, gets user approval
  Orchestration: Executes script with parameters, reports output
-->

## Mode Detection

This command has four modes. Detect the mode from user input:

- **Update mode**: User input contains "update", "modify", "change", or "edit" (referring to existing issue) → go to [Update Flow](#update-flow)
- **Fix mode**: User input contains "fix" or "implement fix" (agent will do the fix work now) → go to [Fix Flow](#fix-flow)
- **Resolve mode**: User input contains "resolve", "close", "fixed", or references a specific issue file → go to [Resolve Flow](#resolve-flow)
- **Create mode** (default): Anything else → continue to [Create Flow](#create-flow) below

---

## Create Flow

### Outline

Goal: Enable rapid issue capture with minimal friction by collecting priority and issue details, then creating a properly formatted issue file with auto-populated metadata and unique timestamp-based filename.

**Context**: This command supports three input methods:
- **Verbal description**: Agent drafts Issue Summary from user description
- **Screenshot**: Agent reads screenshot with vision API and extracts issue information
- **Agent synthesis**: Agent drafts Issue Summary from conversation context

**Prerequisites**: None - issues can be created at any time

**Constraints**:
- Priority must be specified (no default allowed)
- Issue files must have unique names (YYYY-MM-DD-slug.md)
- Status is always `identified` for new issues

Execution steps:

1. **Gather priority with criteria**: Ask user to specify issue priority

   **Priority criteria** (present these to help user decide):

   | Priority | Criteria | Response Time |
   |----------|----------|---------------|
   | **critical** | Blocks all work, data loss, or security vulnerability | Immediate |
   | **high** | Blocks significant functionality, multiple users affected | Within hours |
   | **medium** | Noticeable impact but doesn't block work | Within days |
   | **low** | Minor inconvenience, cosmetic issues | When convenient |

   **Ask**: "What priority is this issue? (critical/high/medium/low)"

   Present the criteria table to help the user make an informed decision.

   - Validation: Priority must be one of: critical, high, medium, low
   - If invalid, re-prompt with criteria

1.5. **[INTERNAL TESTING — remove after 2026-04-15] Determine target repository**: Review the conversation context for signals that this issue relates to the Spectri framework itself rather than the current project.

   **Spectri framework signals**: mentions of Spectri commands (`/spec.*`), skills, scripts, `.spectri/` infrastructure, build pipeline, `SPECTRI.md`, `create-issue.sh`, `resolve-issue.sh`, spec.issue command behaviour, etc.

   **Ask**: "Should this issue be filed in:
   - A) **Spectri repo** — it's a Spectri framework issue (affects all Spectri users)
   - B) **Current project repo** — it's this project's own issue"

   - If A → set `TARGET_REPO=spectri`, pass `--target-repo spectri` to create-issue.sh
   - If B → set `TARGET_REPO=current`, pass `--target-repo current` to create-issue.sh (or omit, it's the default)

2. **Determine input method**: Ask user how they want to provide issue details

   **Three options**:
   - **Option A - Verbal description**: User describes the problem, agent drafts summary
   - **Option B - Screenshot**: User provides screenshot path, agent reads with vision API
   - **Option C - Agent synthesis**: Agent drafts from conversation context

   **Ask**: "How should I capture this issue?"
   - A) I'll describe the issue
   - B) I have a screenshot to share
   - C) You (the agent) describe it based on our conversation

   Based on their response, follow either Option A, Option B, or Option C below.

3. **Option A - Verbal description path**:

   a. **Collect issue description**: Ask user to describe the problem
      - **Ask**: "Please describe the issue. What's broken or needs fixing?"
      - Encourage brief but clear descriptions (2-4 sentences ideal)
      - If user is too brief (< 10 words), ask for more context

   b. **Draft Issue Summary**: Create concise summary from description
      - **Transformation pattern**:
        - User: "The login page doesn't work when I enter valid credentials. It just spins forever and never logs me in."
        - Summary: "Login page fails to authenticate with valid credentials and shows infinite spinner"

        - User: "Found a typo in the docs - says 'recieve' instead of 'receive' on the API page"
        - Summary: "Spelling error in API documentation: 'recieve' should be 'receive'"

      - Keep summary to 1-2 sentences
      - Focus on the problem, not the solution
      - Use present tense, active voice

   c. **Generate slug**: Convert summary to kebab-case filename
      - **Transformation rules**:
        - Lowercase all letters
        - Replace spaces with hyphens
        - Remove special characters except hyphens
        - Limit to 5-8 words max (truncate if needed)

      - **Examples**:
        - Summary: "Login page fails to authenticate with valid credentials"
        - Slug: "login-page-fails-to-authenticate"

        - Summary: "API documentation has spelling error"
        - Slug: "api-docs-spelling-error"

   d. **Show for approval**: Display drafted summary and slug to user
      ```markdown
      **Issue Summary**: [drafted summary]
      **Slug**: [generated-slug]

      Does this look correct? (yes to proceed, or provide corrections)
      ```

      - If user says yes/correct/looks good → proceed to step 4
      - If user provides corrections → update summary/slug and re-show
      - If user is unclear → ask specifically what to change

4. **Option B - Screenshot path**:

   a. **Collect screenshot path**: Ask for screenshot file path
      - **Ask**: "Please provide the path to the screenshot file"
      - Accept relative or absolute paths
      - Validation: File must exist and be readable
      - If file not found, ERROR "Screenshot file not found: [path]"

   b. **Read screenshot with vision API**: Use Read tool to analyze screenshot
      - Read the image file
      - Agent should observe what's shown in the screenshot
      - Look for: error messages, visual glitches, unexpected behavior, UI problems

   c. **Extract issue information**: Draft Issue Summary from screenshot content
      - Describe what you see in the screenshot
      - Focus on the problem/bug visible
      - Be specific: error messages, broken layout, missing elements
      - Keep to 1-2 sentences

      - **Example**:
        - Screenshot shows: Error dialog with "500 Internal Server Error" and stack trace
        - Summary: "API returns 500 error when submitting user profile form"

   d. **Generate slug**: Convert summary to kebab-case (same rules as Option A)

   e. **Show for approval**: Display drafted summary and slug
      ```markdown
      **From screenshot**: [path]
      **Issue Summary**: [drafted summary]
      **Slug**: [generated-slug]

      Does this look correct? (yes to proceed, or provide corrections)
      ```

4. **Option C - Agent synthesis from conversation (if user chooses Option C)**:

   a. **Review conversation context**: Review conversation history to understand the issue

   b. **Draft Issue Summary**: Create concise summary from conversation context
      - Extract the problem discussed in recent messages
      - Focus on what's broken or needs fixing
      - Keep to 1-2 sentences
      - Use present tense, active voice

   c. **Generate slug**: Convert summary to kebab-case filename (same rules as Option A)

   d. **Show for approval**: Display drafted summary and slug
      ```markdown
      Based on our conversation, let me draft the issue:

      **Issue Summary**: [drafted summary]
      **Slug**: [generated-slug]

      Does this accurately capture the issue?
      ```

   e. **Handle feedback**: If user approves, proceed to Step 5; if user requests changes, revise and show again

   **Example**:
   ```
   User: You describe it based on our conversation

   Agent: Based on our discussion, let me draft the issue:

   **Issue Summary**: The /specify command ignores specs in deployed/ and archived/ folders when determining next spec number, causing numbering gaps

   **Slug**: specify-ignores-deployed-archived-numbering

   Does this accurately capture the issue?

   User: Perfect

   Agent: [Proceeds to Step 5]
   ```

5. **Invoke creation script**: Call create-issue.sh with collected parameters

   **Script invocation**:
   ```bash
   .spectri/scripts/spectri-quality/create-issue.sh \
     --slug "[slug]" \
     --priority "[priority]" \
     --summary "[summary]" \
     --agent "$AGENT_SESSION_ID" \
     --target-repo "[spectri|current]" \
     [--screenshot "[screenshot-path]"]  # Only if Option B
   ```

   **Parameters**:
   - `--slug`: Generated kebab-case slug
   - `--priority`: User-specified priority (critical/high/medium/low)
   - `--summary`: Drafted Issue Summary text
   - `--agent`: Current session ID (from environment or "unknown")
   - `--target-repo`: Target repository (`spectri` or `current`, default: `current`)
   - `--screenshot`: Screenshot path (only for Option B)

   **Error handling**:
   - If script returns non-zero exit code, ERROR "Failed to create issue: [error message]"
   - If script output doesn't contain file path, ERROR "Issue creation failed - no file path returned"

6. **Detail completion (conditional)**: Behavior depends on which input method was chosen

   **Step 6A - For Option A (verbal) or Option B (screenshot)**:

   Ask the user if they want to complete details now or defer:
   ```
   Would you like to fill in the detailed sections now (Expected Behaviour, Current Behaviour, Steps to Reproduce, Proposed Fix)?

   A) Yes, I have context now - let's complete it
   B) No, defer for later
   ```

   **If user chooses A (complete now)**:
   - Read the created issue file
   - Ask user for each section:
     * **Expected Behaviour**: What should happen?
     * **Current Behaviour**: What actually happens?
     * **Steps to Reproduce**: How to trigger the issue?
     * **Proposed Fix**: Suggested solution (optional, can be skipped)
   - Update the issue file with provided details
   - Change status from `identified` to `open`
   - Report: "Issue details completed and status updated to 'open'. The issue is now ready to be worked on."

   **If user chooses B (defer)**:
   - Report: "Issue created: [file-path]. Status: identified. The issue can be completed later by manually editing the file."

   **Step 6B - For Option C (agent synthesis)**:

   **Do NOT ask user** whether to complete details. Automatically complete using conversation context:

   1. Read the created issue file
   2. Inform user: "I'll now complete the issue details based on our conversation context."
   3. Review conversation history to extract:
      - **Expected Behaviour**: What should happen (infer from discussion)
      - **Current Behaviour**: What actually happens (the problem discussed)
      - **Steps to Reproduce**: How to trigger the issue (based on conversation)
      - **Proposed Fix**: Suggested solution (if discussed, or propose based on conversation)
   4. Draft all four sections and show for approval:
      ```
      **Expected Behaviour**: [your draft]

      **Current Behaviour**: [your draft]

      **Steps to Reproduce**: [your draft]

      **Proposed Fix**: [your draft]

      Does this accurately capture the issue details?
      ```
   5. If user approves:
      - Update the issue file with details
      - Change status from `identified` to `open`
      - Report: "Issue details completed and status updated to 'open'. The issue is now ready to be worked on."
   6. If user requests changes:
      - Revise sections based on feedback
      - Show updated version for approval
      - Repeat until approved

   **Why automatic for Option C**: When using agent synthesis, the agent already has conversation context. Asking to defer would lose that context, making it impossible to complete the issue later without re-explaining everything. Therefore, must complete details while context is available.

---

## Fix Flow

Goal: Orchestrate the entire fix process — read issue, implement the fix, resolve the issue, and commit everything in a single atomic commit. Git history is the authoritative record of which commit resolved the issue.

**Context**: Use this when the agent will do the fix work right now. The fix code and resolved issue file must land in the same commit.

**Prerequisites**: At least one open issue must exist

**Constraints**:
- Never commit fix code separately from the resolved issue file
- No commit hash is required — git history serves as the record

### Steps

1. **Identify the issue to fix**

   If the user provided a filename or slug, locate it:
   ```bash
   ls spectri/issues/*<slug>*.md 2>/dev/null
   ```

   If not provided, list open issues and ask user to pick:
   ```bash
   ls spectri/issues/2026-*.md
   ```

   Read the issue file to understand what needs to be done (Tasks and Proposed Fix sections).

2. **Implement the fix**

   Perform the work described in the issue:
   - Read the Proposed Fix and Tasks sections
   - Implement the changes required
   - Run any relevant tests

3. **Gather resolution notes**

   Ask the user for (or infer from the fix work done):
   - **Notes**: Brief description of what was changed and how it resolves the issue
   - **Spec updates needed?**: Did the fix reveal specs that need updating?

4. **Run the resolve script**

   ```bash
   bash .spectri/scripts/spectri-quality/resolve-issue.sh \
     "<issue-file-path>" \
     --notes "<resolution notes>" \
     [--spec-needs-update]
   ```

   The script will:
   - Set `status: resolved` and `closed: <today>` in frontmatter
   - Replace the Resolution section with provided details
   - Move the file to `spectri/issues/resolved/`
   - Stage the issue file with `git add`

5. **Stage all fix files**

   Stage all modified/created files from the fix work alongside the already-staged resolved issue:
   ```bash
   git add <all modified/created fix files>
   ```

   Confirm everything is staged: `git status`

6. **Commit in one operation**

   ```bash
   git commit -m "fix: resolve <issue-slug>

   <brief description of what was fixed>"
   ```

7. **Report**: "Fix complete. Issue resolved and committed in a single commit alongside the fix code."

---

## Update Flow

Goal: Modify existing issue fields through the command system, preserving historical metadata and maintaining consistent Date Updated timestamps.

**Context**: Issues evolve as work progresses. Priority changes, new context emerges, specs get linked, blockers appear. This flow enables sanctioned updates without manual file editing.

**Prerequisites**: At least one open issue must exist

**Constraints**:
- Cannot modify status (use lifecycle scripts: resolve-issue.sh, reopen-issue.sh)
- Cannot modify historical fields (created_by_agent, created_by_user, opened, closed)
- Must update Date Updated frontmatter field

### Steps

1. **Identify the issue to update**

   If the user provided a filename or slug, use it:
   ```bash
   ls spectri/issues/*<slug>*.md 2>/dev/null
   ```

   If not provided, the script will list open issues and prompt for selection.

2. **Collect field updates**

   The script will:
   - Display current values for all updatable fields
   - Prompt for new values (Enter to keep current)
   - Validate priority if changed (critical/high/medium/low)
   - Validate blocked if changed (true/false)

   **Updatable fields**:
   - `priority`: Issue severity (critical/high/medium/low)
   - `summary`: Issue description text
   - `blocked`: Whether issue is blocked (true/false)
   - `blocker_info`: Description of what's blocking progress
   - `related_specs`: Comma-separated spec numbers
   - `related_tests`: Comma-separated test paths
   - `related_files`: Comma-separated file paths

3. **Run the update script**

   ```bash
   bash .spectri/scripts/spectri-quality/update-issue.sh "<issue-file-path>"
   ```

   Or with slug:
   ```bash
   bash .spectri/scripts/spectri-quality/update-issue.sh --slug "<slug>"
   ```

   The script will:
   - Display current field values
   - Collect updates interactively
   - Update the issue file
   - Update Date Updated frontmatter timestamp
   - Stage changes with `git add`

4. **Commit the update**

   ```bash
   git commit -m "chore(issue): update <issue-slug>

   - Updated fields: <list-of-changed-fields>"
   ```

5. **Report**: "Issue updated: `spectri/issues/<filename>`. Changes committed."

### Update Scenarios

**Scenario 1 - Priority escalation**:
```
User: Update issue login-page-fails-to-authenticate to high priority

Agent: [Runs update script with slug]
Agent: Issue updated. Priority changed from medium to high.
```

**Scenario 2 - Add blocker**:
```
User: Mark the API issue as blocked - waiting for backend team

Agent: [Runs update script, sets blocked=true, blocker_info="Waiting for backend team API changes"]
Agent: Issue updated. Marked as blocked.
```

**Scenario 3 - Link related spec**:
```
User: Link spec 042 to the dashboard-slow-load issue

Agent: [Runs update script, adds "042" to related_specs]
Agent: Issue updated. Linked to spec 042.
```

### Anti-Patterns to Avoid

**Don't bypass the command system**: Manual edits risk inconsistent metadata updates. Always use `/spec.issue update`.

**Don't modify status directly**: Use lifecycle scripts (resolve-issue.sh, reopen-issue.sh) for status changes.

**Don't skip commit**: Every update must be committed immediately to maintain audit trail.

---

## Resolve Flow

Goal: Mark an issue as resolved, fill in the Resolution section, and move it to `spectri/issues/resolved/`.

### Steps

1. **Identify the issue file**

   If the user provided a filename or slug, locate it:
   ```bash
   ls spectri/issues/*<slug>* 2>/dev/null
   ```

   If not provided, list open issues and ask user to pick:
   ```bash
   ls spectri/issues/2026-*.md
   ```

2. **Gather resolution details**

   Ask the user for (or infer from conversation context):
   - **Notes**: Brief description of how it was resolved
   - **Spec updates needed?**: Did the fix reveal specs that need updating?

3. **Run the resolve script**

   ```bash
   bash .spectri/scripts/spectri-quality/resolve-issue.sh \
     "<issue-file-path>" \
     --notes "<resolution notes>" \
     [--spec-needs-update]
   ```

   Add `--spec-needs-update` flag if specs need updating.

   The script will:
   - Set `status: resolved` and `closed: <today>` in frontmatter
   - Replace the Resolution section with provided details
   - Move the file to `spectri/issues/resolved/`
   - Stage the changes with `git add`

4. **Commit the resolution**

   ```bash
   git commit -m "fix(issue): resolve <issue-slug>"
   ```

5. **Report**: "Issue resolved and moved to `spectri/issues/resolved/<filename>`. Changes committed."

---

## Pedagogical Patterns

### Decision Framework: Choosing Priority

When users are unsure about priority, guide them with these questions:

1. **Does it block work?** → Yes = critical or high, No = medium or low
2. **How many people affected?** → All users = higher priority, One user = lower priority
3. **Is data at risk?** → Yes = critical, No = evaluate other factors
4. **Can users work around it?** → No workaround = higher priority, Easy workaround = lower priority

**Anti-patterns to avoid**:
- Don't default everything to "high" - this devalues the priority system
- Don't let users skip priority - it's required for proper triage
- Don't make priority judgments for the user - guide them to decide

### Transformation Examples: Description → Summary

**Good transformations** (concise, problem-focused):
- User: "When I click the save button nothing happens and I lose my work" → Summary: "Save button fails silently causing data loss"
- User: "The dashboard is really slow, takes like 30 seconds to load" → Summary: "Dashboard page has 30+ second load time"
- User: "Getting 404 errors when trying to view user profiles" → Summary: "User profile pages return 404 errors"

**Bad transformations** (too vague or solution-focused):
- User: "Login is broken" → Summary: "Login issue" ❌ (too vague, needs detail)
- User: "We should add error handling to the API" → Summary: "Add error handling to API" ❌ (this is an enhancement, not an issue - ask user what's broken)

### Anti-Patterns to Avoid

**Don't skip approval**: Always show drafted summary/slug for user confirmation. Users may have important context you missed.

**Don't over-engineer the summary**: Keep it simple. Triage will add full details later. Capture just enough to identify the problem.

**Don't force users into one input method**: Some issues are easier to describe verbally, others with screenshots. Let user choose.

**Don't lose context from screenshots**: When processing screenshots, include relevant error codes, messages, or visual details in the summary.

---

## Behavior Rules

- If user provides incomplete information, prompt for required fields (don't guess)
- If priority is unclear, present criteria table and ask user to decide
- For screenshot input, always use Read tool to view the image (don't ask user to describe it)
- Status progression: Start as `identified`, update to `open` if details completed in Step 6. Valid statuses: `identified | open | resolved | reopened | awaiting-spec-update | spec-updated`
- Always capture $AGENT_SESSION_ID if available for attribution

---

## References

- Issue Template: `.spectri/templates/spectri-quality/issue-template.md`
- Creation Script: `.spectri/scripts/spectri-quality/create-issue.sh`
- Resolve Script: `.spectri/scripts/spectri-quality/resolve-issue.sh`
- Issue Schema: `spectri/specs/04-deployed/020-issue-module/spec.md`

<!-- INJECT: post-finalization -->
