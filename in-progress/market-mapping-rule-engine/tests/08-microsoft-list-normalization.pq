let
    MicrosoftListShape = #table(
        type table [
            ID=number,
            CountryChoice=any,
            SurveyChoice=any,
            ArchitectureChoice=any,
            ArchitectureName=text,
            GroupKey=text,
            GroupOrder=any,
            RuleKey=text,
            RuleOrder=any,
            ConditionOrder=any,
            FieldChoice=any,
            OperatorChoice=any,
            ConfiguredValue=nullable text,
            ValueTypeChoice=any,
            ActionChoice=any,
            ActionValueText=nullable text,
            ActionFromText=nullable text,
            ActionToText=nullable text,
            StopAfter=any,
            IsActive=any
        ],
        {
            {123, [Value="AU"], [Value="SURVEY_A"], [Value="ALL"], "ALL", "GROUP_A", "10", "RULE_A", "20", "1", [Value="Scenario"], [Value="Equals"], "  MATCH  ", [Value="Text"], [Value="ReplaceWith"], " RESULT ", "   ", null, "No", "Yes"}
        }
    ),

    SourceColumnMap = [
        CountryID="CountryChoice",
        SurveyID="SurveyChoice",
        JobArchitectureLevel="ArchitectureChoice",
        JobArchitectureName="ArchitectureName",
        RuleGroupID="GroupKey",
        RuleGroupExecutionOrder="GroupOrder",
        RuleID="RuleKey",
        RuleExecutionOrder="RuleOrder",
        ConditionID="ConditionOrder",
        Field="FieldChoice",
        Operator="OperatorChoice",
        Value="ConfiguredValue",
        ValueType="ValueTypeChoice",
        ActionType="ActionChoice",
        ActionValue="ActionValueText",
        ActionFrom="ActionFromText",
        ActionTo="ActionToText",
        StopAfterRuleGroup="StopAfter",
        Active="IsActive"
    ],

    Normalized = #"Table.NormalizeMicrosoftListMarketMappingRules"(MicrosoftListShape, SourceColumnMap),
    Row = Normalized{0},

    TargetTable = #table(type table [Country=text, Survey=text, Scenario=text, MarketCode=text], {{"AU","SURVEY_A","MATCH","BASE"}}),
    AttributeMap = #table(
        type table [CanonicalAttribute=text, TargetColumn=text, DataType=text],
        {
            {"CountryID","Country","Text"},
            {"SurveyID","Survey","Text"},
            {"Scenario","Scenario","Text"},
            {"MarketDataCode","MarketCode","Text"}
        }
    ),
    EngineResult = #"Table.ApplyMarketMappingOverrides"(TargetTable, Normalized, AttributeMap, "AddColumn", "OverrideCode"),

    ExpectedColumns = {"CountryID","SurveyID","JobArchitectureLevel","JobArchitectureName","RuleGroupID","RuleGroupExecutionOrder","RuleID","RuleExecutionOrder","ConditionID","Field","Operator","Value","ValueType","ActionType","ActionValue","ActionFrom","ActionTo","StopAfterRuleGroup","Active"},

    Assertions = {
        Table.ColumnNames(Normalized) = ExpectedColumns,
        not List.Contains(Table.ColumnNames(Normalized), "ID"),
        Row[CountryID] = "AU",
        Row[SurveyID] = "SURVEY_A",
        Row[JobArchitectureLevel] = "ALL",
        Row[Field] = "Scenario",
        Row[Operator] = "Equals",
        Row[Value] = "MATCH",
        Row[ActionValue] = "RESULT",
        Row[ActionFrom] = null,
        Row[RuleGroupExecutionOrder] = 10,
        Row[RuleExecutionOrder] = 20,
        Row[ConditionID] = 1,
        Row[StopAfterRuleGroup] = false,
        Row[Active] = true,
        EngineResult{0}[FinalMarketDataCode] = "RESULT"
    },

    Result =
        if List.AllTrue(Assertions) then
            #table(type table [Test=text, Pass=logical], {{"Issue #8 Microsoft List normalization", true}})
        else
            error Error.Record("MarketMappingRuleEngineTest", "Issue #8 Microsoft List normalization fixture failed.", Normalized)
in
    Result
