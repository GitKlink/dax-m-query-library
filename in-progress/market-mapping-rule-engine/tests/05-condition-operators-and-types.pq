let
    TargetTable = #table(
        type table [Country=text, Survey=text, Scenario=text, TextValue=text, NumberValue=number, LogicalValue=logical, DateValue=date, BlankValue=nullable text, MarketCode=text],
        {
            {"AU","SURVEY_A","EQUALS","  Executive  ",42,true,#date(2026,8,17),null,"BASE"},
            {"AU","SURVEY_A","NOTEQUALS","Alpha",42,true,#date(2026,8,17),"x","BASE"},
            {"AU","SURVEY_A","STARTSWITH","  Executive Director  ",42,true,#date(2026,8,17),"x","BASE"},
            {"AU","SURVEY_A","ENDSWITH","Senior Executive  ",42,true,#date(2026,8,17),"x","BASE"},
            {"AU","SURVEY_A","CONTAINS","Head of Lending",42,true,#date(2026,8,17),"x","BASE"},
            {"AU","SURVEY_A","IN","Bravo",42,true,#date(2026,8,17),"x","BASE"},
            {"AU","SURVEY_A","ISBLANK","Alpha",42,true,#date(2026,8,17),"   ","BASE"},
            {"AU","SURVEY_A","ISNOTBLANK","Alpha",42,true,#date(2026,8,17),"value","BASE"},
            {"AU","SURVEY_A","NUMBER","Alpha",42,true,#date(2026,8,17),"x","BASE"},
            {"AU","SURVEY_A","LOGICAL","Alpha",42,true,#date(2026,8,17),"x","BASE"},
            {"AU","SURVEY_A","DATE","Alpha",42,true,#date(2026,8,17),"x","BASE"}
        }
    ),

    AttributeMap = #table(
        type table [CanonicalAttribute=text, TargetColumn=text, DataType=text],
        {
            {"CountryID","Country","Text"},
            {"SurveyID","Survey","Text"},
            {"Scenario","Scenario","Text"},
            {"TextValue","TextValue","Text"},
            {"NumberValue","NumberValue","Number"},
            {"LogicalValue","LogicalValue","Logical"},
            {"DateValue","DateValue","Date"},
            {"BlankValue","BlankValue","Text"},
            {"MarketDataCode","MarketCode","Text"}
        }
    ),

    RuleRows = {
        {"EQUALS","TextValue","Equals","executive","Text"},
        {"NOTEQUALS","TextValue","NotEquals","Beta","Text"},
        {"STARTSWITH","TextValue","StartsWith","executive","Text"},
        {"ENDSWITH","TextValue","EndsWith","EXECUTIVE","Text"},
        {"CONTAINS","TextValue","Contains","OF LEND","Text"},
        {"IN","TextValue","In","Alpha | bravo | Charlie","Text"},
        {"ISBLANK","BlankValue","IsBlank",null,"Text"},
        {"ISNOTBLANK","BlankValue","IsNotBlank",null,"Text"},
        {"NUMBER","NumberValue","Equals","42","Number"},
        {"LOGICAL","LogicalValue","Equals","true","Logical"},
        {"DATE","DateValue","Equals","2026-08-17","Date"}
    },

    RulesTable = #table(
        type table [CountryID=text, SurveyID=text, JobArchitectureLevel=text, JobArchitectureName=text, RuleGroupID=text, RuleGroupExecutionOrder=number, RuleID=text, RuleExecutionOrder=number, ConditionID=number, Field=text, Operator=text, Value=nullable text, ValueType=text, ActionType=text, ActionValue=nullable text, ActionFrom=nullable text, ActionTo=nullable text, StopAfterRuleGroup=logical, Active=logical],
        List.Combine(
            List.Transform(
                List.Positions(RuleRows),
                (i) =>
                    let
                        R = RuleRows{i},
                        Scenario = R{0},
                        OrderValue = (i + 1) * 10
                    in
                        {
                            {"AU","SURVEY_A","ALL","ALL","OPERATORS",10,Scenario,OrderValue,1,"Scenario","Equals",Scenario,"Text","ReplaceWith","MATCH_" & Scenario,null,null,false,true},
                            {"AU","SURVEY_A","ALL","ALL","OPERATORS",10,Scenario,OrderValue,2,R{1},R{2},R{3},R{4},"ReplaceWith","MATCH_" & Scenario,null,null,false,true}
                        }
            )
        )
    ),

    Actual = #"Table.ApplyMarketMappingOverrides"(TargetTable, RulesTable, AttributeMap, "AddColumn", "OverrideCode"),
    ExpectedCodes = List.Transform(TargetTable[Scenario], each "MATCH_" & _),
    ActualCodes = Actual[FinalMarketDataCode],
    AllMatched = List.Count(ActualCodes) = List.Count(ExpectedCodes) and List.AllTrue(List.Transform(List.Positions(ExpectedCodes), each ActualCodes{_} = ExpectedCodes{_})),
    AllApplied = List.AllTrue(Actual[OverrideApplied]),
    NoConflicts = List.AllTrue(List.Transform(Actual[RuleConflictDetected], each _ = false)),

    Result =
        if AllMatched and AllApplied and NoConflicts then
            #table(type table [Test=text, Pass=logical], {{"Issue #5 operators and typed comparisons", true}})
        else
            error Error.Record("MarketMappingRuleEngineTest", "Issue #5 operator/type fixture failed.", Actual)
in
    Result
