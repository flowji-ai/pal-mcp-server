---
managed_by: spectri
description: "Detect structural drift in Spectri projects by verifying command sync, spec integrity, conventions, and cross-references."
model: sonnet
family: spectri-quality
origin:
  source: spectri
injections_applied:
  - user-input
build_info:
  built_at: 2026-03-26T10:24:06Z
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

  Thinking: Strategic guidance on when/why to run verification
  Orchestration: Mechanical execution of verification script
-->

## Outline

Goal: Detect structural drift in Spectri projects before it causes problems by verifying integrity across four categories: command template sync, spec folder structure, naming conventions, and internal cross-references.

**When to use this command**:
- Before committing significant changes to the repository
- After merging branches that modify specs or commands
- When investigating "file not found" or "missing file" errors
- As part of CI pipeline validation
- After bulk operations (moving specs, renaming folders, etc.)

**Prerequisites**: None - this command can run at any time without side effects.

Execution steps:

1. **Understand what verification checks**: Learn the five categories and why each matters.

   **Decision Framework - What Each Category Detects**:

   | Category | What It Checks | Why It Matters | Priority |
   |----------|----------------|----------------|----------|
   | **Command Sync** | Built commands in `.spectri/canonical/commands/` match deployed files in `.claude/commands/` | Source is `src/command-bases/`, built to `src/spectri_cli/canonical/commands/`, forward-synced to `.spectri/canonical/commands/`. Drift means commands won't sync properly. | High |
   | **Spec Integrity** | Every spec folder has `spec.md` and `meta.json` | Missing files break the spec workflow and confuse agents. Specs are unusable without these. | High |
   | **Conventions** | Lowercase folder names, frontmatter in markdown files | Case violations cause cross-platform issues (macOS works, Linux breaks). Missing frontmatter breaks tooling. | Medium |
   | **Cross-References** | Internal markdown links resolve to existing files | Broken links frustrate navigation and suggest stale documentation or moved files. | Low |

   **Mental Model**: Think of verification as a "structural health check" - it doesn't validate content quality, only that the project's organizational structure is intact and follows conventions.

2. **Determine verification scope**: Decide whether to run all checks or focus on specific categories.

   **Transformation Examples - When to Use Category Filtering**:

   | Scenario | Command | Reason |
   |----------|---------|--------|
   | General health check | `.spectri/scripts/spectri-quality/validate-integrity.sh` | Run all 5 categories to catch any drift |
   | After command changes | `.spectri/scripts/spectri-quality/validate-integrity.sh --category commands` | Only check command sync, faster feedback |
   | After moving specs | `.spectri/scripts/spectri-quality/validate-integrity.sh --category specs` | Verify spec integrity after bulk moves |
   | Before committing | `.spectri/scripts/spectri-quality/validate-integrity.sh --verbose` | See all checks (passed + failed) for full audit |

   **Anti-Patterns**:
   - **Don't** run verification and ignore failures - structural issues compound over time
   - **Don't** fix issues manually without understanding root cause - you might mask systematic problems
   - **Don't** assume macOS success means Linux will work - case-sensitivity issues are silent on macOS

3. **Execute verification script**: Run the integrity verification with appropriate flags.

   **Available Options**:
   - `--verbose`: Show all checks (passed + failed), not just failures
   - `--category CAT`: Run only specific category (commands|specs|conventions|links)
   - `--help`: Display usage information

   **Run the script**:
   ```bash
   .spectri/scripts/spectri-quality/validate-integrity.sh [--verbose] [--category CAT]
   ```

   **Exit codes**:
   - `0` = All checks passed (safe to proceed)
   - `1` = One or more checks failed (issues found)

4. **Interpret results**: Understand what failures mean and prioritize fixes.

   **Output Format**:
   ```text
   === Command Sync ===
   ✗ Out of sync: spectri.verify.md

   === Spec Integrity ===
   ✓ All specs have required files

   === Convention Enforcement ===
   ✓ All conventions followed

   === Cross-Reference Validation ===
   ✗ Broken link in spectri/specs/036/spec.md: ../015-feature/plan.md not found

   === Summary ===
   Passed: 3 categories
   Failed: 2 categories
   ✗ Found 3 issue(s)
   ```

   **Decision Framework - Issue Priority**:

   | Issue Type | Severity | Fix Priority | Why |
   |------------|----------|--------------|-----|
   | Missing spec.md or meta.json | **CRITICAL** | Fix immediately | Spec is unusable, breaks workflows |
   | Command sync drift | **HIGH** | Fix before committing | Prevents proper deployment, confuses agents |
   | Uppercase folder names | **MEDIUM** | Fix before pushing | Works on macOS, breaks on Linux servers |
   | Broken internal links | **LOW** | Fix when convenient | Annoying but doesn't break functionality |

5. **Fix detected issues**: Address failures based on priority.

   **Common Fixes**:

   | Issue | Fix Command | Notes |
   |-------|-------------|-------|
   | Template not deployed | Copy template to `.claude/commands/` | Temporary until Spec 009 sync tooling |
   | Out of sync | `cp .spectri/canonical/commands/X.md .claude/commands/X.md` | Overwrite deployed with template |
   | Missing spec.md | Create `spec.md` with proper frontmatter | Use `/spec.spectri` if possible |
   | Missing meta.json | Use `update-spec-meta.sh` to create | Never manually create meta.json |
   | Uppercase folder | `git mv spectri/specs/04-Deployed spectri/specs/04-deployed` | Use git mv to preserve history |
   | Missing frontmatter | Add `---` block at top of .md file | Include Date Created, Date Updated |
   | Broken link | Update link path or restore missing file | Check if file was moved or deleted |

6. **Re-verify after fixes**: Confirm all issues resolved.

   ```bash
   .spectri/scripts/spectri-quality/validate-integrity.sh
   ```

   **Expected Output** (if all fixed):
   ```text
   === Summary ===
   Passed: 5 categories
   Failed: 0 categories
   ✓ All checks passed
   ```

   **If still failing**:
   - Re-read error messages carefully
   - Use `--category` to isolate remaining issues
   - Use `--verbose` to see what is passing (helps narrow scope)

7. **Confirm completion**: Verify structural integrity is restored.

   Summary output:
   ```markdown
   ## Verification Complete

   **Status**: PASS (all 4 categories)
   **Issues Found**: 0
   **Exit Code**: 0

   **Next Steps**:
   1. Commit fixes if any were made
   2. Continue with original task
   3. Consider running verification in CI pipeline
   ```

---

## Behavior Rules

- If verification fails, DO explain what each failure means and how to fix it (don't just report failures)
- If user asks about specific category, explain what it checks and why it matters (pedagogical guidance)
- For repeated failures in same category, suggest systematic investigation (might indicate workflow issue)
- Never suppress failures or suggest ignoring them - structural issues compound over time
- Always re-verify after fixes to confirm resolution

---

## References

- Implementation: `.spectri/scripts/spectri-quality/validate-integrity.sh`
- Related Spec: `spectri/specs/04-deployed/045-integrity-system/spec.md`
- AGENTS.md Critical Rules: Folder naming, meta.json handling, work cycle
