# ADR 001: Ordered RuleGroups with first-match RuleIDs

## Status
Accepted

## Context
Mapping exceptions need AND conditions, ordered alternatives, and potentially sequential transformations without introducing an arbitrary Boolean expression language.

## Decision
Use RuleGroups as ordered business-rule families. Within a RuleGroup, RuleIDs are ordered alternatives and the first matching RuleID wins. All conditions within a RuleID are ANDed. OR-of-AND behaviour is represented with multiple RuleIDs. RuleGroups execute sequentially and may stop subsequent processing with `StopAfterRuleGroup`.

Normal sequential application of multiple RuleGroups is intentional and is not itself a conflict. `RuleConflictDetected` is reserved for ambiguity such as multiple RuleIDs matching within the same RuleGroup.

`StopAfterRuleGroup` is triggered by a matching RuleID, even when the resulting action is a no-op.

## Consequences
The configuration remains tabular and Microsoft-List-friendly, while ambiguous same-group matches can be detected and surfaced. Rule ordering, rather than implicit specificity, controls interactions between groups.