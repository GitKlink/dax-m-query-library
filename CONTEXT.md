# Repository Context

## Purpose

This repository contains reusable analytics engineering assets, primarily for Power BI, across four implementation domains:

- Power Query / M custom functions and patterns
- DAX measures, UDFs, and patterns
- Python functions, scripts, and analytics patterns
- Deneb visuals, templates, and Vega/Vega-Lite patterns

The goal is a portable, well-documented library rather than project-specific report code.

## Core vocabulary

- **Feature** — independently deliverable engineering work that produces one reusable asset or a tightly related asset family and has its own spec/design history.
- **Published asset** — the final reusable implementation under `library/`.
- **Feature engineering record** — README, spec, ADRs, tests, examples, fixtures, and relevant design history stored under `in-progress/` while active and `features/` when complete.
- **M function** — reusable Power Query function with a defined input/output contract.
- **M pattern** — reusable Power Query logic requiring adaptation rather than direct invocation.
- **DAX measure** — reusable measure or closely related measure family.
- **DAX UDF** — reusable DAX user-defined function.
- **DAX pattern** — reusable modelling/calculation approach with model assumptions.
- **Python function/script/pattern** — reusable Python implementation intended for analytics, automation, transformation, modelling, or Power BI-adjacent workflows.
- **Deneb visual** — reusable Deneb/Vega/Vega-Lite visual specification.
- **Deneb pattern** — reusable visual technique such as interaction, tooltip, responsive layout, or conditional formatting.
- **Adapter / ingestion query** — source-specific logic that normalises external data into the contract expected by reusable library logic.
- **Spec** — approved design contract for a feature.
- **ADR** — durable architecture decision whose rationale should remain discoverable after implementation.

## Repository scopes

### Repository scope

Applies to the entire library and lives in root files or `docs/`.

Examples: feature lifecycle, public-data policy, naming standards, issue conventions, library taxonomy.

### Feature scope

Applies only to one feature and lives under `in-progress/<feature>/` or `features/<feature>/`.

Examples: a rule engine's evaluation semantics, a DAX UDF's API, or a Deneb visual's interaction model.

## Design principles

1. Feature-first engineering; library-first consumption.
2. Keep core logic source-agnostic where practical.
3. Isolate connector/source-specific normalisation from reusable logic.
4. Make configuration and public contracts explicit and validate them early.
5. Prefer observable-behaviour tests/examples over tests coupled to implementation details.
6. Use synthetic public examples only.
7. Favour readable, auditable analytics logic over clever compactness.
8. Preserve extensibility without adding capabilities that have no concrete use case.
9. Keep final reusable assets separate from design history without duplicating competing implementations.

## Repository boundaries

This repository should not contain:

- project-specific PBIX/PBIP business logic unless deliberately generalized as an example;
- real employee or remuneration data;
- confidential company names/rules where disclosure is not intended;
- proprietary market survey/vendor datasets;
- credentials, tokens, private URLs, or secrets.
