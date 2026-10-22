# Analytics Library

Reusable Power BI and analytics engineering library containing Power Query (M), DAX, Python, and Deneb functions, patterns, utilities, visuals, and examples.

## Repository model

This repository separates **feature engineering** from **published reusable assets**.

```text
library/        Published, reusable assets
in-progress/    Active feature engineering records
features/       Completed feature engineering records
docs/           Repository-wide standards, ADRs, and agent conventions
```

A feature is the primary unit of development. A feature normally produces one reusable asset or one tightly related asset family, for example:

- an M custom function or pattern;
- a DAX measure, measure family, UDF, or pattern;
- a Python function, script, or analytics pattern;
- a Deneb visual, template, or Vega/Vega-Lite pattern.

## Development lifecycle

```text
GitHub Issue
    ↓
in-progress/<feature>/
    ├── README.md
    ├── spec.md
    ├── adr/
    ├── tests/
    ├── examples/
    └── experiments/   (only when useful)
    ↓
feature branch implementation
    ↓
review / PR
    ↓
published asset under library/
    ↓
engineering record moves to features/<feature>/
```

Use one independently deliverable feature per GitHub Issue and feature branch unless a spec explicitly defines a tightly coupled set.

## Published library

```text
library/
├── m/
│   ├── functions/
│   └── patterns/
├── dax/
│   ├── measures/
│   ├── udfs/
│   └── patterns/
├── python/
│   ├── functions/
│   ├── scripts/
│   └── patterns/
└── deneb/
    ├── visuals/
    ├── templates/
    └── patterns/
```

Subfolders should be created when an asset actually needs them rather than pre-populating empty taxonomy folders.

## Where this library fits

This is the **reusable implementation library**, not the project's AI architect, engineering-policy source or installer.

- **[Power BI / Fabric Architect](https://github.com/GitKlink/performance-reward-dashboard-architect)** orchestrates cross-repository Power BI/Fabric reviews and future installation. The [read-only DAX Measure Standards Reviewer](https://github.com/GitKlink/performance-reward-dashboard-architect/tree/main/.agents/skills/dax-measure-standards-review) is implemented there, **not in this library**.
- **[Power BI / Fabric Engineering Standards](https://github.com/GitKlink/power-bi-fabric-standards)** publishes the canonical naming, metadata, semantic-model and other engineering policies. This library *consumes* approved standards but does not maintain conflicting copies.
- **Performance & Reward domain authority** governs business meaning, population, eligibility and KPI semantics. Library examples are not approved business definitions.

**Terminology:** **Wayfinder** is Matt Pocock's planning skill used for early project research. It is not our product name, installer, agent or architecture layer. Ask Matt is a workflow tool, not the identity of this library.

## Agent / Ask Matt compatibility

Repository-wide context starts with:

- `AGENTS.md`
- `CONTEXT.md`
- `docs/agents/`
- `docs/adr/`
- `docs/guides/`

Feature-specific context lives inside the relevant `in-progress/<feature>/` or `features/<feature>/` folder. Ask Matt / engineering workflows should resolve repository rules first, then feature-specific context.

## Public repository policy

Use synthetic examples and fixtures. Do not commit confidential employee/remuneration data, proprietary survey data, private URLs, secrets, tokens, or company-specific material that is not intended for public release.
