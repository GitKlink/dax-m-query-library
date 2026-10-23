# Manager-only shifted ancestor hierarchy — minimal BIccountant patch

**Stage:** Draft patch under feature issue [#15](https://github.com/GitKlink/dax-m-query-library/issues/15) and [PR #16](https://github.com/GitKlink/dax-m-query-library/pull/16). **Power Query runtime test pending.**

## 🎯 What this solves

A worker/manager reporting hierarchy is flattened into manager labels only. A worker is included under every **strict ancestor** (direct or indirect manager), not under a hierarchy node named for themselves.

\`\`\`text
Actual reporting tree           Manager display levels on each worker row

CEO                             CEO              -> (none)
└─ Group Executive              Group Executive  -> CEO
   └─ General Manager           General Manager  -> CEO > Group Executive
      ├─ Employee A             Employee A       -> CEO > Group Executive > General Manager
      └─ Employee B             Employee B       -> CEO > Group Executive > General Manager
\`\`\`

All workers remain as rows; \`Employee A\` and \`Employee B\` are included in their managers' reporting totals but do not become hierarchy labels.

## 🛠️ Minimal-change principle

**Use the existing, proven original**: [Imke Feldmann / BIccountant — ParentChildAllParents.pq](https://gist.github.com/ImkeF/3a6b50e705bfbdbcb3480b6be505322a).

The only intended modification is replacing its **\`ReverseOrderName\`** step with [patches/ReverseOrderName.pq](patches/ReverseOrderName.pq). This removes the final self-name element from the already-resolved root-first name path. **Do not replace the original algorithm with a rewritten implementation.**

| Component | Behaviour |
| --- | --- |
| Parent-child recursion | Original unchanged |
| Multiple-parent support | Original unchanged |
| Missing-parent handling | Original unchanged |
| Loop detection | Original unchanged |
| Key \`Path\` output | Original unchanged — still includes self |
| \`FirstName\`, \`NodeKey\`, \`FirstParentKey\` | Original unchanged |
| \`HierarchyDepth\` | Original unchanged — inclusive semantics |
| \`IsLeaf\` | Original unchanged — \`false\` identifies structural manager |
| Level 1…N display names | **Only change** — exclude worker's own name |
| Input source and other columns | Original unchanged |

**No \`IsManager\` filter** is applied to the worker rows. That would remove non-managers and change the totals. A separate boolean \`IsManager = not [IsLeaf]\` can be added downstream **only if necessary**; the original function already contains the equivalent information.

## 📦 Files

| File | Role |
| --- | --- |
| [patches/ReverseOrderName.pq](patches/ReverseOrderName.pq) | Single-step replacement to paste into the existing BIccountant function |
| [examples/synthetic-workers.pq](examples/synthetic-workers.pq) | Safe numeric-ID and repeated-manager example |
| [tests/Test.ShiftedAncestorHierarchy.pq](tests/Test.ShiftedAncestorHierarchy.pq) | 10 behavioural acceptance checks against the patched original |
| [tests/verification.md](tests/verification.md) | Power Query setup and expected outcomes |
| [spec.md](spec.md) | Behavioural contract and limitations |
| [adr/001-preserve-biccountant-engine.md](adr/001-preserve-biccountant-engine.md) | Design decision to preserve the BIccountant engine, not reinvent |

**Source licensing:** the linked gist does not include an explicit reuse license. This repository stores **only the original independently authored replacement step** and synthetic tests, not a redistributed copy of the entire third-party function. The owner must maintain the original function locally in the Power Query project; licence/permission review is needed before distributing a complete modified upstream function as an MIT-licensed library asset.

## ▶️ Apply the change

**Where:** In Power BI Desktop → **Transform data** → existing BIccountant function query (the working example called it \`Query1\`) → **Advanced Editor**.

1. Find the existing step beginning \`ReverseOrderName =\`.
2. Replace **that step only** with the full expression in [patches/ReverseOrderName.pq](patches/ReverseOrderName.pq) (do not paste the file's comments over unrelated steps).
3. Keep the next step, \`ReverseOrderPath\`, unchanged.
4. Save and refresh using a copy of the query before applying it to production.

**Expected:** Manager labels remain in ancestor levels, but each row's self-name disappears from its deepest level; root worker has no display ancestor.

**If different:** Preserve the original query copy, capture the Power Query error and compare exactly which step was replaced. See [tests/verification.md](tests/verification.md).

## 🔎 Inputs and outputs

The original function call and source naming remain unchanged:

\`\`\`powerquery
Query1(#"Reordered columns", "UserID", "MgrUserID", "Name")
\`\`\`

| Original output | Expected meaning after patch |
| --- | --- |
| \`NodeKey\` | The worker's ID (not an ancestor) |
| \`FirstName\` | The worker's name (retained for other uses) |
| \`FirstParentKey\` | Immediate manager key |
| \`Path\` | Original ID path including the worker, **not** a strict-ancestor/RLS path |
| \`HierarchyDepth\` | Original recursion depth (inclusive) |
| \`IsLeaf\` | Boolean from original; \`false\` = structural manager |
| \`Level 1\`, \`Level 2\`, ... | **Display-only strict ancestors**, root-first; trailing levels blank |

Use manager-only \`Level 1\`…\`Level N\` to construct the visual hierarchy, without placing \`FirstName\` or the worker name field at the bottom.

## ⚠️ Consequences and limits

1. **Ragged matrix:** Power BI native Matrix can still show \`(Blank)\`/empty branches when rows have different ancestor depths. Suppressing blanks with a worker-row filter can silently exclude direct reports from sums. This patch does **not** solve that presentation problem.
2. **Security:** \`Path\` remains the original *inclusive* ID path. If used for RLS, it can grant self-access unless the RLS rule independently excludes self. Existing RLS needs independent validation. This display-only modification must not be treated as an access-control change.
3. **Duplicate display names:** distinct managers with the same name can collapse in a name-only visual; use keyed/disambiguated labels when necessary.
4. **Multiple parents:** the source function supports multiple parent paths; workers can appear on more than one path. Do not sum repeated worker rows into an enterprise total without modelling the grain. This patch does not alter that existing behaviour.
5. **Roots / unknown parents / loops:** governed by the upstream BIccountant function, not reimplemented here. Its existing synthetic unknown-root conventions remain.
6. **Workers and contractors:** neither is filtered. Any employee-only span/headcount policy belongs in a separate business transformation.
7. **Function name:** \`Query1\` is the existing Power Query query name in the screenshot; your query may have a different name. No rename is needed to apply the one-step patch.

## 🧪 Verification status

The replacement expression and [10-case synthetic test suite](tests/Test.ShiftedAncestorHierarchy.pq) are committed. They have **not yet been run in Power Query Desktop**. Do not describe the patch as verified until the tests pass and the Matrix presentation is reviewed.

**Done when:** all 10 test rows return \`Pass = true\`, no \`UnknownParent\` for repeated managers, the native Matrix totals meet the agreed behaviour, and PR #16 has been reviewed. The current PR is **draft**, not merged.
