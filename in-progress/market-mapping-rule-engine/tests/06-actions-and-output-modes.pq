let
    TargetTable = #table(
        type table [Country=text, Survey=text, Scenario=text, MarketCode=nullable text],
        {
            {"AU","SURVEY_A","SUFFIX_MATCH","ROLE.IC"},
            {"AU","SURVEY_A","SUFFIX_NOOP","ROLE.OTHER"},
            {"AU","SURVEY_A","SUFFIX_NULL",null},
            {"AU","SURVEY_A","REPLACE_NULL",null}
        }
    ),

    AttributeMap = #table(
        type table [CanonicalAttribute=text, TargetColumn=text, DataType=text],
        {
            {"CountryID","Country","Text"},
            {"SurveyID","Survey","Text"},
            {"Scenario","Scenario","Text"},
            {"MarketDataCode","MarketCode","Text"}
        }
    ),

    RulesTable = #table(
        type table [CountryID=text, SurveyID=text, JobArchitectureLevel=text, JobArchitectureName=text, RuleGroupID=text, RuleGroupExecutionOrder=number, RuleID=text, RuleExecutionOrder=number, ConditionID=number, Field=text, Operator=text, Value=nullable text, ValueType=text, ActionType=text, ActionValue=nullable text, ActionFrom=nullable text, ActionTo=nullable text, StopAfterRuleGroup=logical, Active=logical],
        {
            {"AU","SURVEY_A","ALL","ALL","ACTIONS",10,"SUFFIX_MATCH",10,1,"Scenario","Equals","SUFFIX_MATCH","Text","ReplaceSuffix",null,".IC",".MGR",false,true},
            {"AU","SURVEY_A","ALL","ALL","ACTIONS",10,"SUFFIX_NOOP",20,1,"Scenario","Equals","SUFFIX_NOOP","Text","ReplaceSuffix",null,".IC",".MGR",false,true},
            {"AU","SURVEY_A","ALL","ALL","ACTIONS",10,"SUFFIX_NULL",30,1,"Scenario","Equals","SUFFIX_NULL","Text","ReplaceSuffix",null,".IC",".MGR",false,true},
            {"AU","SURVEY_A","ALL","ALL","ACTIONS",10,"REPLACE_NULL",40,1,"Scenario","Equals","REPLACE_NULL","Text","ReplaceWith","RECOVERED",null,null,false,true}
        }
    ),

    AddColumnResult = #"Table.ApplyMarketMappingOverrides"(TargetTable, RulesTable, AttributeMap, "AddColumn", "OverrideCode"),
    DefaultColumnResult = #"Table.ApplyMarketMappingOverrides"(TargetTable, RulesTable, AttributeMap, "AddColumn"),
    ReplaceResult = #"Table.ApplyMarketMappingOverrides"(TargetTable, RulesTable, AttributeMap, "Replace"),

    ExpectedFinal = {"ROLE.MGR", "ROLE.OTHER", null, "RECOVERED"},
    ExpectedApplied = {true, false, false, true},

    AddColumnFinals = AddColumnResult[FinalMarketDataCode],
    ReplaceFinals = ReplaceResult[MarketCode],
    AddColumnApplied = AddColumnResult[OverrideApplied],

    FinalsPass = List.AllTrue(List.Transform(List.Positions(ExpectedFinal), (i) => AddColumnFinals{i} = ExpectedFinal{i} and ReplaceFinals{i} = ExpectedFinal{i})),
    AppliedPass = List.AllTrue(List.Transform(List.Positions(ExpectedApplied), (i) => AddColumnApplied{i} = ExpectedApplied{i})),
    OriginalPreserved = AddColumnResult[MarketCode] = TargetTable[MarketCode],
    CustomOutputPass = AddColumnResult[OverrideCode] = ExpectedFinal,
    DefaultOutputPass = DefaultColumnResult[MarketDataCode_Override] = ExpectedFinal,
    NoOpAuditPass = AddColumnResult{1}[AppliedRuleCount] = 0 and AddColumnResult{1}[AppliedRuleIDs] = "" and AddColumnResult{2}[AppliedRuleCount] = 0,
    ChangedAuditPass = AddColumnResult{0}[OriginalMarketDataCode] = "ROLE.IC" and AddColumnResult{0}[FinalMarketDataCode] = "ROLE.MGR" and AddColumnResult{0}[AppliedRuleIDs] = "SUFFIX_MATCH",

    Result =
        if FinalsPass and AppliedPass and OriginalPreserved and CustomOutputPass and DefaultOutputPass and NoOpAuditPass and ChangedAuditPass then
            #table(type table [Test=text, Pass=logical], {{"Issue #6 actions and output modes", true}})
        else
            error Error.Record("MarketMappingRuleEngineTest", "Issue #6 action/output fixture failed.", AddColumnResult)
in
    Result
