# ADR 001 — Preserve the BIccountant hierarchy engine

**Status:** Proposed, pending runtime acceptance  
**Issue:** [#15](https://github.com/GitKlink/dax-m-query-library/issues/15)

## Context

The user already relies on Imke Feldmann's [ParentChildAllParents.pq](https://gist.github.com/ImkeF/3a6b50e705bfbdbcb3480b6be505322a) in Power Query. The original supports multiple parents, unknown-parent handling and endless-loop detection. A freshly written replacement attempted to provide a self-excluding display hierarchy but introduced a false \`UnknownParent\` error for repeated manager references. The original had a distinct-parent check already.

## Decision

- Keep the original hierarchy engine and original API unchanged.
- Change only its \`ReverseOrderName\` step: reverse the assembled root-to-worker display-name path and remove the final self-name.
- Reuse the existing \`IsLeaf\` boolean to distinguish managers (\`false\`) from non-manager workers (\`true\`).
- Do not change ID \`Path\`, source grain, missing-parent behaviour, multiple-parent behaviour, loop detection or the original \`HierarchyDepth\` semantics.
- Provide a self-contained, independently authored replacement step rather than rehosting the whole original function (no explicit source license on gist).

## Rationale

One well-defined formatting change has a far smaller regression surface than a rewrite of validated recursive logic. It retains upstream bug fixes and exactly matches the stakeholder's goal: managers-only display levels and no worker self-contribution via those levels.

## Consequences

- A root worker has no displayed ancestor level; this is intentional.
- Self-inclusion in \`Path\` and RLS logic is unchanged; RLS must remain independently tested.
- Native Matrix ragged blank levels and same-name manager issues are not solved by this small modification.
- Multiple-parent worker rows may be repeated due to the unchanged original function. Original behaviour must be accounted for by the semantic model.
- Third-party source stays outside this repository; document how to apply and test the one-step patch locally.
- The prior experimental custom function is removed from the feature diff, not maintained as another implementation.

## Revisit if

The business specifically needs ID-based manager-level columns, flat one-row-per-worker output under multi-parent arrangements, conditional employee-only manager classification, or independent access-control entitlements. Those are separate features, not justification to rewrite the original engine for the present requirement.
