# ADR 001 — Preserve one worker row: strict single-parent manager ancestry

**Status:** Proposed (feature-local; awaits owner/runtime review)  
**Issue:** [#15](https://github.com/GitKlink/dax-m-query-library/issues/15)

## Context

The requested Power BI hierarchy describes an employee's **strict manager ancestors**, never the employee as a visible node. Report users still need the complete employee/fact population so ordinary additive metrics and existing conformed employee relationships work without a self-excluding DAX measure.

The linked Imke Feldmann [ParentChildAllParents gist](https://gist.github.com/ImkeF/3a6b50e705bfbdbcb3480b6be505322a) supports multiple parents. That is useful for a general network, but the business case is a worker-to-one-manager reporting tree and the existing report uses a worker-grain dimension.

## Decision

1. Implement a **new** source-agnostic \`Table.FlattenManagerHierarchy\` rather than modify/copy the existing gist.
2. Require exactly one input row per worker ID and zero or one immediate manager. Reject duplicate IDs and unknown managers rather than generating multiple ancestry rows or inventing roots.
3. Keep worker-level row cardinality unchanged and add root-first, **ancestor-only** display-name and stable-ID level columns.
4. Include structural manager metadata but **do not filter out non-managers** during the transformation.
5. Fail early on cycles, missing ID/name, invalid delimiters and output collisions.
6. Keep implementation under \`in-progress/\` until Power Query runtime and Matrix verification; then publish into \`library/m/functions/table/\`.

## Why

A many-parent flattened ancestry can generate multiple worker rows. Joining repeated worker records to normal fact tables can multiply compensation/headcount amounts. A strict one-parent contract gives predictable row grain, explicit error handling and ordinary filtering of workers into ancestor organisations.

Alternative considered: build an ancestor/descendant bridge (one row per worker ancestor). This supports multi-parent and arbitrary paths but requires relationship/grain management and distinct aggregation semantics. It is outside the original requirement to produce ordinary, level-based Power BI hierarchies with no DAX self-exclusion.

Alternative considered: move every visible name up a level in the existing function without a new contract. That would inherit multiple-parent row multiplication and a source-licensing question, and does not provide an explicit quality gate.

## Consequences / limitations

- A manager's own worker record belongs under their parent manager, not themselves.
- Non-manager workers remain in the employee table and contribute to their manager's totals; restricting \`IsManager = true\` at worker level is an anti-pattern.
- \`(Blank)\` descendants and visually non-reconciling child manager rows remain possible in native Matrix visuals. This is a **presentation limitation**, not a failure of strict-ancestor semantics. Do not hide data to make the matrix superficially tidy.
- Root rows have no manager levels; a visual filter using \`HasManagerNode = true\` excludes roots from that visual's total as well.
- Same-name managers need stable-key presentation/disambiguation in the semantic model.
- Contractor management semantics and employee-only direct counts must be handled via explicit population logic outside this generic function.
- Multiple-manager relationships require another explicit model design (probably a bridge), not silently reusing this function.

## Attribution / reuse

This is independently authored M code, conceptually informed by the linked public gist; no portion of the gist code is imported. The gist does not provide an explicit source license on its page. Repository MIT licensing covers this new implementation only.

## Revisit if

The data must represent matrix/dotted-line managers, orphan employee snapshots, graph-like cyclic relationships, employee-only structural counts, or a Matrix with no blank display nodes at any depth.
