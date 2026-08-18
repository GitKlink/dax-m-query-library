# Market Mapping Rule Engine — V1 Specification

## Problem Statement

Baseline market data is normally mapped through ordinary joins such as country + job profile + survey. Some workers require deterministic exceptions based on attributes such as position title, job profile, state, manager status, match type, or other row-level fields.

Hard-coding those exceptions directly in Power Query makes them difficult to maintain, audit, review, reuse, and govern. Business rules also need to be maintained outside the function itself so that rule changes do not require editing M code.

The engine therefore needs to support externally maintained configuration while remaining generic enough to work across differently shaped target datasets and independently of the operational rule source.

## Solution

Build a reusable Power Query (M) function that applies validated, ordered market-mapping overrides after the normal baseline mapping join.

The public function contract is:

```text
Table.ApplyMarketMappingOverrides(
    TargetTable,
    RulesTable,
    AttributeMap,
    OutputMode,
    optional OutputColumnName
)
```

The engine accepts:

- a target table containing baseline market mappings;
- a normalized rules table;
- a canonical-to-physical attribute map;
- a global output mode;
- an optional output-column name.

It returns the final market mapping plus explicit audit columns showing whether and how the mapping was changed.

Microsoft List is the intended operational rule source for V1, but Microsoft List connectivity and normalization are deliberately separate from the core engine. The engine receives a normal Power Query table and can therefore also operate with Excel, SQL, Dataverse, local `#table(...)` fixtures, or another future rule source without modification.

## User Stories

1. As a Power BI developer, I want market-mapping exceptions stored as configuration, so that I do not need to hard-code business exceptions in M.
2. As a rules maintainer, I want to activate or deactivate configured rules, so that rule changes can be controlled without deleting configuration.
3. As a rules maintainer, I want every active rule scoped to a specific country and survey, so that a rule cannot accidentally apply outside its intended market context.
4. As a rules maintainer, I want rules scoped to either a specific JobProfile or all job profiles in a country/survey, so that I can express both targeted and broad transformations.
5. As a rules maintainer, I want to maintain human-readable job-architecture names, so that the rule configuration is understandable to business users.
6. As a rules maintainer, I want to use row attributes such as position title, job profile ID, state, manager status, and match type as conditions, so that exceptions can reflect real mapping requirements.
7. As a rules maintainer, I want multiple conditions inside a RuleID to be combined with AND, so that a rule can require several facts to be true simultaneously.
8. As a rules maintainer, I want alternative rule pathways represented as separate ordered RuleIDs, so that OR-of-AND logic can be expressed without a complex Boolean expression language.
9. As a rules maintainer, I want RuleIDs grouped into ordered RuleGroups, so that related alternatives can be treated as one business rule family.
10. As a rules maintainer, I want the first matching RuleID in a RuleGroup to win, so that rule precedence is explicit and deterministic.
11. As a reviewer, I want the engine to flag when more than one RuleID in the same RuleGroup matches, so that ambiguous configuration can be detected even though the first rule still wins.
12. As a rules maintainer, I want multiple RuleGroups to execute sequentially, so that later rule families can intentionally transform the result of earlier rule families.
13. As a rules maintainer, I want RuleGroup execution order explicitly configured, so that broad and specific rule groups do not rely on hidden specificity precedence.
14. As a rules maintainer, I want a matched RuleGroup to optionally stop all later RuleGroups, so that some results can be treated as final.
15. As a rules maintainer, I want an action that replaces the market code with an exact configured value, so that exceptions can point directly to another mapping.
16. As a rules maintainer, I want an action that replaces a suffix on the current market code, so that architecture-wide transformations such as individual-contributor to manager mappings can be expressed without duplicating full codes.
17. As a developer, I want rules to refer to canonical attribute names rather than physical target-column names, so that the same RulesTable can be reused across different extracts.
18. As a developer, I want an AttributeMap to resolve canonical attributes to physical columns, so that Workday, EOY, Power BI, or other shaped extracts can use the same rule engine.
19. As a developer, I want the engine to validate required attribute mappings before processing rows, so that schema problems fail clearly rather than producing partial results.
20. As a developer, I want invalid operators, action types, value types, and unsupported job-architecture levels to fail validation, so that configuration mistakes are not silently treated as false conditions.
21. As a developer, I want text comparisons to be trimmed and case-insensitive, so that harmless formatting differences do not change rule outcomes.
22. As a rules maintainer, I want `In` conditions to support a simple pipe-delimited list, so that a single condition can match one of several configured values.
23. As a rules maintainer, I want blank detection to treat null, empty text, and whitespace-only text consistently, so that blank rules behave predictably.
24. As a developer, I want typed comparison support for Text, Number, Logical, and Date values, so that rules are not limited to text comparisons.
25. As a developer, I want a safe reconciliation mode that preserves the original market-code column and adds the final result separately, so that rule behavior can be tested before replacement.
26. As a developer, I want a production replacement mode that writes the final result back to the mapped market-code column, so that the engine can be used directly in normal transformation pipelines.
27. As a reviewer, I want original and final market codes returned as audit fields, so that I can compare before and after values.
28. As a reviewer, I want applied RuleGroup and RuleID identifiers returned, so that I can trace which configuration produced a result.
29. As a reviewer, I want a count of applied rules, so that rows with multiple sequential transformations can be identified.
30. As a reviewer, I want conflict detection to distinguish configuration ambiguity from normal sequential RuleGroup processing, so that intentional multi-stage transformations are not automatically treated as errors.
31. As a developer, I want a rule to count as applied only when its action changes the current market code, so that audit output represents actual transformations rather than merely matched conditions.
32. As a rules maintainer, I want `StopAfterRuleGroup` to stop later groups when a RuleID matches, even if its action results in no value change, so that stop behavior represents business precedence rather than mutation side effects.
33. As a developer, I want a `ReplaceWith` rule to be able to populate a null baseline market code, so that configuration can rescue missing baseline mappings.
34. As a developer, I want a `ReplaceSuffix` action against a null or non-matching current code to leave the value unchanged, so that suffix rules are safe when their prerequisite shape is absent.
35. As a developer, I want no matching rule to preserve the baseline mapping and return `OverrideApplied = false`, so that the engine is non-destructive by default.
36. As a developer, I want configuration validation to occur before row processing, so that a structurally invalid rule set does not partially process a dataset.
37. As a developer, I want the core engine testable with local synthetic tables, so that Microsoft List connectivity is not required for rule-engine tests.
38. As a developer, I want Microsoft List normalization tested independently from rule evaluation, so that connector-specific failures can be isolated from engine failures.
39. As a Microsoft List maintainer, I want constrained vocabularies stored as single-select Choice fields where practical, so that configuration typos are reduced.
40. As a Microsoft List maintainer, I want free-form values and action values stored as text, so that the list remains simple while `ValueType` determines interpretation.
41. As a developer, I want Microsoft List display/internal field names translated before the engine is called, so that connector implementation details do not leak into the rule contract.
42. As a developer, I want Microsoft List item IDs excluded from rule identity and execution ordering, so that business semantics remain explicit and portable.
43. As a developer, I want reserved future job-architecture levels to fail clearly in V1, so that future configuration cannot appear to work while actually being ignored.
44. As a reviewer, I want the feature considered incomplete until it has been executed against synthetic fixtures in a real Power Query runtime, so that static inspection is not mistaken for runtime verification.

## Implementation Decisions

### Public function and primary seam

- The reusable engine is exposed as one public M function with inputs `TargetTable`, `RulesTable`, `AttributeMap`, `OutputMode`, and optional `OutputColumnName`.
- The public function is the primary behavioral seam for testing.
- The engine runs after the normal baseline market-data mapping join.
- The expected target grain is approximately worker × job profile × survey.
- `Primary` / `Secondary` or another `MatchType` value is ordinary conditionable row data, not special engine scope.

### Source separation

- Microsoft List is the intended operational rules source for V1.
- Microsoft List connectivity and normalization remain outside the reusable engine.
- A source-specific ingestion query owns field selection, internal/display-name translation, Choice flattening, logical conversion, blank normalization, and explicit typing.
- The ingestion query returns the canonical `RulesTable` contract.
- Microsoft List item ID does not define RuleGroupID, RuleID, ConditionID, or execution order.
- Multi-select Choice behavior is excluded from V1.

### Rule scope

- Every active rule is explicitly scoped by `CountryID`, `SurveyID`, `JobArchitectureLevel`, and `JobArchitectureName`.
- Country is always explicit; Country `ALL` is not supported in V1.
- Reserved job-architecture vocabulary is `JobProfile`, `Job`, `JobFamily`, `JobFamilyGroup`, and `ALL`.
- V1 executes only `JobProfile` and `ALL`.
- `JobProfile` scope matches canonical `JobProfileName`.
- `ALL` scope requires `JobArchitectureName = ALL`.
- Unsupported reserved architecture levels fail validation rather than being skipped.
- There is no hidden specificity precedence between `ALL` and JobProfile-scoped groups. `RuleGroupExecutionOrder` controls execution.

### JobProfile-name validation

- V1 validates configured JobProfile names against JobProfile names present in `TargetTable`.
- A configured JobProfile name not present in the current target dataset is treated as a configuration error and fails validation.
- This is intentionally strict for V1, but it has a known trade-off: a valid configured profile with zero current workers will also fail.
- If a separate authoritative job-architecture reference table is introduced later, validation should move to that reference rather than the current target population.

### RulesTable contract

- RulesTable uses one row per condition.
- Required columns are:
  - `CountryID`
  - `SurveyID`
  - `JobArchitectureLevel`
  - `JobArchitectureName`
  - `RuleGroupID`
  - `RuleGroupExecutionOrder`
  - `RuleID`
  - `RuleExecutionOrder`
  - `ConditionID`
  - `Field`
  - `Operator`
  - `Value`
  - `ValueType`
  - `ActionType`
  - `ActionValue`
  - `ActionFrom`
  - `ActionTo`
  - `StopAfterRuleGroup`
  - `Active`
- Repeated RuleID scope/action metadata must be identical across all of its condition rows.
- Rule execution order must be unambiguous within each RuleGroup scope.
- RuleGroup execution metadata must be internally consistent.

### Evaluation model

- A RuleGroup is an ordered business-rule family.
- RuleGroups execute in ascending `RuleGroupExecutionOrder`.
- RuleIDs inside each RuleGroup execute in ascending `RuleExecutionOrder`.
- All conditions within one RuleID are ANDed.
- The first matching RuleID wins inside a RuleGroup.
- If more than one RuleID in the same RuleGroup matches, the first still wins and `RuleConflictDetected = true`.
- OR-of-AND behavior is represented by separate RuleIDs rather than nested condition groups.
- Multiple RuleGroups may intentionally apply sequentially to the same row.
- Normal sequential application of more than one RuleGroup is **not by itself a conflict**.
- `StopAfterRuleGroup = true` stops all later RuleGroups when that group has a matching RuleID, regardless of whether the winning action changes the current market-code value.

### Applied-rule semantics

- A RuleID counts as **matched** when all of its conditions evaluate true.
- A RuleID counts as **applied** only when its action changes the current market-code value.
- `AppliedRuleGroups`, `AppliedRuleIDs`, and `AppliedRuleCount` record applied transformations, not merely matched no-op rules.
- `OverrideApplied = true` when at least one rule actually changes the market code.
- A matched `ReplaceSuffix` whose suffix is absent is therefore a no-op and is not included in applied-rule audit fields.
- Stop semantics are independent of applied semantics: a matched no-op rule can still stop later RuleGroups when configured to do so.

### Conditions and comparison behavior

- Supported operators are `Equals`, `NotEquals`, `StartsWith`, `EndsWith`, `Contains`, `In`, `IsBlank`, and `IsNotBlank`.
- Supported `ValueType` values are `Text`, `Number`, `Logical`, and `Date`.
- Text comparisons are trimmed and case-insensitive.
- `In` uses `|` as the configured list delimiter.
- `IsBlank` treats null, empty text, and whitespace-only text as blank.
- Invalid operators or value types fail configuration validation.

### Actions

- V1 supports exactly one action per RuleID.
- `ReplaceWith` sets the current market code to `ActionValue` and may populate a null baseline mapping.
- `ReplaceSuffix` changes the configured `ActionFrom` suffix to `ActionTo` when the current code ends with that suffix.
- `ReplaceSuffix` leaves null or non-matching codes unchanged.
- Supported action types are validated before row processing.

### AttributeMap

- Rules use canonical field names rather than physical target-column names.
- AttributeMap uses `CanonicalAttribute`, `TargetColumn`, and `DataType` columns.
- Required canonical mappings include `CountryID`, `SurveyID`, and `MarketDataCode`, plus `JobProfileName` when JobProfile-scoped rules exist, plus every canonical field referenced by active rule conditions.
- Duplicate canonical mappings fail validation.
- Missing mapped target columns fail validation.
- AttributeMap decouples reusable rules from Workday, EOY, Power BI, or other physical schemas.

### Output behavior

- Output mode is global to a function invocation, not configurable per rule.
- `AddColumn` preserves the original physical market-code column and adds the final value in `OutputColumnName`.
- The default AddColumn output name is `MarketDataCode_Override`.
- `Replace` replaces the physical target column mapped to canonical `MarketDataCode`.
- Reserved audit/output-column collisions fail validation.

### Audit behavior

The function adds:

- `OriginalMarketDataCode`
- `FinalMarketDataCode`
- `OverrideApplied`
- `AppliedRuleGroups`
- `AppliedRuleIDs`
- `AppliedRuleCount`
- `RuleConflictDetected`

Additional decisions:

- Multiple applied group/rule identifiers are pipe-delimited.
- No match preserves the original mapping and returns `OverrideApplied = false`.
- `RuleConflictDetected` represents ambiguous same-RuleGroup matching, not normal multi-stage RuleGroup execution.
- A future version may add richer diagnostic fields for matched-but-no-op rules, but that is not required in V1.

### Fail-fast validation

The engine validates configuration before target-row processing, including at minimum:

- required RulesTable columns;
- required AttributeMap columns;
- unique canonical AttributeMap entries;
- canonical fields required by active rules are mapped;
- mapped physical target columns exist;
- supported operators;
- supported action types;
- supported value types;
- supported architecture levels;
- `ALL` scope uses `JobArchitectureName = ALL`;
- configured JobProfile names exist in current TargetTable under the V1 strict-validation decision;
- repeated RuleID metadata/action values are consistent;
- RuleExecutionOrder is unambiguous within RuleGroup scope;
- RuleGroup execution metadata is consistent;
- reserved audit/output columns do not collide with TargetTable.

### Microsoft List column design

Recommended operational List types:

| RulesTable column | Microsoft List type |
|---|---|
| `CountryID` | Text or single-select Choice |
| `SurveyID` | Text or single-select Choice |
| `JobArchitectureLevel` | Single-select Choice |
| `JobArchitectureName` | Text |
| `RuleGroupID` | Text |
| `RuleGroupExecutionOrder` | Number |
| `RuleID` | Text |
| `RuleExecutionOrder` | Number |
| `ConditionID` | Number |
| `Field` | Single-select Choice or text |
| `Operator` | Single-select Choice |
| `Value` | Text |
| `ValueType` | Single-select Choice |
| `ActionType` | Single-select Choice |
| `ActionValue` | Text |
| `ActionFrom` | Text |
| `ActionTo` | Text |
| `StopAfterRuleGroup` | Yes/No |
| `Active` | Yes/No |

Choice is preferred for constrained vocabularies where practical. `Value`, `ActionValue`, `ActionFrom`, and `ActionTo` remain text at the List layer.

## Testing Decisions

### Testing philosophy

- Test externally observable behavior rather than internal implementation steps.
- Use the public rule-engine function as the main test seam.
- Prefer small synthetic `#table(...)` fixtures with explicit expected results.
- Do not require Microsoft List connectivity for core rule-engine tests.
- Test Microsoft List ingestion separately against representative connector shapes.
- Do not use real employee, remuneration, company-confidential, proprietary survey, or private SharePoint data in repository tests.

### Core engine acceptance behavior

The V1 engine is acceptable when runtime tests demonstrate all of the following:

1. A row with no eligible/matching rule retains its baseline code and returns `OverrideApplied = false`.
2. `ReplaceWith` changes only rows whose rule scope and conditions match.
3. `ReplaceWith` can populate a null baseline code.
4. `ReplaceSuffix` changes a matching suffix and preserves the prefix.
5. `ReplaceSuffix` leaves null codes unchanged.
6. `ReplaceSuffix` leaves non-matching suffixes unchanged.
7. All conditions within a RuleID must match for that RuleID to match.
8. RuleIDs are evaluated in `RuleExecutionOrder` and the first matching rule wins.
9. If multiple RuleIDs in the same RuleGroup match, the first wins and `RuleConflictDetected = true`.
10. Multiple RuleGroups execute in `RuleGroupExecutionOrder` and later groups see the current result produced by earlier groups.
11. Multiple sequential RuleGroups changing the value do not automatically set `RuleConflictDetected`.
12. `StopAfterRuleGroup = true` prevents later groups after a RuleID matches.
13. A matched no-op RuleID with `StopAfterRuleGroup = true` still prevents later groups.
14. A matched action that makes no value change is not recorded in applied-rule audit fields.
15. JobProfile scope applies only to matching `JobProfileName` rows.
16. `ALL` scope applies regardless of job profile within the matching country/survey.
17. Explicit RuleGroupExecutionOrder determines interaction between JobProfile and ALL groups.
18. Country and Survey scope prevent a rule applying to another country or survey.
19. AttributeMap resolves different physical column names correctly.
20. `MatchType` can be used as an ordinary mapped condition field.
21. `Equals` and `NotEquals` behave correctly for supported ValueTypes.
22. `StartsWith`, `EndsWith`, and `Contains` are trimmed/case-insensitive for text.
23. `In` handles pipe-delimited configured values.
24. `IsBlank` recognizes null, empty, and whitespace-only text.
25. `IsNotBlank` is the inverse of blank behavior.
26. `AddColumn` preserves the original market-code column and creates the requested/default override column.
27. `Replace` updates the mapped physical market-code column.
28. Audit fields return original/final code, applied groups/rules/count, override flag, and conflict flag correctly.
29. Invalid required RulesTable columns fail before row processing.
30. Invalid AttributeMap schema or duplicate canonical mappings fail before row processing.
31. Missing physical target columns fail before row processing.
32. Unsupported operators fail validation.
33. Unsupported action types fail validation.
34. Unsupported ValueTypes fail validation.
35. Unsupported reserved JobArchitectureLevel values such as JobFamily fail clearly in V1.
36. `ALL` architecture with a non-ALL architecture name fails validation.
37. A configured JobProfileName absent from the current TargetTable fails validation under the V1 strict rule.
38. Inconsistent repeated RuleID metadata/actions fail validation.
39. Duplicate RuleExecutionOrder values within one RuleGroup scope fail validation.
40. Inconsistent RuleGroup execution metadata fails validation.
41. Existing reserved audit/output columns fail validation rather than being silently overwritten.

### Microsoft List ingestion acceptance behavior

The source-normalization component is acceptable when tests or controlled connector examples demonstrate that:

1. required List source fields are selected and renamed to canonical RulesTable names;
2. internal/display-name differences are explicitly handled;
3. single-select Choice values are flattened to scalar text;
4. Yes/No fields become logical true/false;
5. execution-order and condition-order fields become explicit numeric types;
6. blank fields are normalized consistently;
7. only the canonical RulesTable shape is passed to the core engine;
8. Microsoft List item ID is not used for rule identity or execution semantics.

### Runtime verification requirement

- The feature must be executed against synthetic fixtures in a real Power Query runtime before it can be marked complete.
- Static code inspection alone is insufficient.
- Any runtime defects discovered must be resolved before the feature record is promoted from `in-progress/` to `features/` and before the PR is ready to merge.

## Out of Scope

V1 does not include:

- Microsoft List connectivity inside `Table.ApplyMarketMappingOverrides`;
- multi-select Choice semantics inside the core engine;
- arbitrary nested Boolean expressions;
- alternative condition groups inside one RuleID;
- execution for `Job`, `JobFamily`, or `JobFamilyGroup` scopes;
- Country `ALL` scope;
- effective dating or market-data year as special engine scope;
- automatic Primary/Secondary selection;
- vendor benchmark-code existence validation;
- regex operators;
- `Between` operator;
- multiple actions per RuleID;
- implicit specificity precedence between rule scopes;
- a separate authoritative job-architecture reference-table input;
- rich diagnostics for matched-but-no-op rules beyond the agreed audit fields;
- automatic Microsoft List creation or governance workflow.

## Further Notes

### Example business shape

A synthetic RuleGroup such as `HOME_LENDING_EXECUTIVES` may contain alternatives like:

```text
Executive 1
  PositionTitle EndsWith "1"
  AND JobProfileID Equals "xxxx.16"
  → CODE_1

Executive 2
  PositionTitle EndsWith "2"
  AND JobProfileID Equals "xxxx.16"
  → CODE_2

Director
  PositionTitle Equals "Director"
  AND JobProfileID Equals "xxxx.16"
  → DIRECTOR_CODE
```

A later ALL-scope RuleGroup may independently convert an IC suffix to a manager suffix. That sequential transformation is intentional and does not by itself constitute a conflict.

### Prototype status

A migrated M implementation already exists on the feature branch. It is treated as a prototype against this specification, not as the source of truth. After spec approval, implementation tickets must compare the prototype behavior to this specification and change the implementation where they differ.

### Approval gate

This specification is **Proposed** until reviewed and approved by the repository owner. Do not create implementation tickets from it until that approval is given. After approval, the next workflow step is `to-tickets`.