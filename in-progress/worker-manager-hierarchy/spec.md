# Feature specification — minimal strict-ancestor display patch

**Issue:** [#15](https://github.com/GitKlink/dax-m-query-library/issues/15)  
**Status:** Proposed; runtime verification pending.

## 🎯 Objective

Provide manager-only hierarchy level names for an existing BIccountant/Imke Feldmann ParentChildAllParents Power Query implementation while preserving its verified hierarchy engine, outputs and workflow.

**Original:** https://gist.github.com/ImkeF/3a6b50e705bfbdbcb3480b6be505322a

## Scope

Modify only the upstream \`ReverseOrderName\` step:

- Original: reverse an assembled name path, yielding \`root → ... → current worker\`.
- Patch: reverse the path and remove its final element, yielding \`root → ... → parent\`.
- When the path has only the current worker (a root), return \`null\`.
- Let the existing downstream \`ReverseOrderPath\`, column splitting, merges, leaf detection and original loop handling continue as before.

The patched step uses \`List.Reverse\`, \`Text.Split\`, \`List.RemoveLastN\`, and \`Text.Combine\`. It does **not** recalculate a worker's reporting path or expand ancestry differently.

## Existing API — unchanged

\`\`\`powerquery
Query1(ParChTable as table, ChildKey as text, ParentKey as text, LevelColumnName as text)
\`\`\`

\`Query1\` refers to the existing function query name visible in the user's screenshot, not a new API or replacement module. Child/parent IDs may be numeric in the source; upstream converts them to text for paths.

## Output contract

| Field | Change? | Contract |
| --- | --- | --- |
| \`Level 1\`…\`Level N\` | **YES** | Root-first, strict ancestor **name** values only, never the worker's own name |
| \`NodeKey\` | No | Worker identity |
| \`FirstName\` | No | Worker display name |
| \`FirstParentKey\` | No | Immediate reporting parent |
| \`Path\` | No | ID path retains original inclusive self; **not safe to assume strict-ancestor RLS** |
| \`HierarchyDepth\` | No | Original inclusive hierarchy depth |
| \`IsLeaf\` | No | Original boolean leaf indicator; \`false\` = manager |
| Other original fields | No | Original behaviour, including multiple parents and missing-parent conventions |

## Core requirements

1. A manager appears as a worker record under its own superior, but never as a display level on its own record.
2. A non-manager's record retains all manager ancestors, and its own name never appears as a display level.
3. All input rows remain available; do not filter the table using \`IsLeaf\` or \`IsManager\`.
4. Preserve the original function's capacity for multiple parents, missing-parent handling and endless-loop detection by not touching their steps. Any existing row multiplication from multi-parent inputs remains.
5. Users can apply the modification by replacing one M step, with no new function arguments, source conversion, RLS change or model-measure dependency.
6. Do not redistribute the complete third-party source without reviewing licensing/permission; feature repo contains replacement snippet and test harness only.

## Test fixtures and expected values

Use synthetic numeric IDs and repeatedly referenced parent key (CEO has four direct reports) to reproduce the user's \`UnknownParent\` issue and ensure the original, correctly distincted missing-parent check continues to work.

\`\`\`text
worker      Level 1    Level 2            Level 3
CEO         null       null               null
Group Exec  CEO        null               null
GM          CEO        Group Executive    null
Employee A  CEO        Group Executive    General Manager
Employee C  CEO        null               null
\`\`\`

No employee or contractor display names should be present in any non-null \`Level N\`.

## Non-goals / caveats

- No new general-purpose hierarchy algorithm, RLS bridge, manager count logic or replacement for original recursion.
- Native Matrix ragged blanks remain an open **visual presentation** concern.
- No assumption that standard Matrix child branch values sum to manager totals, since direct reports at shorter depth are still included in ancestor total.
- Worker IDs, not display names, must remain the security identity.
- The original \`Path\` field remains self-inclusive: do **not** change RLS based only on new level presentation.

## Acceptance gate

1. Code diff contains only a step replacement **to be applied locally to upstream source** plus test/docs; no copied upstream body.
2. 10 synthetic checks in Power Query return \`Pass = true\`, including multiple numeric workers sharing a manager ID.
3. Real sample shows CEO's own \`Level 1\` blank and Group Executive's \`Level 1\` CEO; existing missing-parent error is absent.
4. Native Matrix view tested, blank drill branches documented, and existing RLS retested.
5. Human approves PR; do not merge/publish as a complete re-licensed function without permission to redistribute upstream code.
