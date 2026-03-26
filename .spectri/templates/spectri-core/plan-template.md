---
Date Created: {{ISO_TIMESTAMP}}
Date Updated: {{ISO_TIMESTAMP}}
created_by: [AGENT_SESSION_ID]
updated_by: [AGENT_SESSION_ID]
---

# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Spec**: [link]
**Input**: Feature specification from `/spectri/specs/[###-feature-name]/spec.md`

**Note**: This template is filled in by the `/spec.plan` command. See `src/command-bases/spectri-workflow-core/plan.md` for the execution workflow.

## Summary

[Extract from feature spec: primary requirement + technical approach from research]

## Approved Implementation Phases

*This section is populated during the planning checkpoint. Do not edit manually.*

*Example format (will be filled in by `/spec.plan` command):*

1. **[Phase Name]**: [One-line description of what this phase accomplishes]
2. **[Phase Name]**: [One-line description]
3. **[Phase Name]**: [One-line description]

---

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Language/Version**: [e.g., Python 3.11, Swift 5.9, Rust 1.75 or NEEDS CLARIFICATION]  
**Primary Dependencies**: [e.g., FastAPI, UIKit, LLVM or NEEDS CLARIFICATION]  
**Storage**: [if applicable, e.g., PostgreSQL, CoreData, files or N/A]  
**Testing**: [e.g., pytest, XCTest, cargo test or NEEDS CLARIFICATION]  
**Target Platform**: [e.g., Linux server, iOS 15+, WASM or NEEDS CLARIFICATION]
**Project Type**: [single/web/mobile - determines source structure]  
**Performance Goals**: [domain-specific, e.g., 1000 req/s, 10k lines/sec, 60 fps or NEEDS CLARIFICATION]  
**Constraints**: [domain-specific, e.g., <200ms p95, <100MB memory, offline-capable or NEEDS CLARIFICATION]  
**Scale/Scope**: [domain-specific, e.g., 10k users, 1M LOC, 50 screens or NEEDS CLARIFICATION]

## Testing Principles

<!--
  ACTION REQUIRED: This section is MANDATORY for code-producing specs (Article III: Test-First Imperative).
  SKIP this section ONLY if Language is "Markdown" or "N/A" (documentation-only specs).

  The /spec.plan command will fill this section based on the technology stack above.
-->

**TDD Mandate** (Article III: Test-First Imperative):

This feature MUST follow test-driven development workflow:
1. Write tests FIRST (contract → integration → e2e → unit)
2. Verify tests FAIL (Red phase)
3. Implement code to make tests pass (Green phase)
4. Refactor as needed

**Test Framework Selection**:

Based on the technology stack chosen in Technical Context:
- **[Language]**: [Test framework] for unit tests, [Integration framework] for integration tests
- **Test Organization**: tests/unit/, tests/integration/, tests/e2e/
- **Coverage Requirements**: Minimum 80% code coverage for business logic

**Test File Naming Conventions**:
- Unit tests: test_[module_name].py or [module_name].test.ts
- Integration tests: test_integration_[feature].py
- Contract tests: test_contract_[api_name].py

**Reference**: See spectri/specs/AGENTS.md Development Practices > Testing for TDD workflow details.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**IMPORTANT**: Read `spectri/constitution.md` completely. Create a row for EVERY article and principle in the file. Do not assume the number of articles — count them from the file. The constitution grows over time; hardcoding a subset will produce an incomplete check.

| Article | Status | Notes |
|---------|--------|-------|
| [Every article from constitution] | PASS / FAIL / N/A | [Justification] |

## Project Structure

### Documentation (this feature)

```text
spectri/specs/[###-feature]/
├── plan.md              # This file (/spec.plan command output)
├── research.md          # Phase 0 output (/spec.plan command)
├── data-model.md        # Phase 1 output (/spec.plan command)
├── quickstart.md        # Phase 1 output (/spec.plan command)
├── contracts/           # Phase 1 output (/spec.plan command)
└── tasks.md             # Phase 2 output (/spec.tasks command - NOT created by /spec.plan)
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Delete unused options and expand the chosen structure with
  real paths (e.g., apps/admin, packages/something). The delivered plan must
  not include Option labels.
-->

```text
# [REMOVE IF UNUSED] Option 1: Single project (DEFAULT)
src/
├── models/
├── services/
├── cli/
└── lib/

tests/
├── contract/
├── integration/
└── unit/

# [REMOVE IF UNUSED] Option 2: Web application (when "frontend" + "backend" detected)
backend/
├── src/
│   ├── models/
│   ├── services/
│   └── api/
└── tests/

frontend/
├── src/
│   ├── components/
│   ├── pages/
│   └── services/
└── tests/

# [REMOVE IF UNUSED] Option 3: Mobile + API (when "iOS/Android" detected)
api/
└── [same as backend above]

ios/ or android/
└── [platform-specific structure: feature modules, UI flows, platform tests]
```

**Structure Decision**: [Document the selected structure and reference the real
directories captured above]

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
