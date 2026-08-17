# Issue Tracker Convention

GitHub Issues is the canonical issue tracker for this repository.

## Rules

- Use one independently deliverable feature per GitHub Issue unless an approved spec explicitly defines a tightly coupled asset family.
- Feature branches should normally use `feature/<feature-slug>` and reference the originating issue.
- Specifications produced by `to-spec` live with the feature under `in-progress/<feature>/spec.md` while active and `features/<feature>/spec.md` after completion.
- If `to-spec` publishes specification content into the issue tracker, the GitHub Issue should link to or summarize the canonical feature-local spec rather than creating a competing durable copy.
- Implementation tickets produced by `to-tickets` should be GitHub Issues linked back to the originating feature issue/spec.
- `.scratch/` is not the canonical tracker for this repository unless GitHub Issues becomes unavailable for a specific workflow.

## Completion linkage

A completed feature should remain traceable across:

```text
GitHub Issue
→ feature branch / PR
→ features/<feature>/ engineering record
→ library/<domain>/ published asset
```
