# Notes Workflow

Freeform capture for ideas not yet ready for structured specification.

## When to Use

- Raw idea or observation from other work
- Brain dump that needs a home
- Meta-notes about a pattern or problem you've noticed
- Brainstorm output that should become a future feature

## Steps

1. **Scaffold the backlog item**:
   ```bash
   bash .spectri/scripts/spectri-core/create-backlog-item.sh \
     --type notes \
     --short-name "<slug>" \
     "<description>"
   ```

2. **Write `notes.md`**: No template, no structure requirements. Write whatever captures the idea. The only goal is to prevent the idea from being lost.

3. **Commit**: Stage the new folder and commit.
   ```
   git add spectri/specs/00-backlog/NNN-slug/
   git commit -m "backlog(NNN): capture notes for <description>"
   ```

## Notes Format

There is no required format. Examples of valid content:

- A single paragraph describing an observation
- Bullet points of related ideas
- Copy-pasted conversation excerpts with annotations
- Links to related research or external references

The only constraint: no `spec.md` in `00-backlog/`.
