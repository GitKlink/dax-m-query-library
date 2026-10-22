# Self-excluding manager-only hierarchy — Power Query (M)

> **Stage:** Experimental implementation on \`feature/worker-manager-hierarchy\`. **Power Query runtime verification is pending.** Do not treat this as a published library asset until the validation gate is complete.

## 🎯 Purpose and result

Flatten a single-manager worker reporting tree into **root-first ancestor-only level columns** in Power Query. A worker's own name/ID is never a member of their own manager-level path. Every original worker row is retained, including non-managers.

\`\`\`text
Input (worker -> immediate manager)
CEO (001)
└── Group Executive (002)
    ├── General Manager (003)
    │   ├── Employee A (004)
    │   ├── Employee B (005)
    │   └── Contractor D (007)
    └── Employee C (006)

Output levels for worker 004:
Manager Level 1 = CEO
Manager Level 2 = Group Executive
Manager Level 3 = General Manager
Worker 004 is NOT a hierarchy level.
\`\`\`

**No worker-level filter on \`IsManager\`.** This removes employee rows from metrics. Instead, use \`Manager Level N\` columns for hierarchy display and keep the complete flattened employee table as the data side of the model.

## 📦 Files

| Location | Role |
| --- | --- |
| [implementation/Table.FlattenManagerHierarchy.pq](implementation/Table.FlattenManagerHierarchy.pq) | Experimental M function, canonical feature-local prototype |
| [examples/synthetic-workers.pq](examples/synthetic-workers.pq) | Synthetic input with a reporting CEO / Group Executive / GM structure |
| [tests/Test.FlattenManagerHierarchy.pq](tests/Test.FlattenManagerHierarchy.pq) | Executable synthetic acceptance and error-rejection checks |
| [spec.md](spec.md) | Input/output contract, constraints, acceptance criteria |
| [adr/001-single-parent-worker-grain.md](adr/001-single-parent-worker-grain.md) | Single-parent versus multiple-parent decision |
| [tests/verification.md](tests/verification.md) | Exact Power Query verification, troubleshooting, matrix check |

After runtime acceptance, promote the function to \`library/m/functions/table/Table.FlattenManagerHierarchy.pq\` and move the engineering record to \`features/worker-manager-hierarchy/\` through the reviewed PR. There must not be two competing canonical implementations.

## 🛠️ Public API

\`\`\`powerquery
Table.FlattenManagerHierarchy(
    Source as table,
    ChildKey as text,
    ParentKey as text,
    DisplayName as text
) as table
\`\`\`

| Input | Meaning |
| --- | --- |
| \`Source\` | One row per worker with exactly one manager ID or \`null\` for root |
| \`ChildKey\` | Column name holding unique worker IDs; supply text IDs, e.g. \`EmployeeID\` |
| \`ParentKey\` | Column name holding immediate manager IDs, e.g. \`ManagerID\` |
| \`DisplayName\` | Column name holding a nonblank worker/manager display name |

**Call example** (after creating a Power Query function query named \`Table.FlattenManagerHierarchy\`):

\`\`\`powerquery
let
    Source = Workers,
    Flattened = #"Table.FlattenManagerHierarchy"(
        Source,
        "EmployeeID",
        "ManagerID",
        "EmployeeName"
    )
in
    Flattened
\`\`\`

**Power Query setup:** Open Power BI Desktop → **Transform data** → Power Query Editor → **New Source** → **Blank Query** (the menu may appear under **Home** or **New Source**), name it \`Table.FlattenManagerHierarchy\`, open **Advanced Editor**, and paste the complete code from the implementation file. The query preview should show a function. Then use the same method to create and run the synthetic example.

## 🔎 Expected output

Example (non-displayed columns omitted):

| EmployeeID | IsManager | DirectReportCount | Manager Level 1 | Manager Level 2 | Manager Level 3 |
| --- | --- | ---: | --- | --- | --- |
| 001 CEO | true | 1 | *(null)* | *(null)* | *(null)* |
| 002 Group Executive | true | 2 | CEO | *(null)* | *(null)* |
| 003 General Manager | true | 3 | CEO | Group Executive | *(null)* |
| 004 Employee A | false | 0 | CEO | Group Executive | General Manager |
| 005 Employee B | false | 0 | CEO | Group Executive | General Manager |
| 006 Employee C | false | 0 | CEO | Group Executive | *(null)* |
| 007 Contractor D | false | 0 | CEO | Group Executive | General Manager |

### Added field dictionary

| Field | Type | Exact semantics |
| --- | --- | --- |
| \`IsManager\` | logical | True if the worker ID appears as another input row's immediate manager |
| \`IsLeaf\` | logical | Complement of \`IsManager\`; leaf in the **provided source graph** |
| \`DirectReportCount\` | whole number | Number of input rows with this worker as immediate manager; includes contractors if in input |
| \`HasManagerReports\` | logical | At least one **direct report** is also a manager in the input |
| \`ManagerHierarchyDepth\` | whole number | Count of strict ancestors, root = 0 |
| \`HasManagerNode\` | logical | True if the worker has at least one ancestor and therefore contributes to a manager-level path |
| \`ManagerPathIDs\` | nullable text | Root-first ancestor keys joined by \`|\`; \`null\` for the root; no self key |
| \`Manager Level N\` | nullable text | Root-first ancestor manager's **display name**, suitable for matrix row levels |
| \`Manager Level N Key\` | nullable text | Same ancestor's **stable worker ID**, useful for unique identity and quality checks |

The number of level pairs is the **maximum ancestor depth in the supplied data**. Shallow rows have \`null\` for deeper levels. Two managers with the same name must be distinguished by keys in production modelling; names alone can combine distinct branches if Power BI groups by the text value.

## 📊 Power BI model and visual use

1. Keep the output at the **worker grain**, with the existing worker relationship into the relevant fact (or put ancestor columns in the single, conformed worker dimension). **Check:** the row count and distinct worker count remain unchanged.
2. Create a model hierarchy from \`Manager Level 1\`, \`Manager Level 2\`, etc.; do **not** use \`EmployeeName\` as an additional visible level. **Check:** only manager names appear in level columns.
3. Use normal additive measures and worker-level filters without \`IsManager = true\`. **Check:** a non-manager's test amount remains in their managers' organisation totals.
4. Distinguish same-name managers using manager-level key design (e.g. unique node labels/surrogate IDs) when required. **Check:** the visual does not merge two unrelated managers.
5. Validate visuals for ragged levels and totals before publishing. **Check:** empty-path rows and direct reports behave as the agreed reporting design.

### A crucial matrix limitation

Ancestor-only flattening **does not guarantee that every expanded native Matrix level is free of \`(Blank)\`**. When a manager has direct workers but another branch continues deeper, the shallow rows have null lower-level keys. Expanded matrices may show a blank branch. No metadata flag on a worker row alone can simultaneously guarantee: a) no blank category at every drill depth, b) every direct report counted, c) no manager self-contribution, and d) visually additive child nodes.

For this implementation, **do not silently filter blank levels**, because that removes direct workers from the visible subtotal. Possible later presentations: a manager-grain summary visual, a distinct \`Direct reports\` bucket, a hierarchy-aware visual, or a DAX display-only suppression mechanism (outside this feature's no-DAX requirement). The right choice depends on desired drill/total behaviour.

### CEO / executive arithmetic

- CEO node contains **6** descendants; CEO themselves contribute to **no** manager node.
- Group Executive node contains **5** descendants; Group Executive themselves remain in the **CEO** node, not their own.
- General Manager node contains **3** descendants, including Contractor D in this synthetic example.
- With \`CostIndex = 100\` for each input row, their strict descendant totals are respectively **600 / 500 / 300**.
- These are **hierarchical filter contexts**, not disjoint departments. Do not sum CEO + Group Executive + GM values to get an enterprise total.

## ⚠️ Data / modelling constraints

- **Single-parent:** one row for each worker, exactly one immediate manager or null. Multi-parent records fail on duplicate keys. Imke Feldmann's original supports multi-parent branches; this implementation deliberately does not.
- **Complete scope:** referenced manager IDs must exist as source worker IDs. Filtered datasets with missing managers fail rather than inventing a manager.
- **Cycles/self-parent:** fail with a \`HierarchyCycle\` error.
- **Names:** nonblank text values required; do not use names as unique keys.
- **IDs:** text recommended, including leading zeros. The \`|\` delimiter is disallowed in worker keys. Original ID columns remain unchanged.
- **Reserved outputs:** pre-existing \`Manager Level ...\`, named metadata fields, or \`__ManagerHierarchy\` collide and are rejected.
- **Worker type:** manager classification is structural, not a business role or HR eligibility rule. Contractor manager rows, where present, remain structural managers; counting employee-only spans requires a separate explicitly filtered population.
- **Security:** this function does not confer row-level security, access control or manager authorisation. Use the proper security model separately.
- **Performance:** ancestry is computed in memory per worker using buffered lookups. Verify refresh cost and Power Query/Fabric Dataflow compatibility on realistic data volumes before adoption.

## 🔗 Attribution and independence

Concept reference: Imke Feldmann, [\`ParentChildAllParents.pq\` gist](https://gist.github.com/ImkeF/3a6b50e705bfbdbcb3480b6be505322a). That original handles general parent/child flattening and can enumerate multiple parents.

This feature is a **new independently authored implementation**, not a pasted or modified copy of the gist. The gist page does not state a reusable code license; link and conceptual attribution are provided rather than importing its source under this repository's MIT license.

## 🧪 Verification state

- Synthetic expected output and executable query: **written; not executed in Power Query**.
- Negative cases: duplicate worker key, unknown parent, circular chain, blank worker key, pipe delimiter.
- Power BI Matrix presentation: **requires manual review**, especially ragged blanks, duplicate manager names and subtotals.
- Definition of done: all test rows return \`Pass = true\`, no refresh errors, model row grain/aggregates validated, reviewer agrees on matrix behaviour, then promote to published library.

See [tests/verification.md](tests/verification.md) for exact verification steps and failure recovery.
