---
name: spectri-documentation
description: Use when running /spec.retro, documenting an existing feature, writing or editing AGENTS.md, or authoring project-context.md files.
metadata:
  version: "1.0"
  date-created: "2026-02-28"
  created-by: "ostiimac"
  managed-by: "spectri"
  ships-with-product: "true"
  spectri-pattern: "TODO"
---

# Documentation

Retrospective documentation and AGENTS.md authoring. Only applies to documenting what already EXISTS in code — not planning new features or managing spec lifecycle. For spec lifecycle operations, see the `spectri-manage-specs` skill.

## When to Activate

- Creating a retrospective spec for an already-implemented feature (`/spec.retro`)
- Creating or editing AGENTS.md files
- User says "document this existing feature" or similar
- project-context.md authoring

## When NOT to Activate

- Planning new features from scratch (use `spectri-manage-specs` phase detection)
- Implementation doesn't exist yet (not retrospective)
- Creating API reference documentation (code-generated, not this skill)
- Spec routing decisions — extend vs create new, tech stack pivots, implementation clarifications (use `spectri-manage-specs`)

## Retrospective Documentation

When documenting existing systems with `/spec.retro`, read `references/retrospective-documentation.md` for the full discovery framework. Key principles to carry through:

- **Document reality, not aspirations.** If the code does X, the spec says X — even if X is wrong.
- **Always present findings before writing.** Get user confirmation first — users catch deprecated features and intent vs actual mismatches.
- **Explicitly document scope boundaries.** What's NOT implemented prevents future confusion.

### Discovery Framework (summary)

Use broad-to-narrow exploration in three phases:

1. **Entry Points & Architecture** — Find main entry points, identify core abstractions, map dependencies.
2. **Feature Inventory** — Read implementation (not just signatures), identify edge cases, check commit history for design context.
3. **Scope Boundaries** — Document what the system does NOT do (most valuable part).

### Retrospective Spec Integration

When routing discovered artifacts into spec sections:

| Content type | Spec section |
|-------------|--------------|
| Entities and schemas | Functional requirements |
| API contracts and endpoints | System interface definitions |
| Validation rules and constraints | Quality / non-functional requirements |
| Configuration and environment | Deployment / operational requirements |

### Validation

For every major feature claim:

1. Cross-reference against actual code — does the code do what the spec says?
2. Run existing tests to confirm documented behaviour matches test expectations.
3. Flag any spec statement that cannot be verified from code or tests.

## AGENTS.md Authoring

Read `references/agents-md-authoring.md` for the content decision framework and anti-patterns. Key principle: AGENTS.md points to tooling and records behavioral corrections — never duplicates workflow content. Size limit: under 200 lines, warn at 150.

**Never hardcode counts, quantities, or enumerations in documentation.** Reference the source instead — write "the articles in constitution.md" not "17 Articles". When the source changes, all references remain correct automatically.

## SKILL.md Filepath References

The skill reference test (`tests/unit/test_skill_references.py`) validates every backtick-wrapped token containing a `/`. Rules by prefix:

- `references/` — resolved relative to the skill directory. Backtick these normally.
- `scripts/` paths — listed in both skill-relative and repo-relative prefix sets. If the skill has no `scripts/` subfolder, the test falls back to a repo-root check. Do not wrap skill-internal scripts/ paths in backtick code spans — describe them in prose instead.

## References

- `references/retrospective-documentation.md` — Full discovery framework, scope confirmation, common pitfalls, advanced techniques
- `references/agents-md-authoring.md` — AGENTS.md content decision framework and anti-patterns
