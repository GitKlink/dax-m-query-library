# Agent Instructions

This repository is a reusable Power BI library for Power Query (M) and DAX functions, patterns, utilities, and examples.

## Working rules

- Keep reusable functions generic and source-agnostic unless a source-specific adapter is explicitly part of the feature.
- Separate reusable engine logic from ingestion/connector logic.
- Prefer synthetic test/example data. Never add confidential employee, remuneration, company, survey-vendor, private SharePoint, credential, or proprietary source data.
- Preserve public API/function behaviour unless a specification explicitly changes it.
- Document non-obvious architectural decisions in `docs/adr/`.
- Keep durable domain vocabulary and repository-wide assumptions in `CONTEXT.md`.
- Use GitHub Issues for specifications/tickets and feature branches for implementation.

## Agent skills

Repository-local workflow conventions are recorded in:

- `docs/agents/issue-tracker.md` — canonical issue tracker and ticket conventions.
- `docs/agents/triage-labels.md` — triage/agent-readiness label vocabulary.
- `docs/agents/domain.md` — domain-document and ADR locations.

Ask Matt / engineering skills should use those files rather than guessing repository conventions.
