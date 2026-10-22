# Runtime verification — self-excluding manager hierarchy

**Current state:** Not yet executed in a Power Query runtime. These are runnable instructions and expected results, **not evidence that they have passed**.

**Goal:** Confirm the function keeps all worker rows but exposes only manager ancestors as level columns, rejects invalid graphs, and produces correctly scoped organisation totals.

**Prerequisite:** Power BI Desktop with Power Query Editor or another compatible Power Query evaluator; files from [this feature directory](../README.md).

## 🧭 Plan

\`\`\`text
1. Load M function
2. Run synthetic example
3. Run 20 automated checks
4. Inspect native Matrix drill behaviour
5. Record evidence + review decision
\`\`\`

## Step 1 of 5 — Load the function

**Where:** Power BI Desktop → **Home → Transform data** (Power Query Editor) → **New Source → Blank Query**. Menus vary slightly across releases.

1. Rename the new query exactly \`Table.FlattenManagerHierarchy\`.
2. Open **Advanced Editor**.
3. Replace the default M with all content of [Table.FlattenManagerHierarchy.pq](../implementation/Table.FlattenManagerHierarchy.pq).
4. Select **Done**.

**Expected:** Query shows a **function** with inputs \`Source\`, \`ChildKey\`, \`ParentKey\`, \`DisplayName\`; no error banner.

**If different:** Verify the complete \`let … in Table.FlattenManagerHierarchy\` block was copied without Markdown backticks. Save the exact error message instead of editing the algorithm on speculation.

**STOP:** Do not run the test query until the function visibly loads.

## Step 2 of 5 — Verify synthetic example

**Where:** Power Query Editor → New Source → Blank Query.

1. Rename query to \`Example.FlattenManagerHierarchy\`.
2. Open **Advanced Editor**.
3. Paste [synthetic-workers.pq](../examples/synthetic-workers.pq).

**Expected:**
- 7 rows, still including the three managers and four worker records (one contractor).
- Root \`001\` has \`ManagerHierarchyDepth = 0\`, \`HasManagerNode = false\`, and no manager-level values.
- \`002\` has \`Manager Level 1 Key = 001\`, with all deeper levels null.
- \`003\` has \`Manager Level 1 Key = 001\` and \`Manager Level 2 Key = 002\`.
- \`004\` and \`005\` have \`ManagerPathIDs = 001|002|003\`, and \`Manager Level 3 = General Manager\`.
- \`006\` ends at \`Manager Level 2 = Group Executive\`.
- \`007\` remains in the worker data, despite being a contractor.

**If different:** Copy the exact error and the first unexpected row; retain the input fixture unchanged for diagnosis.

**STOP:** Proceed only if the example refreshes with 7 rows and the named level values.

## Step 3 of 5 — Run the synthetic test suite

**Where:** Power Query Editor → New Source → Blank Query.

1. Name it \`Test.FlattenManagerHierarchy\`.
2. Paste [Test.FlattenManagerHierarchy.pq](Test.FlattenManagerHierarchy.pq) into **Advanced Editor**.
3. Inspect columns \`Check\`, \`Pass\`, and \`Expected\`.

**Expected:** Exactly **20 test rows**, every \`Pass = true\`. The suite checks: source grain, retained numerical values, strict ancestor paths, root behavior, structural metadata, CEO/Group Executive/GM strict-descendant totals, contractor inclusion, non-manager name suppression, and invalid-input errors.

**If any \`Pass = false\`:** Capture that \`Check\` and \`Expected\` row and relevant example output. Do not publish the function to \`library/\`.

**If the test query errors instead of showing 20 rows:** Copy the complete Power Query error text. This is a test failure; don't mark unexecuted checks passed.

## Step 4 of 5 — Inspect Matrix semantics

**Where:** Power BI Desktop Report view, after **Close & Apply** on the synthetic example.

1. Add a **Matrix** visual.
2. Place \`Manager Level 1\`, then \`Manager Level 2\`, then \`Manager Level 3\` in **Rows**.
3. Use a normal SUM of \`CostIndex\` in **Values**, with no \`IsManager\` worker filter.
4. Compare manager node totals against strict-descendant values:

| Manager context | Expected sum of \`CostIndex\` |
| --- | ---: |
| CEO | 600 |
| Group Executive | 500 |
| General Manager | 300 |

**Important:** A Matrix may show \`(Blank)\` in expanded sublevels because direct reports have no deeper manager level. Test whether this occurs and document the visuals/requirements. Do **not** hide blank branches or apply \`IsManager = true\` to make the Matrix look cleaner; doing so changes which workers contribute. A manager's own row is counted under their superior only, so the visible child-manager subtotals are not expected to add to a superior's total unless direct workers receive a distinct display bucket.

**If sums differ:** Check the displayed level's filter context and whether any \`(Blank)\` subtree or report-level worker filter has been excluded. Do not change DAX self-exclusion logic, as that is deliberately absent from this function.

## Step 5 of 5 — Capture acceptance evidence

In issue [#15](https://github.com/GitKlink/dax-m-query-library/issues/15) or its draft PR, record:

\`\`\`text
Power BI Desktop / Power Query version:
Runtime query compilation: PASS / FAIL
Synthetic example (7 rows): PASS / FAIL
Automated suite (20 checks): PASS / FAIL
Unexpected checks/errors:
Matrix CEO strict descendants: 600 / actual:
Matrix Group Executive strict descendants: 500 / actual:
Matrix General Manager strict descendants: 300 / actual:
Ragged (Blank) branches observed: YES / NO
Same-name manager stress test: PASS / FAIL / NOT TESTED
Refresh performance at representative row count:
Decision on native Matrix presentation: ACCEPT / REWORK
Evidence: screenshot / sanitized query results
\`\`\`

**DONE when:** The function compiles in a real M runtime, all 20 checks pass, visual behaviour and totals are explicitly reviewed, the PR code/spec is accepted, and the implementation is promoted to the canonical \`library/m/functions/table/\` location. Until then it remains an experiment, not a published function.

## Additional production acceptance cases

The automated synthetic suite is deliberately small. Before promoting, verify:
- Two workers sharing a display name still have separate worker keys.
- Two managers sharing a display name are not accidentally merged by Power BI text-grouping; use stable-key labels or a manager-node dimension when necessary.
- Manager ID and employee ID types are aligned at source (leading-zero preservation).
- Contractor managers (if present) remain valid structural nodes.
- Input extraction scoped to part of an organisation does not remove required parent records.
- Realistic deep and wide trees do not introduce unacceptable refresh times.
- Relevant Fabric Dataflow engine behaviour matches Desktop before using this centrally.
