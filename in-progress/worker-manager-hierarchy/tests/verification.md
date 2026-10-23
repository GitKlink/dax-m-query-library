# Runtime verification — minimal BIccountant shift patch

**State:** Script/test files committed; **not yet executed in Power Query**.

## 🧭 What will be checked

1. The original BIccountant/ImkeF function still runs without any rewrite.
2. A repeated numeric manager ID does not trigger \`UnknownParent\`.
3. Each worker's own name is absent from display hierarchy levels, while parent levels and original \`Path\` remain.
4. \`IsLeaf\` continues to classify structural manager nodes.
5. Power BI Matrix totals, ragged blanks and RLS are explicitly reviewed.

## Step 1 of 4 — Patch your existing verified function

**Where:** Power BI Desktop → **Home → Transform data** → Power Query Editor → select the existing hierarchy function query (shown as \`Query1\` in the user screenshot) → **Advanced Editor**.

1. Duplicate/back up the working function query before editing.
2. Locate the existing \`ReverseOrderName\` step.
3. Replace **only that step** using [patches/ReverseOrderName.pq](../patches/ReverseOrderName.pq), leaving the trailing comma.
4. Do not alter \`ReverseOrderPath\`, \`Path\`, \`IsLeaf\`, parent joins or the function's four parameters.

**Check:** the function displays without a syntax error.

**If different:** Restore the original function and compare the exact replacement boundaries; do not change unrelated traversal steps.

**STOP:** Do not run the test suite before the function loads.

## Step 2 of 4 — Run the synthetic repeated-parent regression

**Where:** Power Query Editor → **New Source → Blank Query** → **Advanced Editor**.

1. Name the test query \`Test.ShiftedAncestorHierarchy\`.
2. Paste [Test.ShiftedAncestorHierarchy.pq](Test.ShiftedAncestorHierarchy.pq).
3. Ensure its call to \`Query1\` names the existing patched BIccountant function (change \`Query1\` only if the function query has a different name).

**Expected:** Exactly **10 test rows**, every \`Pass = true\`. Source values include numeric IDs, a manager with four direct reports and a contractor; all are fictional.

**If different:** Record \`Check\`, \`Expected\` and exact Power Query error. If \`UnknownParent\` appears, verify the test really invokes the unchanged BIccountant function and has retained its original \`MissingParents\` step, which applies \`List.Distinct\` before \`List.Difference\`.

**STOP:** Do not change a security model or production report until all 10 checks pass.

## Step 3 of 4 — Inspect hierarchy visual

**Where:** Power BI Desktop → Close & Apply → Matrix visual using the synthetic worker query ([example file](../examples/synthetic-workers.pq)).

1. Use \`Level 1\`, \`Level 2\`, etc. for **Rows**; do not add \`FirstName\` as a leaf level.
2. Add a normal SUM measure of \`CostIndex\` for **Values**.
3. Verify the displayed managerial groups and direct report inclusion.
4. Inspect ragged \`(Blank)\` branches and subtotal behaviour without filtering away the underlying non-manager rows.

**Expected:** The CEO is not part of their own Level 1 node. Group Executive is in the CEO node but not their own Level 2 node. General Manager is under Group Executive but not their own node. Non-managers remain included in ancestor totals.

**If different:** Inspect the output Level 1/2/3 columns first. Note that root worker rows with no ancestor are outside the hierarchy level filters, but still present in the table. Keep this distinction when comparing enterprise totals.

## Step 4 of 4 — Review existing RLS

**Where:** Power BI Desktop → model security role definition / View as Role.

1. Confirm manager RLS still grants strict descendants, not self.
2. Check a Business Partner aligned to that manager receives the same entitlement population.
3. Verify access is based on worker identity and secure relationships, not assumed from the visual-level shift.

**Expected:** No access change versus approved security rules. **Important:** the BIccountant \`Path\` column is still self-inclusive; if RLS uses \`Path\`, self exclusion must still be enforced there.

**If different:** Revert this change in the test query and review RLS propagation before production release.

## 🧪 Report back / definition of done

Post to [issue #15](https://github.com/GitKlink/dax-m-query-library/issues/15):

\`\`\`text
BIccountant original function query name:
Single-step patch compile: PASS / FAIL
Synthetic test: 10/10 PASS / FAIL
UnknownParent regression: PASS / FAIL
Native Matrix manager self-exclusion: PASS / FAIL
Matrix (Blank) branches observed: YES / NO
Manager + BP RLS unchanged: PASS / FAIL
Exact errors/screenshots (synthetic only):
Power BI / Power Query version:
\`\`\`

**DONE:** 10/10 true; visual and RLS behaviour reviewed; issue evidence posted; PR reviewed. No unlicensed third-party source copied into this public repository.
