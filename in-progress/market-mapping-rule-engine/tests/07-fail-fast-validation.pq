let
    TargetTable = #table(
        type table [Country=text, Survey=text, JobProfile=text, Scenario=text, MarketCode=text],
        {{"AU","SURVEY_A","Profile A","A","BASE"}}
    ),

    AttributeMap = #table(
        type table [CanonicalAttribute=text, TargetColumn=text, DataType=text],
        {
            {"CountryID","Country","Text"},
            {"SurveyID","Survey","Text"},
            {"JobProfileName","JobProfile","Text"},
            {"Scenario","Scenario","Text"},
            {"MarketDataCode","MarketCode","Text"}
        }
    ),

    RulesTable = #table(
        type table [CountryID=text, SurveyID=text, JobArchitectureLevel=text, JobArchitectureName=text, RuleGroupID=text, RuleGroupExecutionOrder=number, RuleID=text, RuleExecutionOrder=number, ConditionID=number, Field=text, Operator=text, Value=nullable text, ValueType=text, ActionType=text, ActionValue=nullable text, ActionFrom=nullable text, ActionTo=nullable text, StopAfterRuleGroup=logical, Active=logical],
        {{"AU","SURVEY_A","ALL","ALL","GROUP_A",10,"RULE_A",10,1,"Scenario","Equals","A","Text","ReplaceWith","RESULT",null,null,false,true}}
    ),

    ExpectError = (Rules as table, Map as table, Target as table, optional OutputName as nullable text) as logical =>
        let
            Attempt = try #"Table.ApplyMarketMappingOverrides"(Target, Rules, Map, "AddColumn", OutputName)
        in
            Attempt[HasError],

    ReplaceRuleField = (FieldName as text, NewValue as any) as table =>
        Table.TransformColumns(RulesTable, {{FieldName, each NewValue}}),

    DuplicateRuleWith = (Overrides as record) as record =>
        Record.Combine({RulesTable{0}, Overrides}),

    MissingRulesColumn = ExpectError(Table.RemoveColumns(RulesTable, {"Operator"}), AttributeMap, TargetTable),
    MissingMapColumn = ExpectError(RulesTable, Table.RemoveColumns(AttributeMap, {"DataType"}), TargetTable),
    DuplicateCanonical = ExpectError(RulesTable, Table.Combine({AttributeMap, Table.FirstN(AttributeMap, 1)}), TargetTable),
    MissingCanonicalMapping = ExpectError(RulesTable, Table.SelectRows(AttributeMap, each [CanonicalAttribute] <> "Scenario"), TargetTable),
    MissingPhysicalMap = Table.FromRecords(Table.TransformRows(AttributeMap, each if [CanonicalAttribute] = "Scenario" then Record.TransformFields(_, {{"TargetColumn", each "MissingScenario"}}) else _)),
    MissingPhysicalColumn = ExpectError(RulesTable, MissingPhysicalMap, TargetTable),

    UnsupportedOperator = ExpectError(ReplaceRuleField("Operator", "Regex"), AttributeMap, TargetTable),
    UnsupportedAction = ExpectError(ReplaceRuleField("ActionType", "Append"), AttributeMap, TargetTable),
    UnsupportedValueType = ExpectError(ReplaceRuleField("ValueType", "Time"), AttributeMap, TargetTable),
    UnsupportedArchitecture = ExpectError(ReplaceRuleField("JobArchitectureLevel", "JobFamily"), AttributeMap, TargetTable),
    InvalidAllName = ExpectError(ReplaceRuleField("JobArchitectureName", "Not ALL"), AttributeMap, TargetTable),

    UnknownProfileRules = Table.FromRecords({DuplicateRuleWith([JobArchitectureLevel="JobProfile", JobArchitectureName="Unknown Profile"])}),
    UnknownProfile = ExpectError(UnknownProfileRules, AttributeMap, TargetTable),

    InconsistentRuleRows = Table.FromRecords({RulesTable{0}, DuplicateRuleWith([ConditionID=2, ActionValue="OTHER"])}),
    InconsistentRuleMetadata = ExpectError(InconsistentRuleRows, AttributeMap, TargetTable),

    DuplicateOrderRows = Table.FromRecords({RulesTable{0}, DuplicateRuleWith([RuleID="RULE_B", RuleExecutionOrder=10])}),
    DuplicateRuleOrder = ExpectError(DuplicateOrderRows, AttributeMap, TargetTable),

    InconsistentGroupRows = Table.FromRecords({RulesTable{0}, DuplicateRuleWith([RuleID="RULE_B", RuleExecutionOrder=20, RuleGroupExecutionOrder=20])}),
    InconsistentGroupMetadata = ExpectError(InconsistentGroupRows, AttributeMap, TargetTable),

    AuditCollisionTarget = Table.AddColumn(TargetTable, "OriginalMarketDataCode", each "EXISTING", type text),
    ExistingAuditCollision = ExpectError(RulesTable, AttributeMap, AuditCollisionTarget),
    ReservedOutputCollision = ExpectError(RulesTable, AttributeMap, TargetTable, "FinalMarketDataCode"),

    Checks = {
        MissingRulesColumn,
        MissingMapColumn,
        DuplicateCanonical,
        MissingCanonicalMapping,
        MissingPhysicalColumn,
        UnsupportedOperator,
        UnsupportedAction,
        UnsupportedValueType,
        UnsupportedArchitecture,
        InvalidAllName,
        UnknownProfile,
        InconsistentRuleMetadata,
        DuplicateRuleOrder,
        InconsistentGroupMetadata,
        ExistingAuditCollision,
        ReservedOutputCollision
    },

    Result =
        if List.AllTrue(Checks) then
            #table(type table [Test=text, Pass=logical], {{"Issue #7 fail-fast validation", true}})
        else
            error Error.Record("MarketMappingRuleEngineTest", "Issue #7 validation fixture failed.", Checks)
in
    Result
