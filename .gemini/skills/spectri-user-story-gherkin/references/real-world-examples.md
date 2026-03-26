# Real-World Examples

Production-tested user stories from actual deployed specs. These examples have been generalized to apply across domains while preserving the patterns that made them effective.

---

## Example 1: Interactive Approval Workflow (Progressive Review)

**User Story:**

> As a developer, I want requirements presented one at a time for my approval so that I can review each carefully and catch misunderstandings early rather than being overwhelmed by a complete specification.

**Why this priority (P1):** Prevents requirement misunderstandings that are expensive to fix after implementation. Progressive review enables course correction early.

**Independent Test:** Generate multiple requirements, present first one, verify system waits for explicit approval before presenting second.

**Acceptance Scenarios:**

```gherkin
Given the system has multiple requirements to present
When the first requirement is generated
Then only that single requirement is shown and the system waits for explicit approval, rejection, or revision feedback
And no additional requirements are presented until the current one is resolved
```

**Why this is good:**
- Teaches progressive review pattern
- Clear single action (present one requirement)
- Observable outcome (waits for approval)
- Applies to any workflow with sequential review

---

## Example 2: Test-First Development (TDD Integration)

**User Story:**

> As a developer, I want test tasks automatically included before implementation tasks so that every code-producing feature follows test-first development.

**Why this priority (P1):** Prevents post-implementation testing gaps. Tests written first define success criteria before code exists.

**Independent Test:** Generate task list for code-producing feature, verify test tasks appear before implementation tasks.

**Acceptance Scenarios:**

```gherkin
Given a feature specification with code-producing requirements (API, UI, data processing)
When the task list is generated
Then each feature phase contains a "Tests" subsection before the "Implementation" subsection
And test tasks define success criteria before implementation begins
```

**Why this is good:**
- Teaches TDD enforcement pattern
- Specific precondition (code-producing requirements)
- Testable outcome (tests before implementation)
- Universal across all codebases

---

## Example 3: Dynamic Clarifying Questions (Adaptive Requirements)

**User Story:**

> As a developer, I want the system to ask targeted clarifying questions before proceeding so that ambiguous requirements are resolved early rather than assumed.

**Why this priority (P1):** Prevents building the wrong thing. Early clarification is 10x cheaper than rework.

**Independent Test:** Provide ambiguous requirement, verify system generates relevant clarifying questions, confirm answers are incorporated.

**Acceptance Scenarios:**

```gherkin
Given a requirement with ambiguous elements
When the system analyzes the requirement
Then it generates up to 3 contextual clarifying questions based on identified gaps
And questions target high-impact ambiguities (scope, security, user experience)
And the system waits for answers before proceeding
```

**Why this is good:**
- Teaches adaptive requirements gathering
- Specific constraint (up to 3 questions, prioritized)
- Observable outcome (waits for answers)
- Applies to any requirements process

---

## Example 4: Checkpoint Validation (Early Course Correction)

**User Story:**

> As a developer, I want to review and approve high-level phases before detailed planning begins so that I can course-correct the approach early rather than after significant work is done.

**Why this priority (P1):** Prevents detailed work on wrong approach. High-level validation is fast, detailed rework is expensive.

**Independent Test:** Generate high-level phases, present for approval, verify detailed work only starts after approval.

**Acceptance Scenarios:**

```gherkin
Given a specification with multiple user stories and requirements
When the checkpoint validation runs
Then implementation phases are extracted and presented in a table with names and descriptions
And the system waits for approval before generating detailed plans
And the developer can reject phases and request alternative approaches
```

**Why this is good:**
- Teaches checkpoint pattern
- Clear gate (approval before detail)
- Enables early course correction
- Universal project management pattern

---

## Example 5: Load Design Artifacts (Follow Architecture)

**User Story:**

> As a developer, I want the system to read all available design artifacts before implementation so that work follows the planned architecture rather than improvising.

**Why this priority (P2):** Prevents architecture drift. Design decisions should drive implementation, not be discovered retroactively.

**Independent Test:** Create design artifacts (architecture, data model, contracts), verify implementation references and follows them.

**Acceptance Scenarios:**

```gherkin
Given design artifacts exist (architecture plan, data model, API contracts, research)
When implementation starts
Then the system reads and incorporates all design artifacts
And implementation decisions reference the planned architecture
And deviations from design are flagged for review
```

**Why this is good:**
- Teaches design-driven development
- Specific about what gets loaded
- Prevents improvisation
- Universal across technical projects

---

## Example 6: Document Synchronization (Change Propagation)

**User Story:**

> As a developer who has updated requirements, I want related planning documents to be updated to reflect those changes so that my implementation approach stays aligned with the specification.

**Why this priority (P1):** Prevents planning drift. Requirements and plans must stay synchronized or implementation targets the wrong spec.

**Independent Test:** Update requirements, run sync, verify plan reflects changes with clear diff of what changed.

**Acceptance Scenarios:**

```gherkin
Given requirements have been updated since the plan was last modified
When the synchronization process runs
Then the system displays a diff showing what changed in requirements since the last plan update
And affected sections of the plan are identified
And the developer can review and approve propagated changes
```

**Why this is good:**
- Teaches document sync pattern
- Shows what changed (diff)
- Requires approval (no auto-sync)
- Universal for any multi-document workflow

---

## Example 7: Automatic Metadata Updates (Audit Trail)

**User Story:**

> As a developer, I want document metadata automatically updated when I make revisions so that documents always reflect when and by whom they were last modified.

**Why this priority (P1):** Enables audit trails. Manual metadata updates are forgotten; automatic updates are reliable.

**Independent Test:** Modify document, verify metadata updated with current timestamp and author.

**Acceptance Scenarios:**

```gherkin
Given a document revision is made
When the update process completes
Then the "Date Updated" field contains the current ISO timestamp
And the "updated_by" field contains the current session identifier
And the previous metadata values are preserved in version history
```

**Why this is good:**
- Teaches audit trail automation
- Specific metadata fields
- Preserves history
- Universal documentation pattern

---

## Example 8: Identify Underspecified Areas (Quality Check)

**User Story:**

> As a developer, I want the system to scan my specification for ambiguous or missing decision points so that I can address gaps before work begins.

**Why this priority (P1):** Prevents implementation blockers. Gaps discovered during coding cause delays; gaps found during spec review are cheap to fix.

**Independent Test:** Create specification with known gaps, run scanner, verify all gaps are identified and categorized.

**Acceptance Scenarios:**

```gherkin
Given a feature specification with some underspecified areas
When the quality check runs
Then the system identifies which specification categories are Clear, Partial, or Missing
And each gap is flagged with severity (blocking vs. nice-to-have)
And the developer receives a prioritized list of areas needing clarification
```

**Why this is good:**
- Teaches proactive quality checking
- Categorizes gaps (not binary pass/fail)
- Prioritizes by severity
- Universal spec quality pattern

---

## Example 9: Progressive Refinement (Iterative Improvement)

**User Story:**

> As a developer, I want each clarification answer to be immediately written back into the specification so that the spec is progressively refined during the session.

**Why this priority (P1):** Prevents clarification loss. Answers captured in conversation but not in docs are forgotten.

**Independent Test:** Answer clarifying question, verify answer is incorporated into relevant spec section immediately.

**Acceptance Scenarios:**

```gherkin
Given the developer answers a clarifying question about feature scope
When the answer is accepted
Then the clarification is logged in session history
And the relevant specification section is updated with the clarification
And the updated section is presented for review
```

**Why this is good:**
- Teaches progressive refinement
- Immediate feedback (shows updated section)
- Prevents information loss
- Universal for any iterative process

---

## Example 10: Decision Documentation (Rationale Capture)

**User Story:**

> As a developer or team member resuming work from a previous session, I need documentation to capture the reasoning and decisions made so that context is preserved across session boundaries and team handoffs.

**Why this priority (P1):** Prevents context loss. "Why did we do it this way?" questions cause delays and second-guessing.

**Independent Test:** Make design decision, document it, verify documentation includes decision, rationale, and alternatives considered.

**Acceptance Scenarios:**

```gherkin
Given a design decision is made during implementation
When the decision is documented
Then the summary includes: the decision made, the rationale, and alternatives considered
And the documentation is timestamped and attributed to the decision maker
And future sessions can reference the decision without needing to re-discuss
```

**Why this is good:**
- Teaches decision documentation
- Specific structure (decision + rationale + alternatives)
- Enables future reference
- Universal team collaboration pattern

---

## Example 11: Quality Gates (Documentation Before Commit)

**User Story:**

> As a team lead, I want commits to require documentation so that every piece of work is explained for audit trails and team awareness.

**Why this priority (P1):** Prevents undocumented changes. Code without context is technical debt.

**Independent Test:** Stage changes without documentation, attempt commit, verify commit is blocked until documentation is added.

**Acceptance Scenarios:**

```gherkin
Given code changes are staged without accompanying documentation
When the developer attempts to commit
Then the commit is blocked with instructions to create documentation
And the block message identifies what documentation is required
And the commit succeeds only after documentation is added
```

**Why this is good:**
- Teaches quality gate enforcement
- Clear failure mode (blocked commit)
- Guides user to fix (shows what's required)
- Universal for any documented codebase

---

## Example 12: Drift Detection (Deployed vs Source)

**User Story:**

> As a developer, I want to verify that deployed artifacts match their source definitions so that manual edits or sync failures are detected before they cause problems.

**Why this priority (P2):** Prevents configuration drift. Deployed artifacts that don't match source create debugging nightmares.

**Independent Test:** Manually edit deployed artifact, run verification, verify drift is detected and reported with specific diff.

**Acceptance Scenarios:**

```gherkin
Given all deployed artifacts match their source definitions
When the drift detection runs
Then the system reports no differences
And verification passes with exit code 0

Given a deployed artifact was manually edited
When the drift detection runs
Then the system identifies which artifact differs
And the output shows the specific lines that differ
And verification fails with exit code 1
```

**Why this is good:**
- Teaches drift detection pattern
- Tests both success and failure cases
- Specific output (diff, exit codes)
- Universal deployment pattern

---

## Example 13: Build Integrity (Source Matches Output)

**User Story:**

> As a developer modifying build sources, I want to verify that build output matches source definitions so that drift is detected before deployment.

**Why this priority (P2):** Prevents stale builds. Build output should always reflect current source; drift means the build is broken.

**Independent Test:** Modify source, run build, verify output matches, verify check passes. Modify output manually, verify check fails.

**Acceptance Scenarios:**

```gherkin
Given source files and build output are in sync
When the build verification runs
Then verification passes with no differences reported
And the verification log shows all checked files

Given build output was manually edited
When the build verification runs
Then verification fails and identifies the modified files
And the output shows the diff between source-derived and actual output
```

**Why this is good:**
- Teaches build integrity checking
- Tests success and failure
- Specific about what's checked
- Universal build system pattern

---

## Example 14: Automated Task Execution (Task List Workflow)

**User Story:**

> As a developer, I want to execute all defined tasks automatically so that planned work is completed according to specification without manual tracking.

**Why this priority (P1):** Prevents forgotten tasks. Manual tracking creates gaps; automated execution ensures completeness.

**Independent Test:** Create task list with multiple phases, execute automation, verify all tasks are completed and marked.

**Acceptance Scenarios:**

```gherkin
Given a task list with 3 phases and 12 tasks
When the automated execution runs
Then all phases execute sequentially in order
And all tasks are marked complete upon successful execution
And execution stops if a task fails, with clear error reporting
```

**Why this is good:**
- Teaches automated workflow execution
- Sequential phases (clear order)
- Clear failure mode (stops on error)
- Universal task automation pattern

---

## Example 15: Semantic Versioning (Version Discipline)

**User Story:**

> As a developer, I want version numbers automatically managed using semantic versioning so that the impact of each change is clearly communicated.

**Why this priority (P1):** Prevents version confusion. Semantic versions communicate impact; arbitrary versions communicate nothing.

**Independent Test:** Make patch-level change, verify patch version increments. Make breaking change, verify major version increments.

**Acceptance Scenarios:**

```gherkin
Given a clarification or typo fix is applied
When the version is updated
Then only the patch version increments (1.0.0 → 1.0.1)

Given a breaking change is introduced
When the version is updated
Then the major version increments (1.0.0 → 2.0.0)
And the minor and patch versions reset to zero
```

**Why this is good:**
- Teaches semantic versioning discipline
- Specific about increment rules
- Shows multiple scenarios (patch vs major)
- Universal versioning pattern

---

## Common Patterns Across Examples

**What makes these effective**:

1. **Specific preconditions**: Given states are concrete, not vague
2. **Single actions**: When describes one clear trigger
3. **Observable outcomes**: Then states are testable, not capabilities
4. **Business value**: "So that..." explains real impact
5. **Independent tests**: Verification method is explicit
6. **Priority justification**: "Why this priority" has business reasoning

**Universal patterns demonstrated**:

- Progressive review (present one item at a time)
- Quality gates (block until criteria met)
- Drift detection (source vs deployed)
- Adaptive behavior (ask questions based on context)
- Audit trails (automatic metadata)
- Document synchronization (propagate changes)
- Decision documentation (capture rationale)
- Test-first discipline (tests before implementation)
