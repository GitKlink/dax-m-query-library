# Market Mapping Rule Engine Tests

Tests should be behaviour-oriented and use synthetic in-memory Power Query tables.

Required V1 cases:

1. no-match preserves baseline;
2. ReplaceWith;
3. ReplaceSuffix;
4. first RuleID wins;
5. multiple same-group matches set conflict;
6. sequential RuleGroups;
7. StopAfterRuleGroup;
8. JobProfile scope;
9. ALL scope;
10. AttributeMap against renamed physical columns;
11. AddColumn mode;
12. Replace mode;
13. audit fields;
14. fail-fast invalid configuration.

Runtime status: **not yet executed in a Power Query host**.
