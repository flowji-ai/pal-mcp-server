# [REVIEWS/] CODE AND SPEC ANALYSIS
<!-- target: spectri/coordination/reviews/ -->

> **Reviews evaluate existing work** — did we build it right, what needs fixing, is code/spec quality acceptable. Backward-looking.

Reviews are qualitative analyses of code, specs, or architecture. They provide assessment beyond automated validation (linting, type checking) with human-level critique of technical quality, maintainability, and technical debt.

## When to Use

Create reviews when:
- Analyzing existing code for architecture and modularity
- Assessing spec quality before implementation
- Evaluating technical debt and cleanup opportunities
- Reviewing post-implementation work for lessons learned

Use automated tools for syntax errors, lint violations, type failures. Use reviews for qualitative judgment.

## File Naming

Two patterns:
- `YYYY-MM-DD-[topic]-review.md` — Date-based (time-bound or comparative analyses)
- `[topic]-review.md` — Topic-based (evergreen documentation, onboarding guides)

## Required Structure

### Frontmatter
Required fields:
```yaml
---
Date Created: YYYY-MM-DDTHH:MM:SSZ
Scope: [component being reviewed]
---
```

Optional fields (add when relevant):
```yaml
Date Updated: YYYY-MM-DDTHH:MM:SSZ
Reviewer: Agent Name (session-id)
Agent: Agent Name (session-id)
Method: [approach]
Type: architecture | code-quality | spec | system-enhancement | onboarding | historical-analysis | marketing | pre-implementation-gate | comparative-analysis
Status: draft | complete | partial
Source: [origin]
Plan Reference: [path]
---

```

**Frontmatter Notes:**
- Use block YAML or inline YAML (`**Key**: Value`) format — both accepted
- `Type: READ-ONLY review` is one option among many
- `Reviewer` and `Agent` fields — newer files use one or the other for who conducted review

### Body Structure

Reviews adapt structure to their type and scope. Common patterns:

**For architecture/system reviews:**
- Current Architecture Map or Project Evolution Summary
- Pain Points or Key Findings
- Refactoring Proposals or Recommendations
- Summary of Priority or Priority Table
- Triage Status (optional)

**For code quality reviews:**
- Current State or Architecture Overview
- Findings or Pain Points (numbered)
- Recommendations (ranked by impact/effort or grouped)
- Related or Quick Wins

**For onboarding reviews:**
- AGENTS.md Gaps or Missing Context
- Spec Clarity Issues or Contradictions & Drift
- Recommendations (ranked by breakage risk)
- Summary

**For comparative analyses:**
- Purpose
- Methodology
- Findings
- Key Insights or Recommendations
- Action

**For historical analysis reviews:**
- Findings or Key Architecture Decisions
- Patterns and Conventions
- Gotchas or Lessons Learned

**Triage Status (optional):**
- What issues were created, what was already tracked, what was disproven, what was folded into existing work

Triage Status may include subsections:
- Issues Created
- Already Tracked
- Resolved or Disproven
- Feature Ideas or Future Consideration

**NOTE:** Triage Status is optional. Only 1 of 10 existing reviews includes this section.

## Review Types

- **Architecture reviews** — System design, component organization, coupling
- **Code quality reviews** — Maintainability, readability, technical debt
- **Spec reviews** — Clarity, completeness, readiness for implementation
- **System enhancement reviews** — Cross-cutting improvements across multiple areas
- **Onboarding reviews** — Evaluate project documentation for new agents
- **Historical analysis reviews** — Extract decisions and patterns from git history
- **Marketing/website reviews** — Content quality, positioning, accuracy
- **Pre-implementation gate reviews** — Assess spec readiness (tasks actionability, TBDs, design gaps)
- **Comparative analysis reviews** — Compare before/after states or against baselines

## Distinction from Validation

| Aspect | Validation | Reviews |
|---------|------------|----------|
| **Tools** | linters, type checkers, tests | Human analysis, pattern recognition |
| **Output** | Errors, warnings, failures | Recommendations, proposals, prioritized issues |
| **Automated** | Yes, runs in CI/CD | No, manual qualitative assessment |
| **Scope** | Syntax, types, test coverage | Architecture, maintainability, technical debt |

Use validation for catching rule violations. Use reviews for identifying improvement opportunities.

## Outcome Actions

Reviews may result in:
- Creating issues for specific problems
- Opening threads for complex reworks
- Generating RFCs for architectural changes
- Updating existing specs based on findings

Document triaged outcomes in review's "Triage Status" section if included.
