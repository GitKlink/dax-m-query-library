# Domain and Context Locations

## Repository context

The canonical repository-wide domain context is the root `CONTEXT.md`.

Repository-wide architectural decisions live in `docs/adr/`.

Repository-wide workflow and engineering guidance lives in `docs/guides/` and `docs/agents/`.

## Feature context

Active features live under:

```text
in-progress/<feature>/
```

Completed feature engineering records live under:

```text
features/<feature>/
```

Each non-trivial feature should normally contain:

```text
README.md
spec.md
adr/
tests/
examples/
```

`experiments/` and `fixtures/` are optional and should exist only when useful.

Feature-specific ADRs live inside that feature's `adr/` folder. They do not belong in `docs/adr/` unless the decision governs multiple features or the repository as a whole.

## Published assets

Final consumable implementations live under `library/` according to implementation domain. Feature folders are engineering records, not the published API surface.

## Context resolution

Agents should read repository context first and feature context second. If a feature decision conflicts with a repo-wide ADR, stop and surface the conflict rather than silently choosing one.
