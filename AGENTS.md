# Agent Instructions

This repository is a reusable analytics engineering library for Power Query (M), DAX, Python, and Deneb assets used primarily with Power BI.

## Working rules

- Treat a feature as the primary unit of engineering work.
- Use one independently deliverable feature per GitHub Issue and feature branch unless the approved spec explicitly groups tightly related outputs.
- Active feature documentation belongs under `in-progress/<feature>/`.
- Completed feature documentation belongs under `features/<feature>/`.
- Published reusable outputs belong under `library/`; do not use `in-progress/` as the consumable library.
- Repo-wide architectural decisions belong under `docs/adr/`; feature-only decisions belong in the feature's `adr/` folder.
- Keep reusable functions generic and source-agnostic unless a source-specific adapter is explicitly part of the feature.
- Separate reusable engine logic from ingestion/connector logic where practical.
- Prefer synthetic test/example data. Never add confidential employee, remuneration, company, survey-vendor, private SharePoint, credential, or proprietary source data.
- Preserve public APIs/behaviour unless an approved specification explicitly changes them.
- Keep durable repository vocabulary and repo-wide assumptions in `CONTEXT.md`.
- Do not create empty taxonomy folders purely for completeness; create category folders when the first asset requires them.
- Follow `docs/guides/github-communication.md` for Issues, pull requests, review comments, and status updates. Use the defined emoji vocabulary as visual icons for scanability, and make required human actions explicit with `🧑‍💻 Action required`.

## Context precedence

When working on a feature, resolve context in this order:

1. `AGENTS.md` and `CONTEXT.md`
2. `docs/agents/`, `docs/adr/`, and `docs/guides/`
3. feature `README.md`, `spec.md`, and `adr/`
4. current issue / approved implementation ticket
5. implementation code and tests

Feature decisions may specialize repo-wide conventions but must not silently contradict them. If a feature requires a repo-wide exception, create or revise a repo ADR.

## Agent skills

Repository-local workflow conventions are recorded in:

- `docs/agents/issue-tracker.md` — canonical issue tracker and ticket conventions.
- `docs/agents/triage-labels.md` — triage/agent-readiness label vocabulary.
- `docs/agents/domain.md` — domain-document, feature-context, and ADR locations.

Ask Matt / engineering skills should use those files rather than guessing repository conventions.
