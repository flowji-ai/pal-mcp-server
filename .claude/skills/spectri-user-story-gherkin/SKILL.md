---
name: spectri-user-story-gherkin
description: Use when conducting feature discovery, writing, auditing or editing user stories, gherkin acceptance criteria (Given-When-Then), defining requirements, creating PRDs, or working on spec.md files within the Spectri framework.
metadata:
  version: "2.2"
  date_created: "2026-02-15"
  date_updated: "2026-02-22"
  created_by: "ostiimac"
  managed_by: spectri
  ships_with_product: true
  spectri-pattern: "TODO"
---

# User Story Creation

Guides feature discovery, writing user stories, and Gherkin acceptance criteria that are testable, maintainable, and focused on outcomes. Covers both creation and review of existing stories.

## Feature Discovery

Run discovery before generating any user stories. Stories from sparse descriptions silently invent requirements — every story downstream is wrong if the agent builds the wrong mental model.

### Required Elements

Five elements must be present before story generation begins:

| Element | Description |
|---------|-------------|
| **Invocation mechanism** | How the feature is accessed — CLI command, UI element, API call, hook, or scheduled job |
| **Trigger** | What starts the feature — the event, condition, or decision that prompts it |
| **Interaction flow** | The sequence of steps and any decision points |
| **Output** | What gets created, changed, or produced, and where it goes |
| **Actors** | Who is involved — user, system, agent |

If all five are present in the initial description, offer to skip:
> "Your description covers invocation mechanism, trigger, flow, output, and actors. Want to proceed to story generation, or walk through anything else first?"

**Sparse input fallback**: If fewer than 5 of the 11 discoverable elements have been collected after the narrative and gap-filling steps, do NOT proceed to synthesis. Stay in discovery until invocation mechanism, trigger, flow/decisions, output, and actors are all confirmed.

**Recording rule**: Write findings to `feature-discovery.md` after each step — not at the end. Context window compression is a real risk during long sessions.

For the full step-by-step procedure, question wording, and probing patterns, see `references/feature-discovery-guide.md`.

---

## Five Principles

1. **Substance Over Mechanics** — Stories own outcomes, not process
2. **Quality Over Existence** — "Then X is created" is never enough
3. **Single Story Ownership** — One story owns the core value proposition
4. **Integration Thinking** — Every output becomes input for something else
5. **Concrete Validation** — Validation must specify what is checked

---

## Applying the Principles

### 1. Substance Over Mechanics (The "Black Box" Principle)

Treat the system as a Black Box. If a user cannot see it, hear it, touch it, or feel the delay of it, it does not exist in the specification.

**Prohibited:**
- **No Technology**: Firebase, Bloc, Flutter, JSON, API, SQLite
- **No Mechanics**: `onTap` function, `user_id` variable, class names
- **No Hidden States**: "The boolean is set to true", internal flags

Write stories about achieving goals, not running commands or describing internals.

**Wrong:** "As a user, I want to click the export button so that a file is downloaded."

**Right:** "As a sales manager, I want to export my pipeline report so that I can share progress with stakeholders offline."

### 2. Quality Over Existence

Every "Then" that creates something must specify what makes it valid.

**Wrong:** `Then an invoice is generated`

**Right:** `Then an invoice is generated containing line items, tax calculation, and payment terms`

### 3. Single Story Ownership

Before writing multiple stories, identify THE story that delivers core value. Other stories support it.

**Test:** Can you point to one story and say "if this passes, the feature works"?

**Overloaded Story Warning:** Simple stories need 2-3 scenarios. Medium-complexity stories may warrant 4-5. If a story exceeds 5-6 scenarios, or scenarios test fundamentally different concerns (e.g., build workflow AND validation rules), split into separate stories. More scenarios signal more complexity — consider whether the story itself should be split rather than adding more scenarios.

### 4. Integration Thinking

Ask: What consumes this output? What structure does it expect?

Include scenarios for:
- What the downstream process receives
- What happens if output is malformed

### 5. Concrete Validation

Never write "Then validation passes" — specify what is validated.

**Wrong:** `Then the form validates successfully`

**Right:** `Then the form confirms: email format is valid, password meets complexity rules, username is unique`

---

## Story Template

```
As a [specific persona],
I want [action/capability],
So that [business outcome].

**Why this priority:** [Business reasoning for P1/P2/P3]

**Independent Test:** [How to verify this story in isolation]

**Acceptance Scenarios:**
[Given-When-Then criteria]
```

### Non-Human Personas

Personas can be automated processes, APIs, or scheduled jobs when the story genuinely describes system-to-system behaviour. Example: "As the nightly reconciliation job, I want to retry failed transactions so that temporary outages don't cause permanent data loss."

### Priority Levels

| Level | Definition |
|-------|------------|
| P1 | Core functionality — feature doesn't work without this |
| P2 | Important — significantly enhances value, not blocking |
| P3 | Nice to have — can be deferred |

---

## Gherkin Quick Reference

Prefer **declarative style** (what the user achieves) over **imperative style** (which buttons they click). The anti-patterns below encode this principle — see `references/pattern-guide.md` for side-by-side examples.

| Component | Must Describe | Never Describe |
|-----------|---------------|----------------|
| Given | Data state, user context | Actions, desires, ongoing activities |
| When | Single action (user or system trigger) | Observation, multiple actions |
| Then | Observable outcome with quality criteria | Capabilities, vague success |

---

## Scenario Outlines

Use `Scenario Outline` with an `Examples` table when multiple scenarios share the same Given/When/Then structure but differ only in data values.

```gherkin
Scenario Outline: Reject invalid input
  Given the form is open
  When I enter <input> in the <field> field
  Then validation shows "<message>"

  Examples:
    | input       | field    | message                    |
    | ""          | email    | Email is required          |
    | not-an-email| email    | Enter a valid email format |
    | ab          | password | Minimum 8 characters       |
```

**When to use Scenario Outlines vs. separate scenarios:**
- Same structure, different data → Scenario Outline
- Different behaviour or flow → separate scenarios
- If the Examples table exceeds 6-8 rows, consider whether you're testing too many variations in one scenario

---

## Given Anti-Patterns

<CRITICAL>
Given describes the state of the world BEFORE the user acts. Not how it got there. If it contains an action verb, it's wrong.
</CRITICAL>

| Anti-Pattern | Example | Fix |
|--------------|---------|-----|
| Action as Given | `Given the user creates an account` | `Given an account exists` |
| Completed action | `Given I have edited the file` | `Given the file has been modified` |
| Ongoing action | `Given I am adding a command list` | `Given the draft contains a command list` |
| Desire as Given | `Given I want to build the project` | `Given the project has pending changes` |
| Existence only | `Given commands exist` | `Given 5 commands exist in the queue` |

**Test:** Does your Given contain a verb describing what someone did or is doing? Reframe as the resulting state.

---

## When Anti-Patterns

When is the single action that triggers the behaviour being tested.

| Anti-Pattern | Example | Fix |
|--------------|---------|-----|
| Vague verbs | `When I look up the file` | `When I open the file` |
| Observation verbs | `When I check the output` | Move to Then |
| Two actions | `When I copy the file and run the build` | Split: Given file copied, When I run build |
| Actorless system event | `When the skill activates` | `When I make my first change` or use a non-human persona |
| Backwards (should be Given) | `When the source file is valid` | `Given the source file is valid` |

**Vague verbs to avoid:** look up, check, review, examine, verify, see

**Note:** System events are valid When steps when the persona is a non-human actor (see Non-Human Personas). `When the nightly job runs` is valid if the story's persona is the nightly job.

**Test:** Is this something the actor actively does, or something they observe? Observation belongs in Then.

---

## Then Anti-Patterns

Then describes what the user observes after the action. Must be specific and testable.

| Anti-Pattern | Example | Fix |
|--------------|---------|-----|
| Capability | `Then I can decide to merge or discard` | `Then the merge and discard options are displayed` |
| Vague success | `Then it works` | `Then the dashboard shows status "Active"` |
| Existence only | `Then a file is created` | `Then a file is created containing X, Y, Z` |
| Multiple outcomes | `Then A and B and C and D` | Use separate And statements or scenarios |

**Test:** Could a tester verify this passed or failed? If it requires mind-reading ("I can decide"), it's not testable.

---

## Story-Level Anti-Patterns

Issues that affect the story structure, not individual Given/When/Then lines.

| Anti-Pattern | Signal | Fix |
|--------------|--------|-----|
| Inconsistent specificity | Error scenarios have exact messages, happy path says "proceeds" | Happy path must have equally specific observable outcomes |
| Over-specification | Gherkin lists every subfolder, config option, or field | Reference canonical source file or describe at higher abstraction |
| Duplicate scenarios | Multiple scenarios with same Given + same When | Consolidate into one scenario with And statements in Then |
| Hardcoded growing lists | Gherkin enumerates files, folders, or locations defined elsewhere | Reference the source of truth (template, manifest, config) |

**Quick tests:**
- Inconsistent specificity: Do all Thens have the same level of detail?
- Over-specification: Could a non-coder understand this scenario?
- Duplicate scenarios: Same Given AND same When? Consolidate.
- Hardcoded lists: Will this list grow? Reference the source of truth.

---

## Edge Cases Section

After acceptance scenarios, add edge cases in Q&A format:

```markdown
### Edge Cases

- What happens when input is empty?
  System displays validation message listing required fields.

- What happens when user has no permission?
  System redirects to access denied page with request access option.
```

---

## Pre-Submission Checks

Before finalising any user story:

**INVEST Check:**
- [ ] **Independent** — Can be developed, tested, and delivered without depending on other stories
- [ ] **Negotiable** — Describes the outcome, not the implementation (leaves room for how)
- [ ] **Valuable** — Delivers clear business value (passes the "So What?" test)
- [ ] **Estimable** — Scope is understood well enough to estimate effort
- [ ] **Small** — Can be completed within a single iteration
- [ ] **Testable** — Acceptance criteria are specific enough to write a pass/fail test

**Story Level:**
- [ ] Story owns an outcome, not a process
- [ ] "So that..." describes business value
- [ ] "Why this priority" has business reasoning
- [ ] Independent Test describes verification method
- [ ] Scenario count appropriate to complexity (2-3 simple, 4-5 medium, 6+ means split)
- [ ] All scenarios test the same concern
- [ ] Specificity is consistent across all scenarios (if errors are specific, happy path is too)
- [ ] No duplicate scenarios (same Given + same When)
- [ ] Gherkin describes behaviour, not technical specification
- [ ] No hardcoded lists that will grow (reference source of truth instead)

**Given:**
- [ ] Describes state, not action
- [ ] No "I have [verb]" patterns
- [ ] No "I am [verb]ing" patterns
- [ ] No "I want to" or "I need to"

**When:**
- [ ] Single user action
- [ ] No "and" joining multiple actions
- [ ] No vague verbs (look up, check, review, examine)
- [ ] Not an actorless system event (system triggers are valid with non-human personas)
- [ ] Not an observation

**Then:**
- [ ] Observable, testable outcome
- [ ] No "I can..." capability statements
- [ ] Quality criteria specified (not just existence)
- [ ] Compound outcomes split into And statements

**Coverage:**
- [ ] Edge cases addressed in Q&A format
- [ ] Downstream consumers considered

---

## Quality Heuristics

Quick mental tests to validate story quality before submission:

**CEO Test**: If you read the Gherkin to a non-technical CEO, do they understand the business value without asking for definitions?

**Screenshot Test**: Could a designer draw a mockup of the "Then" step without looking at the code?

**"So What?" Test**: If the "So that" clause is "so that I can use the feature," the story is incomplete. It must express measurable business value.

**Tech-Cleanse**: Search for: `id`, `var`, `table`, `null`, `api`, `endpoint`, `click`, class names, function names. If found, refactor to observable outcomes.

---

## References

For detailed examples, see:
- `references/good-examples.md` — Illustrative examples demonstrating principles
- `references/bad-examples.md` — Common failures to avoid
- `references/real-world-examples.md` — Production-tested patterns from actual deployed specs
- `references/pattern-guide.md` — Imperative vs declarative patterns with side-by-side examples
