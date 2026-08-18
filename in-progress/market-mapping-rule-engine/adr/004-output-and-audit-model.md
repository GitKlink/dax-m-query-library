# ADR 004: Global output mode plus explicit audit columns

## Status
Accepted

## Context
Testing and reconciliation require preserving baseline values, while production use may need the existing market-code column replaced. Rule-level output behavior would unnecessarily complicate configuration. Audit fields also need clear semantics for matched rules, applied transformations, and conflicts.

## Decision
Output behavior is a function-level option: `AddColumn` or `Replace`. The engine always emits explicit audit columns for original/final values, applied groups/rules/count, override status, and conflict detection.

A rule counts as applied only when its action changes the current market-code value. `OverrideApplied` therefore represents an actual transformation. Matched no-op rules are not included in applied-rule audit fields.

`RuleConflictDetected` represents ambiguous same-RuleGroup matches, not the intentional sequential application of multiple RuleGroups.

## Consequences
The rule configuration stays focused on business logic and consumers can choose reconciliation or replacement behavior without changing individual rules. Audit output remains focused on actual transformations while stop behavior can still be triggered by a matched no-op rule.