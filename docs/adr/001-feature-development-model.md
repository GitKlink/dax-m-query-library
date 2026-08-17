# ADR 001: Feature-first development and separate published library

## Status

Accepted

## Context

The repository needs to support multiple M, DAX, Python, and Deneb items being designed and implemented concurrently while remaining easy for humans and engineering agents to navigate.

Keeping prototypes and final assets in the same folders risks unclear status. Keeping duplicate working and final copies of the same implementation risks drift.

## Decision

Use **features as the unit of engineering work** and `library/` as the unit of consumption.

- Active engineering records live under `in-progress/<feature>/`.
- Completed engineering records move to `features/<feature>/`.
- The reusable implementation is published under `library/<domain>/...`.
- Git feature branches provide code isolation during concurrent work.
- A feature normally maps to one independently deliverable asset (for example one M function, DAX UDF, DAX measure/pattern, Python utility, or Deneb visual), but an approved spec may define a tightly coupled asset family.
- Feature-specific ADRs remain with the feature.
- Repository-wide ADRs remain under `docs/adr/`.

## Consequences

- Multiple features can be developed concurrently without confusing published status.
- Final implementations have one canonical location rather than WIP/final duplicates.
- Design rationale remains permanently discoverable after completion.
- Agents can traverse from issue → feature context → implementation deterministically.
