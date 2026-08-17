# ADR 003: Keep Microsoft List ingestion outside the rule engine

## Status
Accepted

## Context
Microsoft List is the intended operational configuration source, but connector-specific Choice/boolean/internal-name shapes are unrelated to rule evaluation and would make the core engine harder to test and reuse.

## Decision
`Table.ApplyMarketMappingOverrides` accepts a canonical RulesTable only. A separate source query owns Microsoft List connectivity, field-name translation, Choice flattening, blank handling, and typing.

## Consequences
The engine is source-agnostic and testable with `#table(...)` fixtures. Ingestion can evolve independently or be replaced by Excel/SQL/Dataverse without changing the engine.
