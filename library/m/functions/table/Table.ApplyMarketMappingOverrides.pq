let
    func =
        (
            TargetTable as table,
            RulesTable as table,
            AttributeMap as table,
            OutputMode as text,
            optional OutputColumnName as nullable text
        ) as table =>
        let
            RequiredRuleColumns = {
                "CountryID", "SurveyID", "JobArchitectureLevel", "JobArchitectureName",
                "RuleGroupID", "RuleGroupExecutionOrder", "RuleID", "RuleExecutionOrder",
                "ConditionID", "Field", "Operator", "Value", "ValueType", "ActionType",
                "ActionValue", "ActionFrom", "ActionTo", "StopAfterRuleGroup", "Active"
            },
            RequiredMapColumns = {"CanonicalAttribute", "TargetColumn", "DataType"},
            SupportedOperators = {"EQUALS", "NOTEQUALS", "STARTSWITH", "ENDSWITH", "CONTAINS", "IN", "ISBLANK", "ISNOTBLANK"},
            SupportedActions = {"REPLACEWITH", "REPLACESUFFIX"},
            SupportedArchitectureLevels = {"JOBPROFILE", "ALL"},
            SupportedValueTypes = {"TEXT", "NUMBER", "LOGICAL", "DATE"},
            AuditColumns = {
                "OriginalMarketDataCode", "FinalMarketDataCode", "OverrideApplied",
                "AppliedRuleGroups", "AppliedRuleIDs", "AppliedRuleCount", "RuleConflictDetected"
            },

            Raise = (Message as text, optional Detail as any) as any =>
                error Error.Record("MarketMappingRuleEngine", Message, Detail),

            NormalizeText = (Value as any) as nullable text =>
                if Value = null then null else Text.Trim(Text.From(Value)),

            TextEquals = (Left as any, Right as any) as logical =>
                let
                    L = NormalizeText(Left),
                    R = NormalizeText(Right)
                in
                    if L = null or R = null then L = R else Text.Compare(L, R, Comparer.OrdinalIgnoreCase) = 0,

            IsBlankValue = (Value as any) as logical =>
                Value = null or (Value is text and Text.Trim(Value) = ""),

            ToTypedValue = (Value as any, ValueType as text) as any =>
                let
                    TypeName = Text.Upper(Text.Trim(ValueType))
                in
                    if Value = null then null
                    else if TypeName = "TEXT" then Text.From(Value)
                    else if TypeName = "NUMBER" then Number.From(Value)
                    else if TypeName = "LOGICAL" then Logical.From(Value)
                    else if TypeName = "DATE" then Date.From(Value)
                    else Raise("Unsupported ValueType: " & ValueType),

            CompareEquals = (Left as any, Right as any, ValueType as text) as logical =>
                let
                    TypeName = Text.Upper(Text.Trim(ValueType)),
                    L = ToTypedValue(Left, TypeName),
                    R = ToTypedValue(Right, TypeName)
                in
                    if TypeName = "TEXT" then TextEquals(L, R) else L = R,

            MissingRuleColumns = List.Difference(RequiredRuleColumns, Table.ColumnNames(RulesTable)),
            _ValidateRuleColumns = if List.Count(MissingRuleColumns) > 0 then Raise("RulesTable is missing required columns.", MissingRuleColumns) else null,

            MissingMapColumns = List.Difference(RequiredMapColumns, Table.ColumnNames(AttributeMap)),
            _ValidateMapColumns = if List.Count(MissingMapColumns) > 0 then Raise("AttributeMap is missing required columns.", MissingMapColumns) else null,

            ActiveRules = Table.SelectRows(RulesTable, each [Active] = true),
            CanonicalAttributes = AttributeMap[CanonicalAttribute],
            DuplicateCanonicalAttributes = List.Select(List.Distinct(CanonicalAttributes), (Name) => List.Count(List.Select(CanonicalAttributes, each _ = Name)) > 1),
            _ValidateCanonicalUniqueness = if List.Count(DuplicateCanonicalAttributes) > 0 then Raise("AttributeMap contains duplicate CanonicalAttribute values.", DuplicateCanonicalAttributes) else null,

            MapRecord = Record.FromList(AttributeMap[TargetColumn], AttributeMap[CanonicalAttribute]),
            HasJobProfileRules = Table.RowCount(Table.SelectRows(ActiveRules, each Text.Upper(Text.Trim(Text.From([JobArchitectureLevel]))) = "JOBPROFILE")) > 0,
            RequiredCanonicalAttributes = List.Distinct(List.Combine({
                {"CountryID", "SurveyID", "MarketDataCode"},
                if HasJobProfileRules then {"JobProfileName"} else {},
                ActiveRules[Field]
            })),
            MissingCanonicalMappings = List.Difference(RequiredCanonicalAttributes, Record.FieldNames(MapRecord)),
            _ValidateCanonicalMappings = if List.Count(MissingCanonicalMappings) > 0 then Raise("AttributeMap does not map all canonical attributes required by the active rules.", MissingCanonicalMappings) else null,

            RequiredTargetColumns = List.Transform(RequiredCanonicalAttributes, each Record.Field(MapRecord, _)),
            MissingTargetColumns = List.Difference(RequiredTargetColumns, Table.ColumnNames(TargetTable)),
            _ValidateTargetColumns = if List.Count(MissingTargetColumns) > 0 then Raise("TargetTable is missing columns required by AttributeMap.", MissingTargetColumns) else null,

            ExistingAuditColumns = List.Intersect({AuditColumns, Table.ColumnNames(TargetTable)}),
            _ValidateAuditColumns = if List.Count(ExistingAuditColumns) > 0 then Raise("TargetTable already contains reserved audit columns.", ExistingAuditColumns) else null,

            Mode = Text.Upper(Text.Trim(OutputMode)),
            _ValidateOutputMode = if not List.Contains({"REPLACE", "ADDCOLUMN"}, Mode) then Raise("OutputMode must be Replace or AddColumn.", OutputMode) else null,
            ResultColumnName = if OutputColumnName = null or Text.Trim(OutputColumnName) = "" then "MarketDataCode_Override" else Text.Trim(OutputColumnName),
            _ValidateResultColumn = if Mode = "ADDCOLUMN" and List.Contains(Table.ColumnNames(TargetTable), ResultColumnName) then Raise("OutputColumnName already exists in TargetTable.", ResultColumnName) else null,

            InvalidOperators = List.Difference(List.Distinct(List.Transform(ActiveRules[Operator], each Text.Upper(Text.Trim(Text.From(_))))), SupportedOperators),
            _ValidateOperators = if List.Count(InvalidOperators) > 0 then Raise("RulesTable contains unsupported operators.", InvalidOperators) else null,

            InvalidActions = List.Difference(List.Distinct(List.Transform(ActiveRules[ActionType], each Text.Upper(Text.Trim(Text.From(_))))), SupportedActions),
            _ValidateActions = if List.Count(InvalidActions) > 0 then Raise("RulesTable contains unsupported action types.", InvalidActions) else null,

            InvalidValueTypes = List.Difference(List.Distinct(List.Transform(ActiveRules[ValueType], each Text.Upper(Text.Trim(Text.From(_))))), SupportedValueTypes),
            _ValidateValueTypes = if List.Count(InvalidValueTypes) > 0 then Raise("RulesTable contains unsupported ValueType values.", InvalidValueTypes) else null,

            InvalidArchitectureLevels = List.Difference(List.Distinct(List.Transform(ActiveRules[JobArchitectureLevel], each Text.Upper(Text.Trim(Text.From(_))))), SupportedArchitectureLevels),
            _ValidateArchitectureLevels = if List.Count(InvalidArchitectureLevels) > 0 then Raise("RulesTable contains JobArchitectureLevel values not supported in V1. Supported: JobProfile, ALL.", InvalidArchitectureLevels) else null,

            InvalidAllScopes = Table.SelectRows(ActiveRules, each Text.Upper(Text.Trim(Text.From([JobArchitectureLevel]))) = "ALL" and Text.Upper(Text.Trim(Text.From([JobArchitectureName]))) <> "ALL"),
            _ValidateAllScopes = if Table.RowCount(InvalidAllScopes) > 0 then Raise("JobArchitectureLevel ALL requires JobArchitectureName ALL.", Table.SelectColumns(InvalidAllScopes, {"RuleGroupID", "RuleID", "JobArchitectureName"})) else null,

            JobProfileColumn = if HasJobProfileRules then Record.Field(MapRecord, "JobProfileName") else null,
            ExistingJobProfileNames = if HasJobProfileRules then List.Distinct(List.RemoveNulls(Table.Column(TargetTable, JobProfileColumn))) else {},
            ConfiguredJobProfileNames = if HasJobProfileRules then List.Distinct(Table.SelectRows(ActiveRules, each Text.Upper(Text.Trim(Text.From([JobArchitectureLevel]))) = "JOBPROFILE")[JobArchitectureName]) else {},
            UnknownJobProfileNames = if HasJobProfileRules then List.Select(ConfiguredJobProfileNames, (Name) => not List.AnyTrue(List.Transform(ExistingJobProfileNames, each TextEquals(_, Name)))) else {},
            _ValidateJobProfileNames = if List.Count(UnknownJobProfileNames) > 0 then Raise("RulesTable contains JobProfile architecture names not present in TargetTable.", UnknownJobProfileNames) else null,

            RuleMetadataColumns = {
                "CountryID", "SurveyID", "JobArchitectureLevel", "JobArchitectureName",
                "RuleGroupID", "RuleGroupExecutionOrder", "RuleID", "RuleExecutionOrder",
                "ActionType", "ActionValue", "ActionFrom", "ActionTo", "StopAfterRuleGroup"
            },
            RuleConsistency = Table.Group(
                ActiveRules,
                {"CountryID", "SurveyID", "JobArchitectureLevel", "JobArchitectureName", "RuleGroupID", "RuleID"},
                {{"MetadataVariants", each Table.RowCount(Table.Distinct(Table.SelectColumns(_, RuleMetadataColumns))), Int64.Type}}
            ),
            InconsistentRules = Table.SelectRows(RuleConsistency, each [MetadataVariants] <> 1),
            _ValidateRuleConsistency = if Table.RowCount(InconsistentRules) > 0 then Raise("A RuleID has inconsistent repeated metadata or action values across its condition rows.", InconsistentRules) else null,

            RuleOrders = Table.Distinct(Table.SelectColumns(ActiveRules, {"CountryID", "SurveyID", "JobArchitectureLevel", "JobArchitectureName", "RuleGroupID", "RuleID", "RuleExecutionOrder"})),
            DuplicateRuleOrders = Table.SelectRows(
                Table.Group(
                    RuleOrders,
                    {"CountryID", "SurveyID", "JobArchitectureLevel", "JobArchitectureName", "RuleGroupID", "RuleExecutionOrder"},
                    {{"RuleCount", each Table.RowCount(_), Int64.Type}}
                ),
                each [RuleCount] > 1
            ),
            _ValidateRuleOrders = if Table.RowCount(DuplicateRuleOrders) > 0 then Raise("RuleExecutionOrder must be unique within each RuleGroup scope.", DuplicateRuleOrders) else null,

            GroupOrders = Table.Distinct(Table.SelectColumns(ActiveRules, {"CountryID", "SurveyID", "JobArchitectureLevel", "JobArchitectureName", "RuleGroupID", "RuleGroupExecutionOrder", "StopAfterRuleGroup"})),
            GroupOrderConsistency = Table.SelectRows(
                Table.Group(
                    GroupOrders,
                    {"CountryID", "SurveyID", "JobArchitectureLevel", "JobArchitectureName", "RuleGroupID"},
                    {{"VariantCount", each Table.RowCount(_), Int64.Type}}
                ),
                each [VariantCount] <> 1
            ),
            _ValidateGroupOrders = if Table.RowCount(GroupOrderConsistency) > 0 then Raise("A RuleGroupID has inconsistent RuleGroupExecutionOrder or StopAfterRuleGroup values within the same scope.", GroupOrderConsistency) else null,

            ValidationComplete =
                _ValidateRuleColumns = null and
                _ValidateMapColumns = null and
                _ValidateCanonicalUniqueness = null and
                _ValidateCanonicalMappings = null and
                _ValidateTargetColumns = null and
                _ValidateAuditColumns = null and
                _ValidateOutputMode = null and
                _ValidateResultColumn = null and
                _ValidateOperators = null and
                _ValidateActions = null and
                _ValidateValueTypes = null and
                _ValidateArchitectureLevels = null and
                _ValidateAllScopes = null and
                _ValidateJobProfileNames = null and
                _ValidateRuleConsistency = null and
                _ValidateRuleOrders = null and
                _ValidateGroupOrders = null,

            RuleGroups = if ValidationComplete then
                Table.Group(
                    ActiveRules,
                    {"CountryID", "SurveyID", "JobArchitectureLevel", "JobArchitectureName", "RuleGroupID", "RuleGroupExecutionOrder", "StopAfterRuleGroup"},
                    {{"Rows", each _, type table}}
                )
            else
                Raise("Rule engine validation failed."),

            GetMappedValue = (Row as record, CanonicalAttribute as text, CurrentMarketCode as any) as any =>
                if TextEquals(CanonicalAttribute, "MarketDataCode") then CurrentMarketCode
                else Record.Field(Row, Record.Field(MapRecord, CanonicalAttribute)),

            EvaluateCondition = (Row as record, CurrentMarketCode as any, Condition as record) as logical =>
                let
                    Operator = Text.Upper(Text.Trim(Text.From(Condition[Operator]))),
                    ValueType = Text.Upper(Text.Trim(Text.From(Condition[ValueType]))),
                    Left = GetMappedValue(Row, Text.From(Condition[Field]), CurrentMarketCode),
                    Right = Condition[Value],
                    LeftText = NormalizeText(Left),
                    RightText = NormalizeText(Right),
                    InValues = if Operator = "IN" and Right <> null then List.Transform(Text.Split(Text.From(Right), "|"), each Text.Trim(_)) else {}
                in
                    if Operator = "ISBLANK" then IsBlankValue(Left)
                    else if Operator = "ISNOTBLANK" then not IsBlankValue(Left)
                    else if Operator = "EQUALS" then CompareEquals(Left, Right, ValueType)
                    else if Operator = "NOTEQUALS" then not CompareEquals(Left, Right, ValueType)
                    else if Operator = "STARTSWITH" then LeftText <> null and RightText <> null and Text.StartsWith(LeftText, RightText, Comparer.OrdinalIgnoreCase)
                    else if Operator = "ENDSWITH" then LeftText <> null and RightText <> null and Text.EndsWith(LeftText, RightText, Comparer.OrdinalIgnoreCase)
                    else if Operator = "CONTAINS" then LeftText <> null and RightText <> null and Text.Contains(LeftText, RightText, Comparer.OrdinalIgnoreCase)
                    else if Operator = "IN" then List.AnyTrue(List.Transform(InValues, each CompareEquals(Left, _, ValueType)))
                    else false,

            ApplyAction = (CurrentMarketCode as any, Rule as record) as any =>
                let
                    ActionType = Text.Upper(Text.Trim(Text.From(Rule[ActionType]))),
                    CurrentText = NormalizeText(CurrentMarketCode),
                    FromText = NormalizeText(Rule[ActionFrom]),
                    ToText = if Rule[ActionTo] = null then "" else Text.From(Rule[ActionTo])
                in
                    if ActionType = "REPLACEWITH" then Rule[ActionValue]
                    else if ActionType = "REPLACESUFFIX" then
                        if CurrentText = null or FromText = null or FromText = "" then CurrentMarketCode
                        else if Text.EndsWith(CurrentText, FromText, Comparer.OrdinalIgnoreCase) then Text.Start(CurrentText, Text.Length(CurrentText) - Text.Length(FromText)) & ToText
                        else CurrentMarketCode
                    else CurrentMarketCode,

            ScopeMatches = (Row as record, Group as record) as logical =>
                let
                    Level = Text.Upper(Text.Trim(Text.From(Group[JobArchitectureLevel])))
                in
                    TextEquals(GetMappedValue(Row, "CountryID", null), Group[CountryID]) and
                    TextEquals(GetMappedValue(Row, "SurveyID", null), Group[SurveyID]) and
                    (if Level = "ALL" then true else TextEquals(GetMappedValue(Row, "JobProfileName", null), Group[JobArchitectureName])),

            EvaluateRow = (Row as record) as record =>
                let
                    OriginalMarketCode = GetMappedValue(Row, "MarketDataCode", null),
                    EligibleGroups = Table.Sort(Table.SelectRows(RuleGroups, each ScopeMatches(Row, _)), {{"RuleGroupExecutionOrder", Order.Ascending}, {"RuleGroupID", Order.Ascending}}),
                    InitialState = [CurrentValue = OriginalMarketCode, AppliedGroups = {}, AppliedRules = {}, Conflict = false, Stop = false],
                    FinalState = List.Accumulate(
                        Table.ToRecords(EligibleGroups),
                        InitialState,
                        (State as record, Group as record) as record =>
                            if State[Stop] then State
                            else
                                let
                                    RuleTables = Table.Sort(
                                        Table.Group(Group[Rows], {"RuleID", "RuleExecutionOrder"}, {{"Rows", each _, type table}}),
                                        {{"RuleExecutionOrder", Order.Ascending}, {"RuleID", Order.Ascending}}
                                    ),
                                    MatchingRules = List.Select(
                                        Table.ToRecords(RuleTables),
                                        (RuleTable as record) => List.AllTrue(List.Transform(Table.ToRecords(RuleTable[Rows]), (Condition as record) => EvaluateCondition(Row, State[CurrentValue], Condition)))
                                    ),
                                    HasMatch = List.Count(MatchingRules) > 0,
                                    WinningRuleTable = if HasMatch then MatchingRules{0} else null,
                                    WinningRule = if HasMatch then Table.First(WinningRuleTable[Rows]) else null,
                                    NewValue = if HasMatch then ApplyAction(State[CurrentValue], WinningRule) else State[CurrentValue],
                                    ValueChanged = HasMatch and not (if State[CurrentValue] = null and NewValue = null then true else if State[CurrentValue] = null or NewValue = null then false else Text.From(State[CurrentValue]) = Text.From(NewValue)),
                                    MultipleRulesMatched = List.Count(MatchingRules) > 1,
                                    NewAppliedGroups = if ValueChanged then List.Combine({State[AppliedGroups], {Text.From(Group[RuleGroupID])}}) else State[AppliedGroups],
                                    NewAppliedRules = if ValueChanged then List.Combine({State[AppliedRules], {Text.From(WinningRule[RuleID])}}) else State[AppliedRules],
                                    StopAfter = HasMatch and Group[StopAfterRuleGroup] = true
                                in
                                    [
                                        CurrentValue = NewValue,
                                        AppliedGroups = NewAppliedGroups,
                                        AppliedRules = NewAppliedRules,
                                        Conflict = State[Conflict] or MultipleRulesMatched,
                                        Stop = StopAfter
                                    ]
                    ),
                    AppliedCount = List.Count(FinalState[AppliedRules])
                in
                    [
                        OriginalMarketDataCode = OriginalMarketCode,
                        FinalMarketDataCode = FinalState[CurrentValue],
                        OverrideApplied = AppliedCount > 0,
                        AppliedRuleGroups = Text.Combine(FinalState[AppliedGroups], "|"),
                        AppliedRuleIDs = Text.Combine(FinalState[AppliedRules], "|"),
                        AppliedRuleCount = AppliedCount,
                        RuleConflictDetected = FinalState[Conflict]
                    ],

            WithEngineResult = Table.AddColumn(TargetTable, "__MarketMappingRuleEngine", each EvaluateRow(_), type record),
            WithFinalTarget =
                if Mode = "ADDCOLUMN" then
                    Table.AddColumn(WithEngineResult, ResultColumnName, each [__MarketMappingRuleEngine][FinalMarketDataCode])
                else
                    let
                        AddReplacement = Table.AddColumn(WithEngineResult, "__MarketMappingReplacement", each [__MarketMappingRuleEngine][FinalMarketDataCode]),
                        RemoveOriginal = Table.RemoveColumns(AddReplacement, {Record.Field(MapRecord, "MarketDataCode")}),
                        RenameReplacement = Table.RenameColumns(RemoveOriginal, {{"__MarketMappingReplacement", Record.Field(MapRecord, "MarketDataCode")}})
                    in
                        RenameReplacement,
            ExpandAudit = Table.ExpandRecordColumn(WithFinalTarget, "__MarketMappingRuleEngine", AuditColumns, AuditColumns)
        in
            ExpandAudit,

    documentation = [
        Documentation.Name = "Table.ApplyMarketMappingOverrides.pq",
        Documentation.Description = "Applies configuration-driven market mapping overrides to a table using canonical rule attributes and a separate attribute map.",
        Documentation.LongDescription = "Evaluates country-, survey-, and job-architecture-scoped RuleGroups in order. Within each RuleGroup the first matching RuleID wins. Supports ReplaceWith and ReplaceSuffix actions, Replace/AddColumn output modes, and audit columns showing applied rules and conflicts.",
        Documentation.Category = "Table",
        Documentation.Source = "GitKlink/dax-m-query-library",
        Documentation.Version = "1.0",
        Documentation.Author = "GitKlink",
        Documentation.Examples = {
            [
                Description = "Use AddColumn while testing so the original market code is preserved.",
                Code = "= Table.ApplyMarketMappingOverrides(TargetTable, RulesTable, AttributeMap, \"AddColumn\", \"MarketDataCode_Override\")",
                Result = "Returns TargetTable plus MarketDataCode_Override and audit columns."
            ]
        }
    ]
in
    Value.ReplaceType(func, Value.ReplaceMetadata(Value.Type(func), documentation))