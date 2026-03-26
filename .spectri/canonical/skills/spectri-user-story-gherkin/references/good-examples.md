# Good Examples

Well-structured user stories demonstrating the five principles.

---

## Persona Examples

Using "The User" leads to vague specs. Every story needs a specific persona to provide motivation and context.

| Persona | Motivation | Example Intent |
| :--- | :--- | :--- |
| **The Novice** | Safety & Guidance | "Help me finish this without breaking anything." |
| **The Power User** | Efficiency & Speed | "Let me use keyboard shortcuts to bypass menus." |
| **The Auditor** | Integrity & History | "Show me exactly who changed this and when." |
| **The Gatekeeper** | Risk Mitigation | "Ensure only approved eyes see this sensitive data." |

**The Formula:**

> **As a** `<Specific Persona>`
>
> **I want** to `<Action that changes system state>`
>
> **So that** `<I achieve a measurable benefit>`

---

## Example 1: Subscription Pause (Core Value Ownership)

**User Story:**

> As a Premium Subscriber,
> I want to pause my subscription for up to 3 months,
> So that I don't pay for the service while on vacation without losing my billing setup.

**Why this priority (P1):** Core retention feature — users currently cancel and never return. Pause option keeps them in the ecosystem.

**Independent Test:** Create a subscription, initiate pause for 60 days, verify billing stops and resumes automatically.

**Acceptance Scenarios:**

```gherkin
Scenario: Successful pause initiation
  Given I have an active monthly subscription
  And I am on the Billing Settings page
  When I select a 2-month pause period and confirm
  Then my subscription status changes to "Paused"
  And my next billing date is set to 60 days from today
  And I receive a confirmation email with the resume date

Scenario: Pause limit enforcement
  Given I am selecting a pause duration
  When I attempt to select more than 90 days
  Then the selection is prevented
  And a message explains the maximum pause is 3 months

Scenario: Early resume
  Given my subscription is currently paused
  When I choose to resume early
  Then billing resumes from the next billing cycle
  And my subscription status changes to "Active"
```

**Why this is good:**
- Story owns the outcome (retention), not the mechanism (a pause button)
- "So that..." expresses real business value
- Each Then has specific, observable criteria
- Scenarios cover happy path, boundary, and alternative flow

---

## Example 2: Invoice Generation (Quality Over Existence)

**User Story:**

> As a Finance Manager,
> I want to generate monthly invoices for all active clients,
> So that billing is consistent and audit-ready without manual document creation.

**Why this priority (P1):** Revenue recognition depends on timely, accurate invoices. Manual process currently takes 2 days and has error rate.

**Independent Test:** Trigger invoice generation for a client with 3 line items, verify PDF contains all required fields and calculations.

**Acceptance Scenarios:**

```gherkin
Scenario: Complete invoice generation
  Given a client has 3 billable items totalling $1,500
  And the client has tax ID and payment terms on file
  When monthly invoice generation runs
  Then an invoice PDF is created containing:
    | Field | Requirement |
    | Line items | All 3 items with descriptions and amounts |
    | Subtotal | Sum of line items |
    | Tax | Calculated based on client's tax jurisdiction |
    | Total | Subtotal plus tax |
    | Payment terms | Client's configured terms (Net 30, etc.) |
    | Due date | Calculated from invoice date plus payment terms |
  And the invoice is stored in the client's document history
  And the client receives the invoice via their preferred delivery method

Scenario: Missing billing information
  Given a client has no tax ID on file
  When invoice generation runs for that client
  Then the invoice is flagged as "Pending Review"
  And the Finance Manager receives a notification listing missing fields
  And no invoice is sent to the client
```

**Why this is good:**
- Then doesn't just say "invoice is created" — specifies what valid means
- Quality criteria are concrete and verifiable
- Handles the failure case explicitly

---

## Example 3: Report Export (Integration Thinking)

**User Story:**

> As a Regional Manager,
> I want to export team performance data in a format compatible with our BI tool,
> So that I can include it in executive dashboards without manual reformatting.

**Why this priority (P2):** Currently takes 4 hours weekly to reformat exports. Blocks dashboard updates.

**Independent Test:** Export a report, import into BI tool, verify all columns map correctly and data types are preserved.

**Acceptance Scenarios:**

```gherkin
Scenario: Successful export for BI consumption
  Given I have a performance report with 12 months of data
  When I export in "BI Compatible" format
  Then a CSV file is generated with:
    | Column | Format |
    | Date | ISO 8601 (YYYY-MM-DD) |
    | Revenue | Numeric, no currency symbol |
    | Growth | Decimal (0.15 not 15%) |
    | Region Code | Standardised 3-letter code |
  And column headers match the BI tool's expected schema
  And the file encoding is UTF-8

Scenario: Data validation before export
  Given my report contains a region with non-standard naming
  When I attempt to export
  Then the export pauses with a validation warning
  And the warning identifies which rows have non-standard values
  And I can choose to fix or export with warnings noted
```

**Why this is good:**
- Considers the downstream consumer (BI tool)
- Specifies the format requirements for integration
- Includes what happens when data doesn't meet integration requirements

---

## Example 4: User Registration (Concrete Validation)

**User Story:**

> As a new visitor,
> I want to create an account with my email,
> So that I can access personalised features and save my preferences.

**Why this priority (P1):** Account creation is the gateway to all paid features. Current 40% drop-off at registration.

**Independent Test:** Complete registration with valid inputs, verify account is created and welcome email received within 60 seconds.

**Acceptance Scenarios:**

```gherkin
Scenario: Successful registration
  Given I am on the registration page
  And I have not registered before
  When I submit valid registration details
  Then my account is created with status "Pending Verification"
  And I receive a verification email within 60 seconds
  And I am redirected to the "Check Your Email" page

Scenario: Validation feedback
  Given I am completing the registration form
  When I enter an invalid email format
  Then the email field displays "Please enter a valid email address"
  And the submit button remains disabled
  When I enter a password shorter than 8 characters
  Then the password field displays "Password must be at least 8 characters"
  When I enter a password without a number
  Then the password field displays "Password must contain at least one number"

Scenario: Duplicate email handling
  Given an account already exists with "user@example.com"
  When I attempt to register with "user@example.com"
  Then I see "An account with this email already exists"
  And I am offered options to sign in or reset password
  And no new account is created
```

**Why this is good:**
- Validation is concrete — specific rules, specific messages
- Doesn't say "validation passes" — says what validation checks
- Handles the duplicate case (common edge case)

---

## Example 5: CI Pipeline Verification (System Persona Done Right)

**User Story:**

> As a CI pipeline,
> I want to verify that deployed configuration matches source definitions,
> So that manual edits to generated files are caught before merge.

**Why this priority (P2):** Prevents configuration drift. Last quarter had 3 incidents from undetected manual edits.

**Independent Test:** Manually edit a deployed config, run verification, confirm it fails with specific diff output.

**Acceptance Scenarios:**

```gherkin
Scenario: Configuration in sync
  Given deployed configuration matches source definitions
  When the verification step runs
  Then the step passes with exit code 0
  And the log shows "All configurations in sync"

Scenario: Drift detected
  Given a deployed configuration was manually edited
  When the verification step runs
  Then the step fails with exit code 1
  And the output identifies which file differs
  And the output shows the specific lines that differ
```

**Why this is good:**
- System persona is appropriate — the CI pipeline IS the consumer
- Exit codes and log output are the observable interface
- Specific about what "failure" looks like

---

## Edge Cases Section Example

```markdown
### Edge Cases

- What happens when the user's session expires mid-registration?
  Form data is preserved in local storage. On re-authentication, user returns to the form with data intact.

- What happens during a duplicate submission (user clicks twice)?
  Server rejects the second request with idempotency check. User sees success from first submission.

- What happens when email service is unavailable?
  Account is created with status "Verification Pending". Background job retries email. User can request resend from login page.
```

---

## Example 6: Project Scaffolding (Reference Canonical Source)

**User Story:**

> As a developer,
> I want to initialise a new project with the standard folder structure,
> So that I have a consistent starting point without manual setup.

**Why this priority (P1):** Foundation for all other features. Inconsistent structure causes tooling failures.

**Independent Test:** Run init in fresh directory, compare resulting structure against template definition.

**Acceptance Scenarios:**

```gherkin
Scenario: Standard structure created
  Given a fresh repository with no existing configuration
  When I run `project init`
  Then the folder structure matches `templates/project-structure.yaml`
  And all empty directories contain a `.gitkeep` file
  And the command outputs "Project initialized successfully"

Scenario: Structure validation on init
  Given a fresh repository
  When I run `project init`
  Then every required folder from the template exists
  And the init log lists each folder created
```

**Why this is good:**
- References canonical source (`templates/project-structure.yaml`) instead of listing every folder in Gherkin
- Single source of truth — folder structure defined once, Gherkin stays stable
- Still testable — compare actual vs template
- Non-technical stakeholder understands the intent without drowning in folder names

> **The "Will It Grow?" Test**
> 
> Before enumerating anything in Gherkin, ask:
> 1. Is this list defined in a script, config, or manifest?
> 2. Will this list grow as the system evolves?
> 
> If yes to both → reference the source of truth.
> If no to both → enumeration may be acceptable.

**Edge Cases:**

- What happens if template file is missing or corrupt?
  Init fails with error "Template not found: templates/project-structure.yaml"

- What happens if a folder in the template already exists?
  Existing folders are preserved, only missing folders are created.

- What happens if user lacks write permission?
  Init fails with error listing the specific folder that couldn't be created.
