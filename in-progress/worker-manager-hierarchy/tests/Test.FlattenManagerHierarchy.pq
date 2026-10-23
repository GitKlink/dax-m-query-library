// Executable synthetic acceptance checks for Table.FlattenManagerHierarchy.
// Query name suggestion: Test.FlattenManagerHierarchy
// Requires the function query "Table.FlattenManagerHierarchy".
// Returns Check / Pass / Expected. No sensitive workforce data.

let
    Fn = #"Table.FlattenManagerHierarchy",
    Workers = #table(
        type table [
            EmployeeID = text,
            ManagerID = nullable text,
            EmployeeName = text,
            WorkerType = text,
            CostIndex = Int64.Type
        ],
        {
            {"001", null,  "CEO",             "Employee",   100},
            {"002", "001", "Group Executive", "Employee",   100},
            {"003", "002", "General Manager", "Employee",   100},
            {"004", "003", "Employee A",      "Employee",   100},
            {"005", "003", "Employee B",      "Employee",   100},
            {"006", "002", "Employee C",      "Employee",   100},
            {"007", "003", "Contractor D",    "Contractor", 100}
        }
    ),
    Flattened = Table.Buffer(Fn(Workers, "EmployeeID", "ManagerID", "EmployeeName")),
    AtID = (id as text) as record =>
        Table.SelectRows(Flattened, each [EmployeeID] = id){0},
    CEO = AtID("001"),
    GE = AtID("002"),
    GM = AtID("003"),
    A = AtID("004"),

    ManagerLevelKeyColumns = {
        "Manager Level 1 Key",
        "Manager Level 2 Key",
        "Manager Level 3 Key"
    },
    ManagerLevelNameColumns = {
        "Manager Level 1",
        "Manager Level 2",
        "Manager Level 3"
    },
    AllRows = Table.ToRecords(Flattened),
    NoSelf = List.AllTrue(
        List.Transform(
            AllRows,
            (row) =>
                not List.Contains(
                    List.RemoveNulls(
                        List.Transform(
                            ManagerLevelKeyColumns,
                            each Record.Field(row, _)
                        )
                    ),
                    row[EmployeeID]
                )
        )
    ),
    VisibleNames = List.RemoveNulls(
        List.Combine(
            List.Transform(
                ManagerLevelNameColumns,
                each Table.Column(Flattened, _)
            )
        )
    ),
    OnlyManagerNames = List.IsEmpty(
        List.Difference(
            List.Distinct(VisibleNames),
            {"CEO", "Group Executive", "General Manager"}
        )
    ),

    // Force calculated columns on invalid inputs inside try to catch errors.
    MustFail = (invalid as table) as logical =>
        let
            result = try List.Sum(
                Table.Column(
                    Fn(invalid, "EmployeeID", "ManagerID", "EmployeeName"),
                    "ManagerHierarchyDepth"
                )
            )
        in
            result[HasError],

    BadDuplicate = #table(
        {"EmployeeID", "ManagerID", "EmployeeName"},
        {{"001", null, "CEO"}, {"002", "001", "GE"}, {"002", "001", "GE"}}
    ),
    BadOrphan = #table(
        {"EmployeeID", "ManagerID", "EmployeeName"},
        {{"001", null, "CEO"}, {"002", "999", "GE"}}
    ),
    BadCycle = #table(
        {"EmployeeID", "ManagerID", "EmployeeName"},
        {{"001", "002", "CEO"}, {"002", "001", "GE"}}
    ),
    BadBlankKey = #table(
        {"EmployeeID", "ManagerID", "EmployeeName"},
        {{"", null, "CEO"}, {"002", "", "GE"}}
    ),
    BadDelimiter = #table(
        {"EmployeeID", "ManagerID", "EmployeeName"},
        {{"00|1", null, "CEO"}}
    ),

    // Regression: the worker IDs may be numeric and the same manager can
    // be referenced by many workers. This must not trigger UnknownParent.
    NumericWorkers = #table(
        type table [UserID = Int64.Type, MgrUserID = nullable number, Name = text],
        {
            {1000, null, "Root"},
            {1001, 1000, "Manager A"},
            {1002, 1000, "Manager B"},
            {1003, 1000, "Employee C"},
            {1004, 1000, "Employee D"},
            {1005, 1000, "Employee E"}
        }
    ),
    NumericResult = Table.Buffer(
        Fn(NumericWorkers, "UserID", "MgrUserID", "Name")
    ),
    NumericChildren = Table.ToRecords(
        Table.SelectRows(NumericResult, each [UserID] <> 1000)
    ),
    NumericRoot = Table.SelectRows(NumericResult, each [UserID] = 1000){0},

    Checks = {
        [Check = "Numeric keys: repeated manager reference does not trigger UnknownParent", Pass = Table.RowCount(NumericResult) = 6 and NumericRoot[DirectReportCount] = 5, Expected = "6 rows, root has 5 reports"],
        [Check = "Numeric keys: all child ancestor IDs are the same manager", Pass = List.AllTrue(List.Transform(NumericChildren, each Record.Field(_, "Manager Level 1 Key") = "1000")), Expected = "All child level 1 keys are text 1000"],
        [Check = "Source row grain preserved", Pass = Table.RowCount(Flattened) = 7, Expected = "7 rows"],
        [Check = "Original numeric values preserved", Pass = List.Sum(Flattened[CostIndex]) = 700, Expected = "700"],
        [Check = "CEO's own row has no manager node", Pass = CEO[ManagerHierarchyDepth] = 0 and CEO[HasManagerNode] = false, Expected = "0 / false"],
        [Check = "Group Executive reports to CEO only", Pass = Record.Field(GE, "Manager Level 1 Key") = "001" and Record.Field(GE, "Manager Level 2 Key") = null, Expected = "001 / null"],
        [Check = "General Manager reports via Group Executive", Pass = Record.Field(GM, "Manager Level 2 Key") = "002", Expected = "002"],
        [Check = "Employee has all three manager ancestors", Pass = Record.Field(A, "Manager Level 3 Key") = "003" and A[ManagerPathIDs] = "001|002|003", Expected = "003 / 001|002|003"],
        [Check = "No worker appears in their own manager path", Pass = NoSelf, Expected = "true"],
        [Check = "Only managers appear as hierarchy level names", Pass = OnlyManagerNames, Expected = "true"],
        [Check = "CEO reporting total excludes CEO", Pass = List.Sum(Table.SelectRows(Flattened, each Record.Field(_, "Manager Level 1 Key") = "001")[CostIndex]) = 600, Expected = "600"],
        [Check = "Group Executive reporting total excludes Group Executive", Pass = List.Sum(Table.SelectRows(Flattened, each Record.Field(_, "Manager Level 2 Key") = "002")[CostIndex]) = 500, Expected = "500"],
        [Check = "General Manager reporting total excludes General Manager", Pass = List.Sum(Table.SelectRows(Flattened, each Record.Field(_, "Manager Level 3 Key") = "003")[CostIndex]) = 300, Expected = "300"],
        [Check = "Group Executive direct reports", Pass = GE[DirectReportCount] = 2, Expected = "2"],
        [Check = "Contractor is retained in counts", Pass = GM[DirectReportCount] = 3, Expected = "3"],
        [Check = "Manager of managers metadata", Pass = CEO[HasManagerReports] and GE[HasManagerReports] and not GM[HasManagerReports], Expected = "CEO / GE true, GM false"],
        [Check = "Leaf classification", Pass = A[IsLeaf] and not A[IsManager] and GM[IsManager], Expected = "true"],
        [Check = "Duplicate worker keys fail", Pass = MustFail(BadDuplicate), Expected = "true"],
        [Check = "Unknown manager key fails", Pass = MustFail(BadOrphan), Expected = "true"],
        [Check = "Cycle fails", Pass = MustFail(BadCycle), Expected = "true"],
        [Check = "Blank worker key fails", Pass = MustFail(BadBlankKey), Expected = "true"],
        [Check = "Pipe in worker ID fails", Pass = MustFail(BadDelimiter), Expected = "true"]
    },
    Results = Table.FromRecords(Checks)
in
    Results
