let
    SourceColumnMap = [
        CountryID="Country", SurveyID="Survey", JobArchitectureLevel="ArchitectureLevel", JobArchitectureName="ArchitectureName",
        RuleGroupID="GroupID", RuleGroupExecutionOrder="GroupOrder", RuleID="RuleIDSource", RuleExecutionOrder="RuleOrder",
        ConditionID="ConditionOrder", Field="FieldSource", Operator="OperatorSource", Value="ConfiguredValue", ValueType="ValueTypeSource",
        ActionType="ActionTypeSource", ActionValue="ActionValueSource", ActionFrom="ActionFromSource", ActionTo="ActionToSource",
        StopAfterRuleGroup="StopAfter", Active="IsActive"
    ],

    Source = #table(
        type table [Country=any, Survey=any, ArchitectureLevel=any, ArchitectureName=text, GroupID=text, GroupOrder=any, RuleIDSource=text, RuleOrder=any, ConditionOrder=any, FieldSource=any, OperatorSource=any, ConfiguredValue=nullable text, ValueTypeSource=any, ActionTypeSource=any, ActionValueSource=nullable text, ActionFromSource=nullable text, ActionToSource=nullable text, StopAfter=any, IsActive=any],
        {
            {[Value="AU"], "SURVEY_A", [Value="ALL"], "ALL", "G1", "1", "R1", 10, "1", [Value="Scenario"], [Value="Equals"], "A", [Value="Text"], [Value="ReplaceWith"], "RESULT_A", "", "   ", false, true},
            {"AU", [Value="SURVEY_A"], "ALL", "ALL", "G1", 1, "R2", "20", 1, "Scenario", "Equals", "B", "Text", "ReplaceWith", "RESULT_B", null, null, "No", "Yes"}
        }
    ),

    Normalized = #"Table.NormalizeMicrosoftListMarketMappingRules"(Source, SourceColumnMap),

    Target = #table(type table [Country=text, Survey=text, Scenario=text, MarketCode=text], {{"AU","SURVEY_A","B","BASE"}}),
    AttributeMap = #table(type table [CanonicalAttribute=text, TargetColumn=text, DataType=text], {{"CountryID","Country","Text"},{"SurveyID","Survey","Text"},{"Scenario","Scenario","Text"},{"MarketDataCode","MarketCode","Text"}}),
    EngineResult = #"Table.ApplyMarketMappingOverrides"(Target, Normalized, AttributeMap, "AddColumn", "OverrideCode"),

    MultiSelectSource = Table.TransformColumns(Source, {{"Country", each {"AU","NZ"}}}),
    MultiSelectAttempt = try #"Table.NormalizeMicrosoftListMarketMappingRules"(MultiSelectSource, SourceColumnMap),

    Assertions = {
        Table.RowCount(Normalized) = 2,
        Normalized{0}[CountryID] = "AU",
        Normalized{1}[SurveyID] = "SURVEY_A",
        Normalized{0}[RuleGroupExecutionOrder] = 1,
        Normalized{1}[RuleExecutionOrder] = 20,
        Normalized{0}[ConditionID] = 1,
        Normalized{1}[StopAfterRuleGroup] = false,
        Normalized{1}[Active] = true,
        Normalized{0}[ActionFrom] = null,
        Normalized{0}[ActionTo] = null,
        EngineResult{0}[FinalMarketDataCode] = "RESULT_B",
        MultiSelectAttempt[HasError] = true
    },

    Result =
        if List.AllTrue(Assertions) then
            #table(type table [Test=text, Pass=logical], {{"Issue #10 Microsoft List adapter verification", true}})
        else
            error Error.Record("MarketMappingRuleEngineTest", "Issue #10 adapter verification failed.", Normalized)
in
    Result
