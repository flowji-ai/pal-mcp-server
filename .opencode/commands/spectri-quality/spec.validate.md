---
managed_by: spectri
description: "Validate specs for format, required sections, and consistency. Use pre-commit, in CI pipelines, or after changes to catch errors early."
model: sonnet
family: spectri-quality
origin:
  source: spectri
injections_applied:
  - user-input
build_info:
  built_at: 2026-03-26T07:35:28Z
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

  Thinking: Strategic guidance on when/why to run validation
  Orchestration: Mechanical execution of validation library
-->

## Outline

Goal: Validate Spectri specs for format compliance, required sections, frontmatter structure, and cross-artifact consistency. Reports actionable errors following the pattern: what's wrong, why it matters, how to fix.

**When to use this command**:
- Before committing spec changes (catch errors early)
- As part of CI/CD pipeline (automated quality gates)
- After bulk operations on specs (moving, renaming, merging)
- When investigating "broken spec" or "missing section" issues
- After modifying spec templates or validation rules

**When to use `/spec.health` instead**:
- Checking command template sync status
- Checking naming conventions across the project
- Verifying internal cross-reference links

**Key difference**: `/spec.validate` checks spec CONTENT (sections, frontmatter, requirements). `/spec.health` checks project STRUCTURE (file locations, sync status, conventions).

**Prerequisites**: Spec must exist. Validation reads spec files without modifying them.

Execution steps:

1. **Understand what validation checks**: Learn the validation categories and why each matters.

   **Decision Framework - What Each Category Detects**:

   | Category | What It Checks | Why It Matters | Triggered By |
   |----------|----------------|----------------|--------------|
   | **Required Sections** | spec.md has User Scenarios, Requirements, Success Criteria | Missing sections make specs incomplete and hard to implement | Always |
   | **Frontmatter** | YAML frontmatter has Date Created, Date Updated, created_by, updated_by | Missing metadata breaks tooling and audit trail | Always |
   | **Plan Format** | plan.md has Implementation Approach, Design Decisions, Technical Considerations | Plans without these sections lack implementation guidance | If plan.md exists |
   | **Tasks Format** | tasks.md has grouped task structure with numeric headers | Malformed tasks confuse implementation workflow | If tasks.md exists |
   | **Cross-Artifact** | Tasks reference valid requirements (FR-XXX patterns match) | Orphaned task references suggest drift between spec and implementation | If both spec.md and tasks.md exist |
   | **Lifecycle** | Deployed specs have implementation summaries; all-complete tasks match lifecycle stage | Lifecycle mismatches indicate incomplete workflows | Always |

   **Mental Model**: Think of validation as a "content health check" - it ensures specs have all required information and internal consistency, not just structural organization.

2. **Determine validation scope**: Decide whether to validate a single spec, all specs, or use specific options.

   **Transformation Examples - Common Scenarios**:

   | Scenario | Command | Reason |
   |----------|---------|--------|
   | Pre-commit check | `lib/validation/cli/validate.sh 023` | Validate single spec before committing |
   | CI/CD pipeline | `lib/validation/cli/validate.sh --all --format=json` | Machine-readable output for automation |
   | Strict quality gate | `lib/validation/cli/validate.sh --all --strict` | Fail on warnings too |
   | Quick local check | `lib/validation/cli/validate.sh 023 --format=human` | Human-readable output (default) |
   | Quiet CI mode | `lib/validation/cli/validate.sh --all --format=json --quiet` | JSON only, no progress output |

   **Anti-Patterns**:
   - **Don't** validate and ignore errors - they indicate real problems that will surface later
   - **Don't** skip validation because "it's just a small change" - small changes can break sections
   - **Don't** use `--strict` locally for every check - it's intended for CI quality gates

3. **Execute validation**: Run the validation library with appropriate options.

   **Available Options**:
   - `SPEC_ID_OR_PATH`: Spec ID (e.g., `023`) or path (e.g., `spectri/specs/023-validation`)
   - `--all`: Validate all specs in repository
   - `--format=FORMAT`: Output format - `human` (default) or `json`
   - `--strict`: Treat warnings as errors (for CI quality gates)
   - `--quiet, -q`: Suppress progress output (useful with JSON)
   - `--no-color`: Disable colored output
   - `--help, -h`: Show usage information
   - `--version, -v`: Show version number

   **Run the script**:
   ```bash
   lib/validation/cli/validate.sh [OPTIONS] [SPEC_ID_OR_PATH]
   ```

   **Exit codes**:
   - `0` = Validation passed (safe to proceed)
   - `1` = Validation failed (errors found)
   - `2` = Strict mode failure (warnings found in strict mode)
   - `3` = Invalid arguments or spec not found
   - `4` = System error

4. **Interpret results**: Understand what errors mean and prioritize fixes.

   **Human Output Format**:
   ```text
   Validating spec: 023-verify-module

   === Spec Format ===
   ✗ Missing required section: User Scenarios & Testing

   === Frontmatter ===
   ✓ All required fields present

   === Cross-Artifact ===
   ✗ Task references non-existent requirement: FR-025

   === Summary ===
   Errors: 2
   Warnings: 0
   Status: FAILED
   ```

   **JSON Output Format** (for CI/CD):
   ```json
   {
     "spec_id": "023-verify-module",
     "status": "fail",
     "duration_ms": 234,
     "issues": [
       {
         "severity": "ERROR",
         "rule_id": "FR-004",
         "message": "Missing required section: User Scenarios & Testing",
         "file_path": "spectri/specs/023-verify-module/spec.md",
         "remediation": "Add '## User Scenarios & Testing' section with at least one user story"
       }
     ]
   }
   ```

   **Decision Framework - Issue Priority**:

   | Issue Type | Severity | Fix Priority | Why |
   |------------|----------|--------------|-----|
   | Missing required section | **ERROR** | Fix immediately | Spec is incomplete, can't be implemented properly |
   | Invalid frontmatter | **ERROR** | Fix immediately | Breaks tooling and audit trail |
   | Orphaned task reference | **ERROR** | Fix before implementing | Tasks reference non-existent requirements |
   | Lifecycle mismatch | **WARNING** | Fix during review | Indicates workflow wasn't followed |
   | Missing implementation summary | **WARNING** | Fix before deploy | Deployed specs should have completion records |

5. **Fix detected issues**: Address errors based on the actionable remediation provided.

   **Common Fixes**:

   | Issue | Fix Approach | Command/Action |
   |-------|--------------|----------------|
   | Missing User Scenarios section | Add section with user stories | Edit spec.md, add `## User Scenarios & Testing` |
   | Missing frontmatter field | Add required field | Edit spec.md frontmatter to include missing field |
   | Orphaned task reference | Update task or add requirement | Edit tasks.md to use valid FR-XXX, or add requirement to spec.md |
   | Missing implementation summary | Create summary | `/spec.summary` |
   | Lifecycle mismatch | Update meta.json status | `.spectri/scripts/shared/update-spec-meta.sh --spec <path> --status <status>` |

   **Actionable Error Pattern**:
   Every error from validation includes:
   - **What's wrong**: Specific problem identified
   - **Why it matters**: Impact on workflow/quality
   - **How to fix**: Concrete steps
   - **Example**: Correct format when applicable
   - **Reference**: Link to documentation (when available)

6. **Re-validate after fixes**: Confirm all issues resolved.

   ```bash
   lib/validation/cli/validate.sh <spec-id>
   ```

   **Expected Output** (if all fixed):
   ```text
   Validating spec: 023-verify-module

   === Summary ===
   Errors: 0
   Warnings: 0
   Status: PASSED
   ```

7. **Confirm completion**: Verify spec is valid and ready.

   Summary output:
   ```markdown
   ## Validation Complete

   **Spec**: 023-verify-module
   **Status**: PASSED
   **Errors**: 0
   **Warnings**: 0

   **Next Steps**:
   1. Commit changes if any fixes were made
   2. Continue with implementation or review
   3. Consider adding validation to CI pipeline
   ```

---

## Behavior Rules

- If validation fails, DO explain what each error means and provide the actionable remediation
- If user asks about a specific rule, explain what it checks and why it matters (pedagogical guidance)
- For repeated failures, suggest reviewing the spec template to understand expected structure
- Never suggest ignoring errors or warnings - they indicate real problems
- Always re-validate after fixes to confirm resolution
- For CI/CD integration, recommend `--format=json --strict` for maximum reliability

---

## References

- Implementation: `lib/validation/cli/validate.sh`
- Related Spec: `spectri/specs/04-deployed/023-verify-module/spec.md`
- Spec Template: `.spectri/templates/spectri-core/spec-template.md`
- Plan Template: `.spectri/templates/spectri-core/plan-template.md`
