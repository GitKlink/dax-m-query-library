# Market Mapping Rule Engine

Status: **In progress**

GitHub Issue: #1

Target published asset:

```text
library/m/functions/table/Table.ApplyMarketMappingOverrides.pq
```

## Purpose

Provide a reusable Power Query (M) rule engine that applies configurable market-data mapping exceptions after a normal baseline mapping join, without hard-coding business rules into the function.

## Feature contents

- `spec.md` — approved behaviour and configuration contract.
- `adr/` — feature-specific design decisions.
- `tests/` — behaviour-oriented test fixtures/cases.
- `examples/` — synthetic usage examples.

## Current state

The V1 implementation has been migrated from the earlier prototype branch into this repository and its source metadata updated. It has been structurally reviewed but has **not yet been executed in a Power Query runtime**. Runtime verification remains required before this feature should be moved to `features/` and merged as completed.

## Design summary

The engine:

- evaluates rows independently by country/survey/job-architecture scope;
- evaluates RuleGroups in configured order;
- uses first-match-wins RuleIDs within each group;
- requires all conditions within a RuleID to match;
- supports `ReplaceWith` and `ReplaceSuffix` actions;
- can replace the mapped market-code column or add an override column;
- emits audit fields describing applied rules/conflicts;
- keeps Microsoft List ingestion outside the core engine.
