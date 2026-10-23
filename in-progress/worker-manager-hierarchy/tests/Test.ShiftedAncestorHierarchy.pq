// Run in Power Query after applying the single ReverseOrderName change
// to BIccountant's original ParentChildAllParents function named Query1.
// Source of original: https://gist.github.com/ImkeF/3a6b50e705bfbdbcb3480b6be505322a
// This test is not runtime-verified in the repository.

let
    Workers = #table(
        type table [
            UserID = Int64.Type, MgrUserID = nullable number,
            Name = text, WorkerType = text, CostIndex = Int64.Type
        ],
        {
            {1000, null, "CEO", "Employee", 100},
            {1001, 1000, "Group Executive", "Employee", 100},
            {1002, 1001, "General Manager", "Employee", 100},
            {1003, 1002, "Employee A", "Employee", 100},
            {1004, 1002, "Employee B", "Employee", 100},
            {1005, 1000, "Employee C", "Employee", 100},
            {1006, 1000, "Employee D", "Employee", 100},
            {1007, 1000, "Employee E", "Employee", 100},
            {1008, 1002, "Contractor F", "Contractor", 100}
        }
    ),

    // Uses the exact existing user function with ONE display calculation modified.
    Flat = Table.Buffer(Query1(Workers, "UserID", "MgrUserID", "Name")),
    AtID = (id as text) as record =>
        Table.SelectRows(Flat, each [NodeKey] = id){0},
    Root = AtID("1000"),
    GE = AtID("1001"),
    GM = AtID("1002"),
    EmployeeA = AtID("1003"),
    EmployeeC = AtID("1005"),

    LevelValue = (r as record, n as number) as any =>
        Record.FieldOrDefault(r, "Level " & Text.From(n), null),

    LevelColumns = List.Select(
        Table.ColumnNames(Flat),
        each Text.StartsWith(_, "Level ")
            and (try Number.FromText(Text.AfterDelimiter(_, "Level ")) otherwise null) <> null
    ),

    VisibleLabels = List.RemoveNulls(
        List.Combine(List.Transform(LevelColumns, each Table.Column(Flat, _)))
    ),
    WorkerNames = {"Employee A", "Employee B", "Employee C", "Employee D", "Employee E", "Contractor F"},

    TestRows = {
        [Check = "Shared root manager: numeric IDs and repeated parent are accepted", Pass = Table.RowCount(Flat) = 9, Expected = "9 rows and no UnknownParent error"],
        [Check = "Root has no ancestor level", Pass = List.Contains({null, ""}, LevelValue(Root, 1)), Expected = "Root Level 1 null or empty"],
        [Check = "Executive is visible under CEO, not self", Pass = LevelValue(GE, 1) = "CEO" and List.Contains({null, ""}, LevelValue(GE, 2)), Expected = "CEO > blank"],
        [Check = "GM is visible under CEO and Group Executive, not self", Pass = LevelValue(GM, 1) = "CEO" and LevelValue(GM, 2) = "Group Executive" and List.Contains({null, ""}, LevelValue(GM, 3)), Expected = "CEO > GE > blank"],
        [Check = "Employee path includes only managers", Pass = LevelValue(EmployeeA, 1) = "CEO" and LevelValue(EmployeeA, 2) = "Group Executive" and LevelValue(EmployeeA, 3) = "General Manager" and List.Contains({null, ""}, LevelValue(EmployeeA, 4)), Expected = "CEO > GE > GM > blank"],
        [Check = "CEO direct worker is not shown as a hierarchy node", Pass = LevelValue(EmployeeC, 1) = "CEO" and List.Contains({null, ""}, LevelValue(EmployeeC, 2)), Expected = "CEO > blank"],
        [Check = "No non-manager display labels", Pass = List.IsEmpty(List.Intersect({VisibleLabels, WorkerNames})), Expected = "All visible labels are manager names"],
        [Check = "Existing IsLeaf identifies managers", Pass = Root[IsLeaf] = false and GE[IsLeaf] = false and GM[IsLeaf] = false and EmployeeA[IsLeaf] = true, Expected = "CEO/GE/GM false, A true"],
        [Check = "Existing ID path still includes the worker", Pass = Text.EndsWith(EmployeeA[Path], "1003"), Expected = "Path ends with 1003 (unchanged original semantics)"],
        [Check = "HierarchyDepth is unchanged inclusive depth", Pass = EmployeeA[HierarchyDepth] > GM[HierarchyDepth], Expected = "A deeper than GM"]
    },

    Result = Table.FromRecords(TestRows)
in
    Result
