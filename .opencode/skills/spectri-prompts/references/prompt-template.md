# Prompt Template

## Frontmatter

```yaml
---
status: pending                 # pending → accepted → in-progress → implemented | superseded
metadata:
  date_created: "ISO-8601"
  created_by: "<agent-name-or-user>"
---
```

## Body Structure

```markdown
# Prompt: [Task Title]

## What
[What needs to be done — specific, actionable description]

## Why
[Context — why this needs to happen, what triggered it]

## Inputs
[Available inputs — file paths, specs, issues, related artifacts]

## Expected Output
[What the result looks like — concrete deliverable description]

## Constraints
[Any boundaries, deadlines, dependencies, or limitations]
```

## File Naming

`YYYY-MM-DD-[slug].md` — kebab-case slug describing the task.
