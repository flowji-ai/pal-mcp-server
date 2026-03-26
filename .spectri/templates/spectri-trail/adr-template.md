---
# ADR Identification
id: ADR-{{NNNN}}
title: {{DECISION_TITLE}}

# Status Tracking
status: Proposed
date: {{YYYY-MM-DD}}

# Context Linking
feature: {NNN-feature-name}
branch: {branch-name} (if applicable)
spec: {link to spec.md}
plan: {link to plan.md}
source_rfc: {RFC-YYYY-MM-DD-slug or empty if no originating RFC}

# Metadata
created_by: {agent or user}
updated_by: {agent or user}
---

# ADR {{NNNN}}: {{DECISION_TITLE}}

## Decision

{What was decided - describe the choice(s) made}

Use {Cluster Title}:
- **Component 1**: {Technology/Choice} - {rationale}
- **Component 2**: {Technology/Choice} - {rationale}
- **Component 3**: {Technology/Choice} - {rationale}

**Integration**: {How components work together and why this combination}

## Context

{Why this decision was needed - describe the problem, requirements, and constraints}

**Problem Statement**: {What problem does this solve?}

**Requirements**:
- {Requirement 1}
- {Requirement 2}
- {Requirement 3}

**Constraints**:
- {Constraint 1}
- {Constraint 2}

## Consequences

### Positive

- {Benefit 1 with explanation}
- {Benefit 2 with explanation}
- {Benefit 3 with explanation}

### Negative

- {Cost/risk 1 with explanation}
- {Cost/risk 2 with explanation}
- {Cost/risk 3 with explanation}

## Alternatives Considered

**Alternative A: {Alternative Cluster Name}**
- Component 1: {Technology}
- Component 2: {Technology}
- Component 3: {Technology}

**Why rejected**: {Rationale for rejection}

**Alternative B: {Alternative Cluster Name}**
- Component 1: {Technology}
- Component 2: {Technology}

**Why rejected**: {Rationale for rejection}

## References

- **Feature Spec**: `spectri/specs/{NNN-feature}/spec.md`
- **Implementation Plan**: `spectri/specs/{NNN-feature}/plan.md`
- **Research**: `spectri/specs/{NNN-feature}/research.md` (if exists)
- **Related ADRs**:
  - [ADR-{NNN}: {Related Decision}](./ADR-{NNN}-slug.md)
  - [ADR-{MMM}: {Another Related Decision}](./ADR-{MMM}-slug.md)
- **External Documentation**:
  - {Link to relevant external docs, specifications, or research}
