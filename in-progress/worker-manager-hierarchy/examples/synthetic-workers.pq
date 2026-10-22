// Synthetic example for Table.FlattenManagerHierarchy.
// Prerequisite: create a Power Query function query named exactly
// "Table.FlattenManagerHierarchy" from ../implementation/Table.FlattenManagerHierarchy.pq.

let
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
    Result = #"Table.FlattenManagerHierarchy"(
        Workers,
        "EmployeeID",
        "ManagerID",
        "EmployeeName"
    )
in
    Result
