// Synthetic worked example for the VERIFIED BIccountant function
// with ONLY its ReverseOrderName display step changed.
// Name the original function query "Query1" to match the screenshot.
// All names and IDs are fictional.

let
    Workers = #table(
        type table [
            UserID = Int64.Type,
            MgrUserID = nullable number,
            Name = text,
            WorkerType = text,
            CostIndex = Int64.Type
        ],
        {
            {1000, null, "CEO",             "Employee",   100},
            {1001, 1000, "Group Executive", "Employee",   100},
            {1002, 1001, "General Manager", "Employee",   100},
            {1003, 1002, "Employee A",      "Employee",   100},
            {1004, 1002, "Employee B",      "Employee",   100},
            {1005, 1000, "Employee C",      "Employee",   100},
            {1006, 1000, "Employee D",      "Employee",   100},
            {1007, 1000, "Employee E",      "Employee",   100},
            {1008, 1002, "Contractor F",    "Contractor", 100}
        }
    ),
    Result = Query1(Workers, "UserID", "MgrUserID", "Name")
in
    Result
