# ADR 001: Ordered RuleGroups with first-match RuleIDs

## Status
Accepted

## Context
Mapping exceptions need AND conditions, ordered alternatives, and potentially sequential transformations without introducing an arbitrary Boolean expression language.

## Decision
Use RuleGroups as ordered business-rule families. Within a RuleGroup, RuleIDs are ordered alternatives and the first matching RuleID wins. All conditions within a RuleID are ANDed. OR-of-AND behaviour is represented with multiple RuleIDs. RuleGroups execute sequentially and may stop subsequent processing with `StopAfterRuleGroup`.

## Consequences
The configuration remains tabular and Microsoft-List-friendly, while ambiguous same-group matches can be detected and surfaced.
