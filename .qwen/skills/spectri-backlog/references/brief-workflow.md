# Brief Workflow

Structured capture for ideas mature enough to spec from. A brief contains a problem statement and directional requirements — enough context that `/spec.specify` can produce a full specification.

## When to Use

- You can articulate a clear problem statement
- You have directional requirements (even if rough)
- The idea is close to being ready for `/spec.specify`
- You want to capture structured context for a future specification session

## Steps

1. **Scaffold the backlog item**:
   ```bash
   bash .spectri/scripts/spectri-core/create-backlog-item.sh \
     --type brief \
     --short-name "<slug>" \
     "<description>"
   ```

2. **Fill in `brief.md`**: The scaffolding script creates `brief.md` from a light template. Complete the sections below.

3. **Commit**: Stage the new folder and commit.
   ```
   git add spectri/specs/00-backlog/NNN-slug/
   git commit -m "backlog(NNN): create brief for <description>"
   ```

## Brief Template Sections

The scaffolded `brief.md` includes these sections:

### Problem Statement
What problem does this feature solve? Who experiences it? What happens today without this feature?

### Directional Requirements
What should the solution roughly do? List capabilities, not implementation details. These are starting points — `/spec.specify` will refine them into formal user stories and functional requirements.

### Context & References
Links to related research, brainstorms, threads, existing specs, or external resources that informed this brief.

### Open Questions
What needs to be answered before this can be specified? These become input for the discovery phase of `/spec.specify`.

## Promotion

When the brief is ready for formal specification, run `/spec.specify` against the backlog item. The command reads the brief content and uses it as input context for story generation.
