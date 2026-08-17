# ADR 004: Global output mode plus explicit audit columns

## Status
Accepted

## Context
Testing/reconciliation requires preserving baseline values, while production use may need the existing market-code column replaced. Rule-level output behaviour would unnecessarily complicate configuration.

## Decision
Output behaviour is a function-level option: `AddColumn` or `Replace`. The engine always emits explicit audit columns for original/final values, applied groups/rules/count, override status, and conflict detection.

## Consequences
The rule configuration stays focused on business logic and consumers can choose a safe reconciliation mode or replacement mode without changing individual rules.
