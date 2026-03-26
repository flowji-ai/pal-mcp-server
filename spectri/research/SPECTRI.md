# [RESEARCH/] INVESTIGATION NOTES
<!-- target: spectri/research/ -->

> **Research explores unknowns** — what should we build, how does something work, what options exist. Forward-looking.

Research files capture investigation notes and exploration of external patterns, tools, or technologies. They document learning before creating specs or making decisions.

## When to Use

Create research files when:
- Evaluating tools, libraries, or frameworks
- Researching external patterns or best practices
- Exploring implementation approaches before committing
- Comparing options to inform a decision
- Investigating upstream projects or references

Use threads for spec-specific continuation context. Use RFCs for structured pre-decision exploration.

## File Naming

Date-based with topic and optional agent: `YYYY-MM-DD-[topic]-research.md` or `YYYY-MM-DD-[topic]-[agent-name]-research.md`

Agent name in filename is optional. If included, it's captured in frontmatter's `Agent` field.

**Frontmatter Notes:** Older research files may use `created_by` instead of `Agent`. Both are valid — newer files use `Agent`.

## Required Structure

### Frontmatter
```yaml
---
Date Created: YYYY-MM-DDTHH:MM:SS+11:00
Date Updated: YYYY-MM-DDTHH:MM:SS+11:00
Agent: Agent Name (session-id)
Type: architectural | tooling | pattern | integration | [custom]
Status: stub | in-progress | complete
Plan Reference: path/to/plan.md (optional)
Note: Additional context (optional)
---
```

**Frontmatter Notes:**
- `Agent` field (newer pattern) or `created_by` (older pattern) — both are valid
- `stub` status used for placeholder research not yet started
- `Type` field has common values, but custom values are allowed

### Recommended Body Structure

Research files follow this recommended structure:

```markdown
## Purpose
What you're investigating and why.

## Research Questions
Specific questions guiding the investigation (optional).

## Initial Context
Background information, current understanding, or state before research began (optional).

## Research Tasks
Numbered steps or areas to investigate:
1. [Task description]
2. [Task description]
...

## Findings
Results, patterns discovered, options identified, data gathered.

## Analysis
Interpretation of findings, implications, tradeoffs, limitations.

## Recommendations
What action to take (adopt, defer, reject, monitor).

## Sources
External references, URLs, upstream docs cited in research (optional but recommended).

## Related
Specs, RFCs, ADRs, external research docs, or reference materials informed by or related to this research.
```

**Structure Notes:**
- This is a **recommended structure** for structured research — actual files may vary
- Sections can be adapted based on research scope and type
- `Sources` section is recommended for credibility when citing external references

## Status Lifecycle

- **Stub** — Placeholder created, research not started
- **In-progress** — Actively investigating
- **Complete** — Finished, recommendations ready

## Research Packages

For multi-source investigations (comparative analysis, technology surveys), create a research package — a dated folder with `00-index.md` as the entry point.

**Package naming:** `YYYY-MM-DD-[topic]/` — packages omit the `-research` suffix since the folder itself is in `research/`.

**Package structure:**
- `00-index.md` — entry point with purpose, package contents table, and synthesis
- `NN-slug.md` — numbered individual research files within the package

Existing organic subfolders with different conventions are pre-convention and grandfathered.

## Relationship to Specs and RFCs

Research may:
- Seed an RFC if multiple options need structured discussion
- Inform spec creation by providing context for implementation
- Stand alone as general reference material

Research goes in folder it belongs to. Don't create separate "global research" — put it where it's used or in most logical subfolder.
