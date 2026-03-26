# Research Template

```yaml
---
type: architectural             # architectural | tooling | pattern | integration | custom
status: stub                    # stub → in-progress → complete
metadata:
  date_created: "ISO-8601"
  date_updated: "ISO-8601"
  created_by: "hostname"
---
```

## Recommended Body Structure

```markdown
# Research: [Title]

## Purpose
What you're investigating and why.

## Research Questions
Specific questions guiding the investigation.

## Findings
Results, patterns discovered, options identified.

## Analysis
Interpretation of findings, implications, trade-offs, limitations.

## Recommendations
What action to take: adopt, defer, reject, monitor.

## Sources
External references, URLs, upstream docs cited.
```

Sections are recommended, not enforced — adapt based on research scope and type.

File naming: `YYYY-MM-DD-[topic]-research.md`.

Attribution field: use `Agent` (not `Researched By`).

## Research Packages

For multi-source investigations, create a package folder instead of a single file using `--package`.

### Package Structure

```
spectri/research/YYYY-MM-DD-slug/
├── 00-index.md          # Entry point — overview and synthesis
├── 01-first-topic.md    # Individual research file
├── 02-second-topic.md   # Individual research file
└── ...
```

- `00-index.md` is the entry point — always present, created by the script
- Numbered files (`NN-slug.md`) are added manually as the investigation progresses
- Update the Package Contents table in `00-index.md` when adding files
- Each file within a package can follow the single-file structure above

### When to Use

| Single file | Package |
|-------------|---------|
| One investigation, one set of findings | Multiple related investigations |
| Fits in one document | Needs synthesis across sources |
| Topic is narrow and focused | Topic is broad or comparative |
