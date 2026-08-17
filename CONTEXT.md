# Repository Context

## Purpose

This repository contains reusable Power BI development assets for:

- Power Query / M custom functions
- Power Query transformation patterns
- DAX measures and measure families
- DAX modelling/calculation patterns
- reusable examples and supporting documentation

The goal is a portable, well-documented library rather than project-specific report code.

## Core vocabulary

- **M function** — a reusable Power Query function with a defined input/output contract.
- **M pattern** — reusable Power Query logic that may require adaptation rather than direct invocation.
- **DAX measure** — a reusable DAX measure or closely related measure family.
- **DAX pattern** — a reusable modelling/calculation approach illustrated with DAX and model assumptions.
- **Adapter / ingestion query** — source-specific logic that normalises external data into the contract expected by reusable library logic.
- **Spec** — design contract for a feature before implementation.
- **ADR** — durable architecture decision whose rationale should remain discoverable after implementation.

## Design principles

1. Keep core logic source-agnostic where practical.
2. Isolate connector/source-specific normalisation from reusable functions.
3. Make configuration contracts explicit and validate them early.
4. Prefer observable-behaviour tests/examples over tests coupled to implementation details.
5. Use synthetic public examples only.
6. Favour readable, auditable Power BI logic over clever compactness.
7. Preserve extensibility without adding capabilities that have no concrete use case.

## Repository boundaries

This repository should not contain:

- PBIX/PBIP project-specific business logic unless deliberately provided as a generic example
- real employee or remuneration data
- confidential company names/rules where disclosure is not intended
- proprietary market survey/vendor datasets
- credentials, tokens, private URLs, or secrets

## Current feature areas

### Market Mapping Rule Engine

A configuration-driven M rule engine for applying market-data mapping overrides after a baseline mapping join. Microsoft Lists is the intended operational rules source, with connector-specific ingestion kept outside the core engine.
