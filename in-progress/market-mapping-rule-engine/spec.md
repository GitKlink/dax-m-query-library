# Market Mapping Rule Engine — V1 Specification

## Problem Statement

Baseline market data is normally mapped by ordinary joins such as country + job profile + survey. Some workers require deterministic exceptions based on attributes such as position title, job profile, state, manager status, or other row-level fields.

Hard-coding those exceptions directly in Power Query makes them difficult to maintain, audit, reuse, and govern. The solution needs to support externally maintained configuration while keeping the reusable engine independent of the operational configuration source.

## Solution

Implement a reusable M function:

```text
Table.ApplyMarketMappingOverrides(
    TargetTable,
    RulesTable,
    AttributeMap,
    OutputMode,
    optional OutputColumnName
)
```

The function applies validated, ordered rules to target rows after baseline mapping and returns the final market code plus audit information.

Microsoft List is the intended operational source for V1 rules, but List connectivity/normalisation is a separate ingestion concern. The engine accepts a normalised Power Query table and can therefore also work with Excel, SQL, Dataverse, local `#table(...)` fixtures, or other sources.

## Architecture

```text
Microsoft List
    ↓
source-specific ingestion / normalisation query
    ↓
canonical RulesTable

Target employee + market-match table
    ↓
AttributeMap
    ↓
Table.ApplyMarketMappingOverrides
    ↓
final market mapping + audit columns
```

## User Stories

- As a report/data-model developer, I can maintain mapping exceptions as configuration instead of editing M code.
- As a rules maintainer, I can express ordered alternatives within a business rule family.
- As a developer, I can reuse the same rules against target extracts with different physical column names.
- As a reviewer, I can see which rule(s) changed a mapping and detect ambiguous matches.
- As a developer, I can test the rule engine using in-memory fixtures without Microsoft List connectivity.

## Function Inputs

1. `TargetTable` — employee/market-match rows after baseline mapping.
2. `RulesTable` — normalised configuration; one row per rule condition.
3. `AttributeMap` — canonical attribute to physical target-column mapping.
4. `OutputMode` — `Replace` or `AddColumn`.
5. `OutputColumnName` — optional; used in AddColumn mode. Default: `MarketDataCode_Override`.

## Target Grain and Match Type

The expected target grain is approximately worker × job profile × survey. Primary/Secondary may exist as normal row attributes. `MatchType` is not special engine scope and may be used as an ordinary rule condition if mapped through `AttributeMap`.

## Rule Scope

Every active rule is scoped by:

- `CountryID`
- `SurveyID`
- `JobArchitectureLevel`
- `JobArchitectureName`

Reserved architecture-level vocabulary:

- `JobProfile`
- `Job`
- `JobFamily`
- `JobFamilyGroup`
- `ALL`

V1 executes only:

- `JobProfile`
- `ALL`

Unsupported reserved levels fail clearly rather than being silently ignored.

For `JobProfile`, `JobArchitectureName` matches canonical `JobProfileName`. For `ALL`, `JobArchitectureName` must equal `ALL`.

Country is always explicit; there is no Country `ALL` in V1.

## RulesTable Contract

One row represents one condition.

Required columns:

| Column | Purpose |
|---|---|
| `CountryID` | Country scope |
| `SurveyID` | Survey scope |
| `JobArchitectureLevel` | `JobProfile` or `ALL` in V1 |
| `JobArchitectureName` | Architecture name or `ALL` |
| `RuleGroupID` | Business rule family |
| `RuleGroupExecutionOrder` | Sequence across RuleGroups |
| `RuleID` | Complete IF → THEN rule |
| `RuleExecutionOrder` | First-match ordering within group |
| `ConditionID` | Condition identifier/order reference |
| `Field` | Canonical target attribute |
| `Operator` | Comparison operator |
| `Value` | Condition value |
| `ValueType` | Text/Number/Logical/Date |
| `ActionType` | `ReplaceWith` or `ReplaceSuffix` |
| `ActionValue` | Replacement value for ReplaceWith |
| `ActionFrom` | Existing suffix for ReplaceSuffix |
| `ActionTo` | New suffix for ReplaceSuffix |
| `StopAfterRuleGroup` | Stop later groups after this group matches |
| `Active` | Enables/disables rule rows |

Because RuleID metadata repeats across condition rows, repeated scope/action metadata for the same RuleID must be identical.

## Rule Hierarchy

```text
CountryID
+ SurveyID
+ JobArchitectureLevel
+ JobArchitectureName
    ↓
RuleGroupID
    ↓
RuleID
    ↓
ConditionID rows
    ↓
one Action
```

### RuleGroups

A RuleGroup is a business rule family / ordered set of alternative rules for one mapping purpose.

RuleGroups execute in `RuleGroupExecutionOrder`. Multiple groups may modify the same current market code sequentially. A group can set `StopAfterRuleGroup = true` to make a matched result final for subsequent group processing.

### RuleIDs

RuleIDs within a group behave like SWITCH/case alternatives. They execute in `RuleExecutionOrder`; the first matching RuleID wins.

If multiple RuleIDs in the same group match the same row, the first is still applied and `RuleConflictDetected` is set.

### Conditions

All conditions for a RuleID are combined with AND.

OR-of-AND alternatives are represented as separate RuleIDs that return the same result. Arbitrary nested Boolean logic is out of scope for V1.

## Supported Operators

- `Equals`
- `NotEquals`
- `StartsWith`
- `EndsWith`
- `Contains`
- `In`
- `IsBlank`
- `IsNotBlank`

Text comparisons are trimmed and case-insensitive.

`In` uses `|` as a delimiter, for example:

```text
VIC|NSW|QLD
```

Blank means null, empty string, or whitespace-only text.

Invalid operators fail configuration validation.

## Value Types

- `Text`
- `Number`
- `Logical`
- `Date`

Invalid value types fail configuration validation.

## Actions

One action is supported per RuleID in V1.

### ReplaceWith

Sets the current market data code exactly to `ActionValue`. This may populate a null baseline mapping.

### ReplaceSuffix

If the current market code ends with `ActionFrom`, replace that suffix with `ActionTo`.

Example:

```text
FINANCE.IC3 → FINANCE.M3
```

If the current value is null or the suffix does not match, leave it unchanged.

## AttributeMap

Rules refer to canonical attributes rather than physical target column names.

Schema:

| CanonicalAttribute | TargetColumn | DataType |
|---|---|---|
| `CountryID` | `Country` | `Text` |
| `SurveyID` | `Survey_Code` | `Text` |
| `JobProfileName` | `Job Profile` | `Text` |
| `JobProfileID` | `JP_ID` | `Text` |
| `PositionTitle` | `Title` | `Text` |
| `State` | `WorkState` | `Text` |
| `IsManager` | `MgrFlag` | `Logical` |
| `MarketDataCode` | `Market_Code` | `Text` |

The engine validates required canonical mappings, duplicate canonical keys, and missing physical columns before processing rows.

## Output Modes

### AddColumn

Preserves the original physical market-code column and adds the final value in `OutputColumnName` (default `MarketDataCode_Override`). Recommended for reconciliation/testing.

### Replace

Replaces the physical target column mapped to canonical `MarketDataCode` with the final value.

Output mode is a function-level option, not a per-rule setting.

## Audit Output

The function adds:

- `OriginalMarketDataCode`
- `FinalMarketDataCode`
- `OverrideApplied`
- `AppliedRuleGroups`
- `AppliedRuleIDs`
- `AppliedRuleCount`
- `RuleConflictDetected`

Multiple group/rule IDs are pipe-delimited.

No matching rule preserves the baseline mapping and returns `OverrideApplied = false`.

## Microsoft List Operational Source

The operational rule configuration is intended to live in Microsoft List. The source query should:

1. connect to the configured List;
2. select only rule-engine fields;
3. translate List internal/display field names to the canonical RulesTable names;
4. flatten Choice values;
5. normalise Yes/No values to logical values;
6. type execution-order fields as numbers;
7. normalise blanks consistently to null where appropriate;
8. apply explicit Power Query types;
9. return the canonical RulesTable.

Recommended List types:

| RulesTable column | Microsoft List type |
|---|---|
| CountryID | text or single Choice |
| SurveyID | text or single Choice |
| JobArchitectureLevel | single Choice |
| JobArchitectureName | text |
| RuleGroupID | text |
| RuleGroupExecutionOrder | Number |
| RuleID | text |
| RuleExecutionOrder | Number |
| ConditionID | Number |
| Field | Choice or text |
| Operator | single Choice |
| Value | text |
| ValueType | single Choice |
| ActionType | single Choice |
| ActionValue | text |
| ActionFrom | text |
| ActionTo | text |
| StopAfterRuleGroup | Yes/No |
| Active | Yes/No |

Use Choice for constrained vocabularies where useful, but keep values/action values as text and interpret them using `ValueType`/action semantics.

Microsoft List item ID must not drive RuleID or execution order. Multi-select Choice semantics are out of scope for V1.

## Validation Decisions

Configuration errors fail before row processing rather than silently skipping rules.

Validate at minimum:

- required RulesTable columns;
- required AttributeMap columns;
- unique CanonicalAttribute mappings;
- canonical fields referenced by active rules are mapped;
- mapped physical columns exist;
- supported operators/action/value types/architecture levels;
- ALL scope uses name ALL;
- configured JobProfile names exist in the target data (V1 decision; revisit if a separate architecture reference table is introduced);
- repeated RuleID metadata/actions are consistent;
- RuleExecutionOrder is unambiguous within scope;
- RuleGroup execution metadata is consistent;
- audit/output columns do not collide with existing target columns.

## Testing Decisions

The public function is the primary test seam. Tests should use small synthetic `#table(...)` fixtures and must not depend on Microsoft List connectivity.

Microsoft List ingestion should be tested separately against representative connector shapes.

Minimum V1 behaviour coverage:

- no match preserves baseline;
- ReplaceWith;
- ReplaceSuffix;
- first RuleID wins;
- multiple matching RuleIDs flag conflict;
- multiple RuleGroups execute sequentially;
- StopAfterRuleGroup;
- JobProfile scope;
- ALL scope;
- AttributeMap resolves differently named target columns;
- AddColumn preserves original code;
- Replace updates mapped code;
- audit output identifies applied rules/groups;
- invalid configuration fails before row processing.

## Example Business Shape

A synthetic `HOME_LENDING_EXECUTIVES` group might include alternatives such as:

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

A later ALL-scope group could independently convert an IC suffix to a manager suffix.

## Out of Scope for V1

- Microsoft List connectivity inside the core function;
- multi-select Choice semantics inside the engine;
- arbitrary nested Boolean logic;
- alternative condition groups within a single RuleID;
- Job/JobFamily/JobFamilyGroup execution;
- effective dating / market year as special engine scope;
- automatic Primary/Secondary selection;
- vendor benchmark-code existence validation;
- regex;
- Between operator;
- multiple actions per RuleID.

## Completion Requirement

The migrated V1 implementation must be executed against synthetic fixtures in an actual Power Query runtime before the feature is considered complete. Until that occurs, it remains under `in-progress/` and should not be represented as runtime-verified.
