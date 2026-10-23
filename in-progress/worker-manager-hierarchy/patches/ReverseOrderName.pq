// Minimal replacement for the existing ReverseOrderName step in
// Imke Feldmann's BIccountant ParentChildAllParents.pq.
// Source: https://gist.github.com/ImkeF/3a6b50e705bfbdbcb3480b6be505322a
//
// The upstream traversal, joins, loop detection, Path, depth, IsLeaf,
// multiple-parent behavior and subsequent steps are unchanged.
//
// Paste this expression into the existing function, replacing ONLY the
// ReverseOrderName step. Retain its trailing comma because the next step
// (ReverseOrderPath) follows it.

ReverseOrderName = Table.TransformColumns(
    #"Trimmed Text",
    {
        {
            "Name",
            each
                let
                    StrictAncestors = List.RemoveLastN(
                        List.Reverse(Text.Split(_, "|")),
                        1
                    )
                in
                    if List.IsEmpty(StrictAncestors) then
                        null
                    else
                        Text.Combine(StrictAncestors, "|"),
            type nullable text
        }
    }
),
