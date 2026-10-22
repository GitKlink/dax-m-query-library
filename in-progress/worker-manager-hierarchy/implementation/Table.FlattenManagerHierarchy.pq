// Table.FlattenManagerHierarchy.pq
// Experimental feature implementation. Not yet Power Query runtime verified.
// Original implementation; inspired by, but not copied from:
// https://gist.github.com/ImkeF/3a6b50e705bfbdbcb3480b6be505322a
//
// Contract:
// - One input row per unique worker, with zero or one manager.
// - Retain every input row and original column.
// - Add root-first manager ancestry levels; NEVER include the worker as a level.
// - Add manager metadata; DO NOT filter worker rows using IsManager.
// - Missing parents, duplicate IDs, cycles, empty IDs/names and column collisions fail fast.
// - DirectReportCount counts every input row regardless of worker classification.
// - Use textual worker/manager IDs to preserve leading zeros.

let
    Table.FlattenManagerHierarchy =
        (
            Source as table,
            ChildKey as text,
            ParentKey as text,
            DisplayName as text
        ) as table =>
        let
            RequiredColumns = {ChildKey, ParentKey, DisplayName},
            ExistingColumns = Table.ColumnNames(Source),
            MissingColumns = List.Difference(RequiredColumns, ExistingColumns),

            MetaColumns = {
                "IsManager", "IsLeaf", "DirectReportCount", "HasManagerReports",
                "ManagerHierarchyDepth", "HasManagerNode", "ManagerPathIDs"
            },

            Collisions = List.Select(
                ExistingColumns,
                (column) =>
                    List.Contains(MetaColumns & {"__ManagerHierarchy"}, column)
                    or Text.StartsWith(column, "Manager Level ")
            ),

            CheckedSource =
                if List.Count(List.Distinct(RequiredColumns)) <> 3 then
                    error Error.Record(
                        "InvalidColumns",
                        "ChildKey, ParentKey and DisplayName must be different columns.",
                        [Columns = RequiredColumns]
                    )
                else if not List.IsEmpty(MissingColumns) then
                    error Error.Record(
                        "MissingColumns",
                        "A required input column is missing.",
                        [Columns = MissingColumns]
                    )
                else if not List.IsEmpty(Collisions) then
                    error Error.Record(
                        "OutputColumnCollision",
                        "Rename existing hierarchy output columns before calling the function.",
                        [Columns = Collisions]
                    )
                else
                    Table.Buffer(Source),

            NormalizeKey = (value as any) as nullable text =>
                if value = null then
                    null
                else
                    let
                        normalized = Text.Trim(Text.From(value))
                    in
                        if normalized = "" then null else normalized,

            SourceRows = Table.ToRecords(
                Table.SelectColumns(CheckedSource, RequiredColumns)
            ),

            Nodes = List.Buffer(
                List.Transform(
                    SourceRows,
                    (row) => [
                        Key = NormalizeKey(Record.Field(row, ChildKey)),
                        Parent = NormalizeKey(Record.Field(row, ParentKey)),
                        Name =
                            let
                                value = Record.Field(row, DisplayName)
                            in
                                if value = null then null else Text.From(value)
                    ]
                )
            ),

            NodeIDs = List.Transform(Nodes, each [Key]),
            ParentIDs = List.RemoveNulls(List.Transform(Nodes, each [Parent])),
            BlankIDs = List.Contains(NodeIDs, null),
            BlankNames = List.AnyTrue(
                List.Transform(
                    Nodes,
                    each [Name] = null or Text.Trim([Name]) = ""
                )
            ),
            DuplicateIDs = List.Count(NodeIDs) <> List.Count(List.Distinct(NodeIDs)),
            PipeIDs = List.AnyTrue(
                List.Transform(
                    NodeIDs,
                    each if _ = null then false else Text.Contains(_, "|")
                )
            ),
            UnknownParents = List.Difference(ParentIDs, NodeIDs),

            ValidatedNodes =
                if BlankIDs then
                    error Error.Record("BlankWorkerID", "Every worker must have a nonblank key.", [])
                else if DuplicateIDs then
                    error Error.Record(
                        "DuplicateWorkerID",
                        "A single-parent hierarchy requires exactly one row per unique worker key.",
                        []
                    )
                else if BlankNames then
                    error Error.Record(
                        "BlankDisplayName",
                        "Every worker must have a nonblank display name.",
                        []
                    )
                else if PipeIDs then
                    error Error.Record(
                        "InvalidWorkerID",
                        "Worker keys cannot contain | because ManagerPathIDs uses it as a separator.",
                        []
                    )
                else if not List.IsEmpty(UnknownParents) then
                    error Error.Record(
                        "UnknownParent",
                        "Some manager keys have no matching worker row.",
                        [ManagerKeys = List.Distinct(UnknownParents)]
                    )
                else
                    Nodes,

            Keys = List.Transform(ValidatedNodes, each [Key]),
            NodeLookup = Record.FromList(ValidatedNodes, Keys),

            // Direct relationships are measured from the supplied source rows,
            // not from expanded ancestry; there is no multiplied row grain.
            ParentTable = Table.FromColumns({ParentIDs}, {"ManagerID"}),
            ParentCounts = Table.Group(
                ParentTable,
                {"ManagerID"},
                {{"Count", each Table.RowCount(_), Int64.Type}}
            ),
            DirectCounts = Record.FromList(ParentCounts[Count], ParentCounts[ManagerID]),

            ManagersWithManagerReports = List.Distinct(
                List.RemoveNulls(
                    List.Transform(
                        List.Select(
                            ValidatedNodes,
                            each [Parent] <> null
                                and Record.HasFields(DirectCounts, [Key])
                        ),
                        each [Parent]
                    )
                )
            ),

            ManagerParentLookup = Record.FromList(
                List.Repeat({true}, List.Count(ManagersWithManagerReports)),
                ManagersWithManagerReports
            ),

            // Walk upwards from the worker; prepend higher ancestors so
            // levels are root-first. Never append the starting worker ID.
            GetAncestorIDs = (workerID as text) as list =>
                let
                    Walk = (currentID as text, visited as list) as list =>
                        let
                            node = Record.Field(NodeLookup, currentID),
                            nextParent = node[Parent]
                        in
                            if nextParent = null then
                                {}
                            else if List.Contains(visited, nextParent) then
                                error Error.Record(
                                    "HierarchyCycle",
                                    "A worker's manager chain contains a cycle.",
                                    [WorkerID = workerID, RepeatedID = nextParent]
                                )
                            else
                                @Walk(nextParent, visited & {nextParent}) & {nextParent}
                in
                    Walk(workerID, {workerID}),

            Paths = List.Buffer(List.Transform(Keys, each GetAncestorIDs(_))),
            PathLookup = Record.FromList(Paths, Keys),
            MaxDepth = List.Max({0} & List.Transform(Paths, each List.Count(_))),
            Positions = if MaxDepth = 0 then {} else List.Numbers(1, MaxDepth),

            LevelColumns = List.Combine(
                List.Transform(
                    Positions,
                    each {
                        "Manager Level " & Text.From(_),
                        "Manager Level " & Text.From(_) & " Key"
                    }
                )
            ),
            OutputColumns = MetaColumns & LevelColumns,

            AddedHierarchy = Table.AddColumn(
                CheckedSource,
                "__ManagerHierarchy",
                (workerRow) =>
                    let
                        workerID = NormalizeKey(Record.Field(workerRow, ChildKey)),
                        ancestorIDs = Record.Field(PathLookup, workerID),
                        depth = List.Count(ancestorIDs),
                        directCount = Record.FieldOrDefault(DirectCounts, workerID, 0),
                        isManager = directCount > 0,
                        levelValues = List.Combine(
                            List.Transform(
                                Positions,
                                (position) =>
                                    if position <= depth then
                                        {
                                            Record.Field(
                                                Record.Field(NodeLookup, ancestorIDs{position - 1}),
                                                "Name"
                                            ),
                                            ancestorIDs{position - 1}
                                        }
                                    else
                                        {null, null}
                            )
                        ),
                        metadataValues = {
                            isManager,
                            not isManager,
                            directCount,
                            Record.HasFields(ManagerParentLookup, workerID),
                            depth,
                            depth > 0,
                            if depth = 0 then null else Text.Combine(ancestorIDs, "|")
                        }
                    in
                        Record.FromList(metadataValues & levelValues, OutputColumns),
                type record
            ),

            Expanded = Table.ExpandRecordColumn(
                AddedHierarchy,
                "__ManagerHierarchy",
                OutputColumns,
                OutputColumns
            ),

            LevelTypes = List.Combine(
                List.Transform(
                    Positions,
                    each {
                        {"Manager Level " & Text.From(_), type nullable text},
                        {"Manager Level " & Text.From(_) & " Key", type nullable text}
                    }
                )
            ),

            Typed = Table.TransformColumnTypes(
                Expanded,
                {
                    {"IsManager", type logical},
                    {"IsLeaf", type logical},
                    {"DirectReportCount", Int64.Type},
                    {"HasManagerReports", type logical},
                    {"ManagerHierarchyDepth", Int64.Type},
                    {"HasManagerNode", type logical},
                    {"ManagerPathIDs", type nullable text}
                } & LevelTypes
            )
        in
            Typed,

    Documentation = [
        Documentation.Name = "Table.FlattenManagerHierarchy",
        Documentation.Description = "Create ancestor-only, manager-level hierarchy columns without dropping workers.",
        Documentation.LongDescription = "Accepts a unique worker ID, immediate manager ID and display name. Returns every worker row with root-first strict-ancestor manager name/key levels and structural manager metadata. Rejects duplicate workers, unknown parents and cycles. This is not a multi-parent flattening function.",
        Documentation.Category = "Table",
        Documentation.Version = "0.1.0-preview",
        Documentation.Source = "GitKlink/dax-m-query-library",
        Documentation.Author = "GitKlink",
        Documentation.Examples = {
            [
                Description = "Create manager-only hierarchy levels for a worker table.",
                Code = "#""Table.FlattenManagerHierarchy""(Workers, ""EmployeeID"", ""ManagerID"", ""EmployeeName"")",
                Result = "All worker rows with Manager Level 1, Manager Level 2, etc."
            ]
        }
    ],

    Documented = Value.ReplaceType(
        Table.FlattenManagerHierarchy,
        Value.ReplaceMetadata(Value.Type(Table.FlattenManagerHierarchy), Documentation)
    )
in
    Documented
