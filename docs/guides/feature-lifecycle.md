# Feature Lifecycle

## Unit of work

Use one independently deliverable feature per GitHub Issue and feature branch unless an approved spec explicitly defines a tightly coupled asset family.

## Typical lifecycle

1. Create/triage a GitHub Issue.
2. Create `in-progress/<feature>/README.md`.
3. Grill/design the feature and write `spec.md`.
4. Record meaningful feature decisions under `adr/`.
5. Convert the approved spec into implementation tickets if the work warrants decomposition.
6. Implement on `feature/<feature>`.
7. Add behaviour tests and usage examples with the feature.
8. Review implementation against the spec and repository standards.
9. Publish the canonical reusable implementation under `library/`.
10. Move the engineering record from `in-progress/<feature>/` to `features/<feature>/` as part of completion.
11. Merge the PR and close the issue.

## Concurrent work

Feature branches are the primary isolation mechanism. Separate feature folders make repository state discoverable. Avoid sharing mutable feature-specific files across unrelated branches.

## Definition of done

A non-trivial feature is complete when:

- its approved behaviour is implemented;
- tests/examples cover the important observable behaviour;
- significant design decisions are recorded;
- its published asset has one canonical location under `library/`;
- its engineering record is under `features/`;
- its issue/PR links are resolvable.
