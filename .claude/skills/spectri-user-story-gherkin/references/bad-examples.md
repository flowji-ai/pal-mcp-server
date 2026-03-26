# Bad Examples

Common failures in user story writing with explanations and fixes.

---

## Anti-Pattern 1: The Mechanics Focus

**Bad:**

> As a user,
> I want to click the Save button,
> So that my data is saved.

**Problems:**
- Generic persona ("user")
- Describes UI mechanics, not goal
- Circular value statement (save so data is saved)

**Fixed:**

> As a content author,
> I want my draft to be preserved automatically,
> So that I don't lose work if my browser crashes.

---

## Anti-Pattern 2: Existence Without Quality

**Bad:**

```gherkin
Given the user has items in their cart
When they proceed to checkout
Then an order is created
```

**Problem:** "An order is created" says nothing about what makes a valid order.

**Fixed:**

```gherkin
Given the user has 3 items in their cart totalling $150
When they complete checkout with valid payment
Then an order is created containing:
  - All 3 items with correct prices
  - Shipping address from user profile
  - Order confirmation number
  - Estimated delivery date
And the user receives a confirmation email with order details
```

---

## Anti-Pattern 3: Action Disguised as Given

**Bad:**

```gherkin
Given the user creates a new project
When they add team members
Then the team members can access the project
```

**Problem:** "Given the user creates" is an action, not a precondition. The Given should describe a state that exists BEFORE the When.

**Fixed:**

```gherkin
Given a project exists with the user as owner
When they add a team member with "Editor" role
Then the team member appears in the project roster
And the team member can access and edit project files
```

---

## Anti-Pattern 4: Completed Action as Given

**Bad:**

```gherkin
Given I have edited the "# Specs Folder" section in the source file
When I run the build script
Then the target is updated
```

**Problem:** "I have edited" describes a completed action, not a state. The test doesn't care who edited or when — it cares that modifications exist.

**Fixed:**

```gherkin
Given the "# Specs Folder" section in the source file has been modified
When I run the build script
Then the target is updated to match the source
```

---

## Anti-Pattern 5: Ongoing Action as Given

**Bad:**

```gherkin
Given I am adding a command list to the section
When I attempt to save
Then the system warns me
```

**Problem:** "I am adding" describes an action in progress. Given should describe the state before the When triggers.

**Fixed:**

```gherkin
Given the draft section contains a command list
When I attempt to save
Then the system warns against the anti-pattern
```

---

## Anti-Pattern 6: Desire as Given

**Bad:**

```gherkin
Given I want to build commands, skills, and SPECTRI files
When I run build-sync-commit.sh
Then all three are built
```

**Problem:** "I want to" describes intent, not precondition. What's the actual state?

**Fixed:**

```gherkin
Given commands, skills, and SPECTRI source files all have pending changes
When I run build-sync-commit.sh
Then all three are built in sequence
```

---

## Anti-Pattern 7: Vague When Verbs

**Bad:**

```gherkin
Given drift exists in the target file
When I look up the differences
Then I see what changed
```

**Problem:** "Look up" is vague. Open a file? Run a command? Search?

**Fixed:**

```gherkin
Given drift exists in the target file
When I run drift detection
Then the output lists the specific lines that differ
```

**Vague verbs to avoid:** look up, check, review, examine, verify, see

---

## Anti-Pattern 8: Observation as When

**Bad:**

```gherkin
Given I have run the build script
When I check the output
Then I see a summary of changes
```

**Problem:** "Check the output" is observation, not action. The action (running the build) already happened. Observation belongs in Then.

**Fixed:**

```gherkin
Given the source file contains changes to deploy
When I run the build script
Then I see a summary listing which files were updated
```

---

## Anti-Pattern 9: Backwards Given/When

**Bad:**

```gherkin
Given I run /spectri.update-spectri
When the source file is valid
Then the build executes
```

**Problem:** Running the command is the action (When). File validity is the precondition (Given). They're reversed.

**Fixed:**

```gherkin
Given the source file is valid
When I run /spectri.update-spectri
Then the build executes
And all targets are updated
```

---

## Anti-Pattern 10: System-Event When

**Bad:**

```gherkin
Given I am editing SPECTRI.md content
When the skill activates
Then it provides guidance
```

**Problem:** "Skill activates" is an internal system state, not a user action. The user does something; the skill responds.

**Fixed:**

```gherkin
Given I am working in the source file
When I ask what belongs in this section
Then the skill explains the content guidelines
```

---

## Anti-Pattern 11: Capability Then

**Bad:**

```gherkin
Given drift is detected
When I review the warning
Then I can decide to merge or discard the changes
```

**Problem:** "I can decide" is a capability, not an observable outcome. Decisions happen in the user's head — tests observe system behaviour.

**Fixed:**

```gherkin
Given drift is detected
When drift detection completes
Then the output shows merge and discard options with instructions for each
```

---

## Anti-Pattern 12: The Tautology Trap

**Bad:**

```gherkin
Given the system is working correctly
When the user performs the action
Then the expected result occurs
```

**Problem:** This says nothing. "System working" is assumed. "Expected result" is undefined.

**Fixed:**

```gherkin
Given the user has exceeded their monthly API quota
When they attempt another API call
Then the request is rejected with status 429
And the response includes quota reset time
And the user's dashboard shows "Quota Exceeded" status
```

---

## Anti-Pattern 13: Implementation Leakage

**Bad:**

```gherkin
Given the database connection pool has available connections
When the UserService.createUser() method is called with valid parameters
Then a new row is inserted into the users table
And the method returns the new user ID
```

**Problem:** Exposes database, service classes, and methods. This is a technical specification, not a user story.

**Fixed:**

```gherkin
Given I am on the registration page
When I submit valid registration details
Then my account is created
And I receive a welcome email
And I can log in with my new credentials
```

---

## Anti-Pattern 14: Fragmented Value

**Bad — spread across 5 stories:**

- Story 1: "As a user, I want to enter my email..."
- Story 2: "As a user, I want to enter my password..."
- Story 3: "As a user, I want to click Register..."
- Story 4: "As a user, I want to receive a verification email..."
- Story 5: "As a user, I want to verify my email..."

**Problem:** No single story owns "successful registration." If Story 3 passes but Story 4 fails, does registration work?

**Fixed — one story owns the outcome:**

> As a new visitor,
> I want to create a verified account,
> So that I can access member features.

With scenarios covering the complete flow, including verification.

---

## Anti-Pattern 15: Overloaded Story

**Bad — 9 scenarios in one story:**

```
Story: Centralized Management
  Scenario 1: Deploy section to target
  Scenario 2: Inject reference
  Scenario 3: Create missing target
  Scenario 4: No changes needed
  Scenario 5: Drift detected
  Scenario 6: Review drift warning
  Scenario 7: Validate section count
  Scenario 8: Validate length
  Scenario 9: Detect anti-patterns
```

**Problem:** This story covers build workflow AND drift detection AND validation. Three different concerns. If Scenario 7 fails, what does that tell you about the build workflow?

**Fixed — split by concern:**

- Story 1: Build and Deploy (scenarios 1-4)
- Story 2: Source File Validation (scenarios 7-9)
- Story 3: Drift Resolution (scenarios 5-6, rewritten)

**Rule of thumb:** If a story has more than 5-6 scenarios, or scenarios test fundamentally different concerns, split it.

---

## Anti-Pattern 16: Vague Validation

**Bad:**

```gherkin
Given a report is generated
When validation runs
Then the report passes quality checks
```

**Problem:** What quality checks? This is untestable.

**Fixed:**

```gherkin
Given a report is generated
When validation runs
Then the report passes all quality checks:
  - No empty sections
  - All date fields in ISO format
  - Total figures match sum of line items
  - All referenced attachments are present
```

---

## Anti-Pattern 17: The Missing Consumer

**Bad:**

```gherkin
Given the export is triggered
When processing completes
Then a CSV file is created in the downloads folder
```

**Problem:** What uses this CSV? What format does it need? Will it actually work when imported elsewhere?

**Fixed:**

```gherkin
Given the export is triggered for the accounting system
When processing completes
Then a CSV file is created with:
  - Headers matching the accounting system's import template
  - Date format: DD/MM/YYYY (accounting system requirement)
  - Currency values as plain numbers without symbols
  - UTF-8 encoding with BOM for Excel compatibility
And the file can be imported into the accounting system without errors
```

---

## Anti-Pattern 18: Compound Outcomes

**Bad:**

```gherkin
Given a support ticket is submitted
When the ticket is processed
Then the ticket is assigned to an agent and the customer receives a confirmation email and the SLA timer starts and the ticket appears in the agent's queue and the priority is calculated based on customer tier and the ticket is logged in the audit trail
```

**Problem:** Six different outcomes in one Then. Impossible to debug which failed.

**Fixed:**

```gherkin
Scenario: Ticket creation and assignment
  Given a Premium customer submits a support ticket
  When the ticket is processed
  Then the ticket is assigned to the Premium Support queue
  And the ticket priority is set to "High" based on customer tier

Scenario: Customer notification
  Given a support ticket is created
  When assignment completes
  Then the customer receives a confirmation email
  And the email includes ticket number and expected response time

Scenario: SLA tracking
  Given a Premium customer ticket is created
  When the SLA timer starts
  Then the response deadline is set to 4 hours from submission
  And the ticket appears in the SLA monitoring dashboard
```

---

## Anti-Pattern 19: No Edge Cases

**Bad:**

```gherkin
Scenario: User uploads a file
  Given I am on the upload page
  When I select a file and click upload
  Then the file is uploaded successfully
```

**Problem:** What about empty files? Wrong format? File too large? Network failure? This only covers the happy path.

**Fixed:**

```gherkin
Scenario: Successful upload
  Given I am on the upload page
  When I upload a valid PDF under 10MB
  Then the file appears in my documents list
  And a success message confirms the upload

### Edge Cases

- What happens when file exceeds 10MB limit?
  Upload is rejected with message showing file size and limit.

- What happens when file type is not supported?
  Upload is rejected with list of supported formats.

- What happens when upload fails mid-transfer?
  Partial upload is discarded. User sees retry option with error details.

- What happens when user uploads duplicate filename?
  System appends timestamp to filename. User is notified of rename.
```

---

## Anti-Pattern 20: Inconsistent Specificity

**Bad:**

```gherkin
Scenario: Fresh repository proceeds
  Given a repository with no existing config
  When user runs `init`
  Then the command proceeds with initialization

Scenario: Existing config detected
  Given a repository with existing `.config/` folder
  When user runs `init`
  Then the command exits with error "Config already exists. Use `sync` to update."

Scenario: Legacy folder detected
  Given a repository with existing `old-config/` folder
  When user runs `init`
  Then the command exits with error "Legacy config found. Run `migrate` instead."
```

**Problem:** Scenarios 2 and 3 have specific error messages. Scenario 1 says "proceeds with initialization" — what does the user actually observe? This inconsistency makes the happy path untestable.

**Fixed:**

```gherkin
Scenario: Fresh repository proceeds
  Given a repository with no existing config
  When user runs `init`
  Then the `.config/` folder is created
  And the command outputs "Initialized successfully"

Scenario: Existing config detected
  Given a repository with existing `.config/` folder
  When user runs `init`
  Then the command exits with error "Config already exists. Use `sync` to update."

Scenario: Legacy folder detected
  Given a repository with existing `old-config/` folder
  When user runs `init`
  Then the command exits with error "Legacy config found. Run `migrate` instead."
```

**Rule:** If error scenarios specify exact messages, happy path scenarios must specify exact observable outcomes.

---

## Anti-Pattern 21: Over-Specification

**Bad:**

```gherkin
Scenario: Complete folder structure created
  Given a fresh repository
  When user runs `init`
  Then `config/` is created with subfolders: `settings/`, `templates/`, `schemas/`, `cache/`, `plugins/enabled/`, `plugins/disabled/`, `plugins/registry/`, `logs/access/`, `logs/error/`, `logs/debug/`, `backup/daily/`, `backup/weekly/`, `backup/monthly/`, each containing a `.gitkeep` file
```

**Problems:**
- Gherkin becomes a technical specification, not a behaviour description
- If folder structure changes, Gherkin must be updated
- Folder list is probably defined elsewhere (template file, docs) — this creates duplication
- Non-technical stakeholder can't understand what success looks like

**Fixed — Option A (reference canonical source):**

```gherkin
Scenario: Complete folder structure created
  Given a fresh repository
  When user runs `init`
  Then the folder structure matches `templates/init-structure.yaml`
  And all empty folders contain a `.gitkeep` file
```

**Fixed — Option B (high-level observable):**

```gherkin
Scenario: Complete folder structure created
  Given a fresh repository
  When user runs `init`
  Then `config/` is created with settings, templates, and plugin subfolders
  And `logs/` is created with access, error, and debug subfolders
  And `backup/` is created with daily, weekly, and monthly subfolders
  And all empty folders contain a `.gitkeep` file
```

**Rule:** Gherkin should describe what the user observes at an appropriate abstraction level. Technical specifications belong in Functional Requirements or reference files.

---

## Anti-Pattern 22: Duplicate Scenarios

**Bad:**

```gherkin
Scenario: Specs folder created
  Given a fresh repository
  When user runs `init`
  Then `specs/` is created with stage subfolders

Scenario: Config folder created
  Given a fresh repository
  When user runs `init`
  Then `.config/` is created with settings subfolders

Scenario: Issues folder created
  Given a fresh repository
  When user runs `init`
  Then `issues/` is created with resolution subfolders
```

**Problem:** Three scenarios with identical Given and When. These aren't testing different behaviours — they're testing different aspects of the same behaviour. This artificially inflates scenario count and creates maintenance burden.

**Fixed:**

```gherkin
Scenario: Complete folder structure created
  Given a fresh repository
  When user runs `init`
  Then `specs/` is created with stage subfolders
  And `.config/` is created with settings subfolders
  And `issues/` is created with resolution subfolders
  And all empty folders contain a `.gitkeep` file
```

**Rule:** If scenarios share the same Given and When, they should be one scenario with multiple And statements in the Then. Separate scenarios are for different triggers or different preconditions.

---

## Anti-Pattern 23: Hardcoded Growing Lists

**Bad:**

```gherkin
Scenario: Config files deployed
  Given a fresh repository
  When user runs `init`
  Then config files are created at:
    - /CONFIG.md
    - /src/CONFIG.md
    - /tests/CONFIG.md
    - /docs/CONFIG.md
```

**Problem:** These locations are defined in a deployment script or manifest. When you add `/api/CONFIG.md` next month:
- The script handles it automatically
- The Gherkin is now incomplete
- Someone has to remember to update the test
- If they forget, the test passes but doesn't verify the new location

This is worse than over-specification — it's a maintenance trap that silently degrades test coverage.

**Fixed:**

```gherkin
Scenario: Config files deployed
  Given a fresh repository
  When user runs `init`
  Then config files are deployed to all configured target locations
  And the deployment log lists each file created
```

**The test:** Ask yourself:
1. Is this list defined somewhere else (script, config, manifest)?
2. Will this list grow as the system evolves?

If yes to both → reference the source of truth, don't enumerate.

**When enumeration IS acceptable:**
- Fixed, stable lists that won't change (e.g., HTTP status codes, days of week)
- User-facing options that ARE the contract (e.g., specific error messages)
- When the Gherkin IS the source of truth (no script/config exists)
