# Pattern Guide: Imperative vs Declarative Gherkin

Learn to recognize and write declarative patterns by understanding the contrast between fragile, technical specs and bankable, implementation-agnostic behavior.

---

## The Core Shift

**Imperative Gherkin** (❌ Wrong):
- Leaks implementation details (APIs, database tables, function names)
- Fragile — breaks when internals change
- Hard to maintain — requires technical knowledge to update

**Declarative Gherkin** (✅ Right):
- Describes observable behavior from user's perspective
- Robust — survives implementation changes
- Maintainable — readable by non-technical stakeholders

---

## Example 1: Data Retrieval

### ❌ Imperative (Implementation Leakage)

*Fragile, technical, coupled to implementation.*

**Scenario:** Save profile
**Given** the `user_db` is connected
**When** I click the `#save-btn` and the `validate()` returns true
**Then** the `users` table should be updated with the new `string`

**Problems:**
- References database table (`user_db`, `users`)
- References HTML selector (`#save-btn`)
- References function name (`validate()`)
- Uses technical jargon (`string`)
- If implementation changes (different database, different button ID), spec breaks

### ✅ Declarative (Bankable Behavior)

*Robust, business-aligned, implementation-agnostic.*

**Scenario:** Successfully updating personal information
**Given** I am logged into my account profile
**When** I save my updated contact details
**Then** I should see a confirmation that my profile is current
**And** my new details should be visible the next time I visit

**Why this works:**
- No implementation details — describes what user sees/does
- Survives refactoring — database, framework, UI can change without breaking spec
- Non-technical stakeholders understand business value
- Designer can draw mockups from this spec
- Testable from user's perspective

---

## Example 2: Error Handling

### ❌ Imperative (Technical Leakage)

**Scenario:** API error handling
**When** the `fetchData()` API returns a `404` error code
**Then** the `ErrorBloc` should emit a `StateError` and show a snackbar

**Problems:**
- References function name (`fetchData()`)
- References HTTP status code (implementation detail)
- References framework class (`ErrorBloc`)
- References state class (`StateError`)
- References UI component implementation (`snackbar`)

### ✅ Declarative (Observable Outcome)

**Scenario:** Handling unavailable data
**When** the system fails to retrieve my information due to a connection issue
**Then** I should be notified that the data is currently unavailable
**And** I should be given the option to try the request again

**Why this works:**
- Describes user experience, not technical mechanism
- "Connection issue" is user-observable (slow loading, timeout), not HTTP 404
- "Notified" and "given option" are observable outcomes, not implementation classes
- Works with any notification UI (snackbar, modal, banner)
- Works with any state management (Bloc, Redux, custom)

---

## Example 3: Form Validation

### ❌ Imperative (Mechanical Description)

**Scenario:** Email validation
**Given** I am on the registration form
**When** I enter "invalid-email" in the `email_field` and call `validateEmail()`
**Then** the `isValid` boolean should be `false`
**And** the `error_message` variable should contain "Invalid format"

**Problems:**
- References field ID (`email_field`)
- References function name (`validateEmail()`)
- References internal state (`isValid` boolean)
- References variable name (`error_message`)
- Describes how validation works, not what user sees

### ✅ Declarative (User-Observable Validation)

**Scenario:** Email validation feedback
**Given** I am completing the registration form
**When** I enter an invalid email format
**Then** the email field displays "Please enter a valid email address"
**And** the submit button remains disabled

**Why this works:**
- No field IDs, function names, or variables
- Describes what user sees: error message text, disabled button
- Testable from UI: check for message, check button state
- Implementation can change (client-side, server-side, library) without breaking spec

---

## Example 4: Authentication Flow

### ❌ Imperative (Backend-Focused)

**Scenario:** Login process
**Given** the `auth_service` has valid credentials in the `credentials_table`
**When** the `login()` method is called with email and password
**Then** a `JWT` token should be generated
**And** the `session` object should store the token
**And** the user should be redirected to `/dashboard`

**Problems:**
- References service name (`auth_service`)
- References database table (`credentials_table`)
- References method name (`login()`)
- References token type (`JWT`)
- References object name (`session`)
- References route (`/dashboard`)

### ✅ Declarative (User Journey)

**Scenario:** Successful sign-in
**Given** I have a registered account
**When** I sign in with my email and password
**Then** I should see my personalized dashboard
**And** I should remain signed in when I return to the site

**Why this works:**
- Describes user experience: see dashboard, stay signed in
- No mention of tokens, sessions, or routes
- Backend can switch from JWT to session cookies without breaking spec
- Dashboard URL can change without affecting test
- Non-technical stakeholder understands the flow

---

## The Refactoring Checklist

When auditing existing Gherkin, use this checklist:

**Find and Replace:**
1. Database tables → State descriptions ("users table" → "my account")
2. Function calls → User actions ("click()" → "I select")
3. Class names → Observable outcomes ("ErrorBloc" → "error notification")
4. Variable names → What user sees ("isValid" → "validation passes")
5. Technical terms → Plain language ("JWT" → "authentication", "API" → "system")

**Test Your Refactor:**
1. **CEO Test**: Can a non-technical CEO understand this?
2. **Screenshot Test**: Can a designer draw the UI from this?
3. **Tech-Cleanse**: No code-like terms (`id`, `var`, `table`, `null`, `api`)?
4. **Implementation Independence**: If we rewrote the backend, would this spec still be valid?

---

## Common Technical Terms to Eliminate

| Technical Term | Replace With |
|----------------|--------------|
| `api`, `endpoint`, `fetchData()` | "the system retrieves" |
| `user_db`, `users table` | "my account", "user information" |
| `#button-id`, `.class-name` | "the submit button", "the confirmation message" |
| `validateEmail()`, `validate()` | "validation checks", "the system verifies" |
| `JWT`, `session token` | "authentication", "signed-in state" |
| `StateError`, `ErrorBloc` | "error notification", "error message" |
| `null`, `undefined`, `boolean` | Describe what user sees instead |
| `HTTP 404`, `status code` | "unavailable", "not found" |

---

## The "Black Box" Mental Model

Imagine the system is a physical black box on a desk:
- You can press buttons (input)
- You can see lights and displays (output)
- **You cannot see inside the box** (internal state, code, database)

If your Gherkin describes what's inside the box, refactor it.

**Wrong:** "The relay switch closes the circuit" (inside the box)

**Right:** "The green light turns on" (observable on the box)
