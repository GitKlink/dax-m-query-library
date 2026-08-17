# Market Mapping Rule Engine Tests

Tests are behaviour-oriented and use synthetic in-memory Power Query tables.

## Test queries

- `03-core-rule-evaluation.pq` — basic end-to-end evaluation, JobProfile/ALL scope, AND conditions, ReplaceWith, no-match and core audit output.
- `04-rule-ordering-and-conflicts.pq` — RuleGroup/RuleID ordering, first-match-wins, same-group conflict detection, sequential groups and matched-no-op stop behaviour.
- `05-condition-operators-and-types.pq` — all V1 condition operators plus Text, Number, Logical and Date comparisons.
- `06-actions-and-output-modes.pq` — ReplaceSuffix, ReplaceWith null recovery, AddColumn, Replace and applied/no-op audit semantics.
- `07-fail-fast-validation.pq` — approved fail-fast configuration failures.
- `08-microsoft-list-normalization.pq` — Microsoft List-shaped normalization into the canonical RulesTable and direct engine consumption.
- `09-engine-verification-suite.pq` — aggregate core-engine suite for queries 03–07.
- `10-microsoft-list-adapter-verification.pq` — dedicated Microsoft List adapter verification, including mixed connector shapes and multi-select rejection.

## Power Query runtime execution

1. Create/import the two function queries using these names:
   - `Table.ApplyMarketMappingOverrides`
   - `Table.NormalizeMicrosoftListMarketMappingRules`
2. Create/import each fixture query using its filename without `.pq` as the query name.
3. Evaluate `09-engine-verification-suite` for the core engine suite.
4. Evaluate `10-microsoft-list-adapter-verification` for the adapter suite.
5. A successful query returns only rows where `Pass = true`. Any failed assertion raises an error with fixture details.

Runtime status: **not yet executed in a Power Query host**. Ticket #11 owns real-runtime execution, defect resolution, and recording the verified result.
