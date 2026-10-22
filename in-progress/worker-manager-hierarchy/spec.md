# Feature specification — worker-to-manager ancestor-only hierarchy

**Issue:** [#15](https://github.com/GitKlink/dax-m-query-library/issues/15)  
**Status:** Proposed engineering contract; pending actual Power Query runtime verification and human acceptance.  
**Implementation:** [Table.FlattenManagerHierarchy.pq](implementation/Table.FlattenManagerHierarchy.pq)

## 🎯 User problem

Power BI worker/manager hierarchies conventionally make an employee part of their own subtree when the employee node is used as the final level. The intended business visual instead groups by **managers' reporting organisations**: the Group Executive belongs to their CEO's node, but not their own, while ordinary non-managers must continue to contribute to organisation metrics.

Solution boundary: perform the reshaping in Power Query/Dataflows, not a DAX self-exclusion measure; preserve original row grain and usable fact relationships.

## Behavioural contract

### Inputs

- \`Source\`: table at worker grain, one row per unique \`ChildKey\`.
- \`ChildKey\`: name of a column identifying each worker uniquely.
- \`ParentKey\`: name of an immediate manager ID column; only graph roots can be null/empty.
- \`DisplayName\`: name of a column containing a nonblank display name.
- Referenced non-null parent IDs must be present as child IDs in the same input.
- Treat child/parent keys as text identifiers; source columns are not mutated.

### Outputs

- All source rows, unchanged in number and source-column values.
- \`IsManager\` and \`IsLeaf\`: structural manager/leaf flags.
- \`DirectReportCount\`: source-graph direct-worker count, independent of labour-force eligibility.
- \`HasManagerReports\`: flag indicating a manager has a direct report who is also a manager.
- \`ManagerHierarchyDepth\`: count of strict ancestors; root = 0.
- \`HasManagerNode\`: false for rows with no strict ancestors.
- \`ManagerPathIDs\`: \`|\`-delimited ID path from root to immediate manager, omitting current worker.
- Paired \`Manager Level N\` name and \`Manager Level N Key\` ID columns for each level up to maximum path depth. Names are display-only; IDs represent identity.
- Nullable values for missing trailing levels, never a self/worker name injected as a filler.
- Source columns retain their original Power Query column values and intended types.

### Semantic invariants

1. **Self exclusion:** For every worker \`w\`, \`w\` must not occur in the worker's manager-level key path.
2. **Ancestor correctness:** A manager ID occurs in \`w\`'s path iff it is a strict ancestor of \`w\` in the supplied graph.
3. **Manager-only level names:** Every non-null hierarchy display value resolves to a structural manager.
4. **One row per worker:** Cardinality remains unchanged from the input; no ancestor expansion into worker duplicates.
5. **Native aggregation:** Manager organisation totals can be evaluated by filtering the worker dimension on manager levels, with ordinary SUM/COUNT semantics where the fact model is properly keyed.
6. **No automatic eligibility rules:** \`IsManager\` does not mean employee-only manager; counts do not exclude contractors.
7. **No access grant:** Hierarchy membership is not row-level security.

### Rejection behaviour

| Input defect | Error identifier | Intended response |
| --- | --- | --- |
| Key/name columns absent | \`MissingColumns\` | Name the missing columns |
| Input selector columns identical | \`InvalidColumns\` | Require three distinct selector names |
| Existing result columns collide | \`OutputColumnCollision\` | Rename or remove conflicting source columns |
| Null/empty worker key | \`BlankWorkerID\` | Stop |
| Duplicate worker key (incl. alternate managers) | \`DuplicateWorkerID\` | Stop; multi-parent unsupported |
| Null/blank worker display name | \`BlankDisplayName\` | Stop |
| Pipe in worker key | \`InvalidWorkerID\` | Stop; delimiter forbidden |
| Unknown manager ID | \`UnknownParent\` | Stop; no synthetic ancestor inserted |
| Worker directly or indirectly manages self | \`HierarchyCycle\` | Stop with repeated ID |

### Expected result on synthetic example

\`\`\`text
Worker        Path IDs         Display manager path
CEO           null             (none)
Group Exec    001              CEO
General Mgr   001|002          CEO > Group Executive
Employee A    001|002|003      CEO > Group Executive > General Manager
Employee B    001|002|003      CEO > Group Executive > General Manager
Employee C    001|002          CEO > Group Executive
Contractor D  001|002|003      CEO > Group Executive > General Manager
\`\`\`

The CEO, Group Executive and General Manager strict-descendant counts are 6, 5 and 3, respectively, when including all synthetic source workers. \`DirectReportCount\` for these same nodes is 1, 2 and 3. Both numbers are valid but have different meanings.

## Data-flow design

\`\`\`text
worker/manager edges
    -> validate required fields, unique IDs, complete graph
    -> indexed ID -> (parent, name) lookup
    -> per-worker ancestor traversal + cycle detection
    -> reverse ancestry to root-first order
    -> depth-dependent name/ID columns + manager metadata
    -> original worker rows with new columns
    -> manager-only row hierarchy in Power BI model
\`\`\`

### Explicit out of scope

- No change to original Imke Feldmann gist code, which supports multiple parents.
- No DAX measure to hide a worker.
- No guaranteed removal of \`(Blank)\` nodes in a ragged native Power BI Matrix by M fields alone.
- No contractor/employee-specific business logic or manager permission design.
- No automatic construction of an aggregated manager fact table; may be a separate future feature.
- No duplicate-name disambiguation policy based on arbitrary domain identifiers; IDs are provided so a model can implement unique labels.
- No inferred ancestors across missing or filtered-out managers.

## 🧪 Test plan / acceptance gates

**Static/spec review:** verify the M source uses ID-based ancestry rather than display-name matching, preserves originals, and never appends worker self.

**Runtime suite:** load \`tests/Test.FlattenManagerHierarchy.pq\` in Power BI Desktop or an equivalent Power Query evaluator and require every \`Pass\` to be \`true\`; capture test results and exact engine version if available.

**Matrix evaluation:** place the manager display level columns in a native Matrix using synthetic amounts; verify manager filtering, ragged blank branches, child sum differences and whether user-accepted presentation needs a future enhancement.

**Refresh/performance:** representative worker volume, real source key types, different hierarchy depths, multiple roots, contractor managers where applicable. Record whether the implementation is acceptable for Dataflows and Desktop.

**Publication gate:** only after actual runtime verification, reviewer agreement on the subtotal/drill limitations, and final PR review may implementation move to \`library/m/functions/table/\`. Move the record to \`features/\` only at feature completion.
