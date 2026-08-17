# ADR 003: Keep Microsoft List ingestion outside the rule engine

## Status
Proposed

## Context
Microsoft List is the intended operational configuration source, but connector-specific Choice/boolean/internal-name shapes are unrelated to rule evaluation and would make the core engine harder to test and reuse.

## Decision
`Table.ApplyMarketMappingOverrides` accepts a canonical RulesTable only. A separate source-specific ingestion component owns Microsoft List connectivity, field selection, field-name translation, Choice flattening, blank normalization, logical conversion, and explicit typing.

The ingestion component is a separate deliverable and test seam within the overall feature. Microsoft List item ID does not drive RuleGroupID, RuleID, ConditionID, or execution order.

## Consequences
The engine is source-agnostic and testable with `#table(...)` fixtures. Ingestion can evolve independently or be replaced by Excel, SQL, Dataverse, or another source without changing the engine.