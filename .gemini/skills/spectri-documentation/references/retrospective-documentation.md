---
managed_by: spectri
Date Created: 2026-01-29T12:32:00+11:00
Date Updated: 2026-01-29T12:32:00+11:00
name: retrospective-documentation
description: Use when creating retrospective specs for existing features with /spec.retro. Provides discovery frameworks and scope confirmation techniques.
---

# Retrospective Documentation Skill

## When to Use This Skill

This skill activates when you need to document existing systems that lack formal specifications. It applies to any codebase—React applications, Python services, Rust systems, or mixed-technology stacks.

**Triggers:**
- User asks to "document existing feature"
- User references `/spec.retro` command
- User needs to create specs for already-implemented functionality
- You encounter a system without formal documentation during investigation

**Anti-patterns (do NOT use this skill when):**
- Planning new features (use prospective specification workflows instead)
- Implementation doesn't exist yet
- User explicitly requests forward-looking design documents
- Creating API documentation (this is for architectural/feature specs, not API reference)

## Discovery Framework

Retrospective documentation succeeds or fails in the discovery phase. Unlike prospective specs where you imagine what should exist, retrospective specs require methodical investigation of what actually exists.

### Broad-to-Narrow Exploration

Start with architecture-level understanding before diving into implementation details.

**Phase 1: Entry Points and Architecture**

1. **Find the main entry point**:
   - Web apps: Look for `index.html`, `main.tsx`, `app.py`, `main.rs`
   - CLI tools: Check for argument parsers, command definitions
   - Libraries: Read the root module or exported API surface

2. **Identify the core abstractions**:
   - What are the main data structures?
   - What are the key interfaces or traits?
   - What patterns are used (MVC, actor model, event-driven)?

3. **Map dependencies**:
   - External libraries (package.json, Cargo.toml, requirements.txt)
   - Internal modules (how are they organized?)
   - Build tooling and deployment targets

**Phase 2: Feature Inventory**

For each major subsystem or feature:

1. **Read the implementation** (not just signatures):
   - What does this function/module actually do?
   - What are the inputs and outputs?
   - What state does it manage?

2. **Identify edge cases**:
   - Error handling paths
   - Boundary conditions (empty lists, null values, rate limits)
   - Concurrency or race conditions

3. **Find the "why" in commit history**:
   ```bash
   git log --oneline --follow path/to/file
   git blame -L 10,20 path/to/file
   ```
   Commit messages often reveal design decisions that aren't obvious from code alone.

4. **Check for comments and TODOs**:
   - `// HACK:` or `# TODO:` reveal known limitations
   - Doc comments explain intent vs implementation
   - Inline comments clarify complex logic

**Phase 3: Scope Boundaries (CRITICAL)**

The most valuable part of a retrospective spec is documenting what the system does NOT do. This prevents future confusion and misaligned expectations.

1. **Identify missing features**:
   - What related functionality is conspicuously absent?
   - What would users expect that isn't there?
   - What dependencies are imported but barely used?

2. **Document limitations**:
   - Performance constraints (e.g., "single-threaded", "no pagination")
   - Unsupported inputs (e.g., "only handles UTF-8", "no binary formats")
   - Environmental assumptions (e.g., "requires Unix sockets", "expects AWS credentials")

3. **Clarify future vs current**:
   - Distinguish between "not yet implemented" and "intentionally omitted"
   - Note any deprecated features still in the codebase
   - Flag experimental or unstable APIs

### Validation with Code

Never document assumptions without verification. For every major feature claim:

1. **Run the code**:
   - Execute the feature in a test environment
   - Observe actual behavior vs described behavior
   - Test edge cases you identified

2. **Check the tests**:
   - Unit tests reveal expected behavior
   - Integration tests show real-world usage patterns
   - Missing tests indicate untested assumptions

3. **Cross-reference documentation**:
   - Compare README claims to actual functionality
   - Check if AGENTS.md matches implementation
   - Verify examples in docs actually run

## Scope Confirmation Techniques

The investigation phase produces a wealth of information. Before writing the spec, you must confirm scope with the user. Poor scope confirmation leads to documenting imaginary features or missing critical details.

### Structured Presentation Format

Present findings in a scannable, hierarchical format:

```markdown
## Implementation Analysis: [System Name]

### Core Functionality
1. **[Feature Name]**: Brief description
   - Implementation: Where it lives, how it works
   - Inputs: Data types, formats, constraints
   - Outputs: Return values, side effects
   - Dependencies: External libraries, internal modules

2. **[Feature Name]**: ...

### Scope Boundaries
**What IS implemented:**
- [Feature X]: Fully functional, handles [edge cases]
- [Feature Y]: Basic implementation, no [advanced capability]

**What is NOT implemented:**
- [Missing Feature A]: Would require [dependency/effort]
- [Missing Feature B]: Intentionally omitted because [reason]

### Gaps and Limitations
- [Known Issue 1]: Described in [commit/issue]
- [Known Issue 2]: ...

### Questions for Clarification
1. [Specific question about ambiguous code]
2. [Question about intended vs actual behavior]
```

### Eliciting User Corrections

Users rarely read documentation thoroughly. Use targeted questions to surface corrections:

1. **Direct feature questions**:
   - "I found that the auth system uses JWT tokens. Does it also support OAuth2?"
   - "The file upload handler seems to reject files over 10MB. Is that intentional?"

2. **Boundary testing**:
   - "I didn't see any pagination. Should I document that as a known limitation?"
   - "The config parser ignores unknown fields. Is that by design or a gap?"

3. **Intent vs implementation**:
   - "The code suggests this was meant to be extensible via plugins, but no plugins exist. Should I document the plugin system or skip it?"

### Handling Uncertainty

When investigation reveals ambiguity:

1. **Flag it explicitly**:
   - "The `process_batch()` function has no tests. I can see it handles basic cases but can't confirm behavior for [edge case]."

2. **Propose a verification**:
   - "To document the rate limiter accurately, I'd like to run a load test. Should I proceed or document based on code review alone?"

3. **Offer alternatives**:
   - "Option A: Document current behavior as-is, flagging untested areas."
   - "Option B: Write minimal tests to confirm behavior before documenting."

## Common Pitfalls

### Pitfall 1: Documenting Aspirations Instead of Reality

**Symptom**: The spec describes features that technically exist in code but are broken, incomplete, or never called.

**Example**:
```markdown
## User Authentication
The system supports OAuth2, JWT tokens, and API key authentication.
```

**Reality**: OAuth2 is a half-finished branch that was never merged. Only JWT tokens work in production.

**Fix**: Verify every feature claim:
- "Does this code path actually execute in production?"
- "Are there any tests for this functionality?"
- "Has anyone actually used this feature?"

Document only confirmed-working features. Put aspirational content in a "Future Enhancements" section clearly marked as NOT YET IMPLEMENTED.

### Pitfall 2: Skipping Validation Steps

**Symptom**: You write the spec immediately after reading the code, without user confirmation.

**Example**: You document a complex caching system, but the user reveals it was disabled three months ago due to bugs.

**Fix**: Always present findings before writing. User confirmation catches:
- Deprecated features still in codebase
- Features that exist but are known-broken
- Misunderstandings about intended behavior

### Pitfall 3: Over-documenting Implementation Details

**Symptom**: The spec reads like code comments rather than a feature overview.

**Example**:
```markdown
The `handle_request()` function accepts a `Request` struct with fields `method`, `path`, `headers`, and `body`. It returns a `Result<Response, Error>` where the Error variant contains...
```

**Fix**: Focus on what the system does, not how it does it. Implementation details belong in code comments or developer guides, not feature specs.

**Better**:
```markdown
The request handler processes HTTP requests and returns appropriate responses. It supports GET, POST, PUT, and DELETE methods. Error responses include detailed error codes for debugging.
```

### Pitfall 4: Ignoring the "Not Implemented" List

**Symptom**: The spec only documents what exists, creating a false impression of completeness.

**Example**: A project management tool is documented as having "task creation, assignment, and status tracking" but doesn't mention that there's no search, no bulk operations, and no export functionality.

**Fix**: Explicitly document scope boundaries. Users need to know what the system doesn't do as much as what it does.

## Integration with Commands

This skill works primarily with the `/spec.retro` command (or equivalent retrospective documentation commands in your project).

**Typical workflow**:
1. User invokes `/spec.retro [feature name]`
2. This skill activates, guiding discovery
3. You investigate using broad-to-narrow framework
4. Present findings using structured format
5. Get user confirmation
6. Write spec.md with validated information

**Commands this skill enhances**:
- `/spec.retro` - Primary use case
- Any project-specific retrospective documentation commands
- Custom spec creation workflows for existing codebases

**Commands this skill does NOT apply to**:
- `/spec.spectri` (prospective, not retrospective)
- `/spec.plan` (assumes spec already exists)
- Feature design or architecture planning commands

## Quick Reference

### Discovery Checklist

- [ ] Found main entry point(s)
- [ ] Identified core abstractions and patterns
- [ ] Mapped external dependencies
- [ ] Inventoried major features
- [ ] Checked commit history for design context
- [ ] Identified edge cases and error paths
- [ ] Documented what is NOT implemented
- [ ] Verified claims by running code or reading tests
- [ ] Presented findings to user
- [ ] Got user confirmation before writing spec

### Red Flags (stop and clarify)

- **No tests for a critical feature**: Don't document behavior you can't verify
- **Contradictory code comments**: "This should never happen" followed by error handling for that case
- **Dead code**: Functions imported but never called
- **Incomplete refactors**: Half-migrated patterns (old and new style coexist)
- **Magic numbers**: Hardcoded values without explanation (limits, timeouts, buffer sizes)

### Presentation Template

Use this template when presenting findings:

```markdown
## Implementation Analysis: [System Name]

### Summary
[2-3 sentence overview of what the system does]

### Core Features
1. [Feature]: [Brief description]
2. [Feature]: [Brief description]

### Scope Boundaries
**Implemented**: [List]
**Not Implemented**: [List with reasons if known]

### Dependencies
- [Dependency]: [Purpose]

### Known Limitations
- [Limitation]: [Impact]

### Questions
1. [Question about ambiguity]
```

## Advanced Techniques

### Inferring Design Intent from Code Structure

Sometimes the code reveals more than comments or docs:

- **Abstraction layers**: Interfaces/traits suggest planned extensibility
- **Configuration patterns**: Environment variables reveal deployment contexts
- **Naming conventions**: Terms like "legacy", "v2", "experimental" tell a story
- **Error granularity**: Detailed error types suggest robust error handling; generic errors suggest "fail fast" philosophy

### Using Tests as Specifications

Integration and end-to-end tests often serve as executable specs:

```rust
#[test]
fn test_batch_processing_with_retry() {
    // This test reveals:
    // - Batch processing exists
    // - It has retry logic
    // - It handles failures gracefully
}
```

Read tests to understand:
- Intended behavior (assertions)
- Edge cases (boundary tests)
- Error scenarios (negative tests)
- Real-world usage patterns (integration tests)

### Cross-Referencing Artifacts

Triangulate truth from multiple sources:

- **Code + Tests + Docs**: All three agree → high confidence
- **Code != Docs**: Code is authoritative (but check git history for context)
- **Tests != Code**: Investigate! Possibly broken tests or code
- **Docs != Reality**: Common with outdated documentation

### Handling Legacy Systems

For old codebases:

1. **Check deprecation notices**: What was deprecated but never removed?
2. **Read migration guides**: What changed and why?
3. **Look for version markers**: `// TODO: Remove this in v3.0`
4. **Ask about tribal knowledge**: What do long-time users know that isn't documented?

## Summary

Retrospective documentation requires disciplined investigation, structured presentation, and careful validation. Follow the broad-to-narrow discovery framework, identify scope boundaries explicitly, and always confirm findings before writing. The goal is to document reality, not aspirations—creating an accurate inventory of what exists and what doesn't.
