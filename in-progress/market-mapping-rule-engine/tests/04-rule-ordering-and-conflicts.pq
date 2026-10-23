let
    TargetTable = #table(
        type table [Country = text, Survey = text, Scenario = text, MarketCode = text],
        {
            {"AU", "SURVEY_A", "CONFLICT", "BASE"},
            {"AU", "SURVEY_A", "SEQUENTIAL", "BASE"},
            {"AU", "SURVEY_A", "STOP_NOOP", "BASE"}
        }
    ),

    AttributeMap = #table(
        type table [CanonicalAttribute = text, TargetColumn = text, DataType = text],
        {
            {"CountryID", "Country", "Text"},
            {"SurveyID", "Survey", "Text"},
            {"Scenario", "Scenario", "Text"},
            {"MarketDataCode", "MarketCode", "Text"}
        }
    ),

    RulesTable = #table(
        type table [CountryID=text, SurveyID=text, JobArchitectureLevel=text, JobArchitectureName=text, RuleGroupID=text, RuleGroupExecutionOrder=number, RuleID=text, RuleExecutionOrder=number, ConditionID=number, Field=text, Operator=text, Value=nullable text, ValueType=text, ActionType=text, ActionValue=nullable text, ActionFrom=nullable text, ActionTo=nullable text, StopAfterRuleGroup=logical, Active=logical],
        {
            {"AU","SURVEY_A","ALL","ALL","CONFLICT_GROUP",10,"FIRST_MATCH",10,1,"Scenario","Equals","CONFLICT","Text","ReplaceWith","FIRST",null,null,false,true},
            {"AU","SURVEY_A","ALL","ALL","CONFLICT_GROUP",10,"SECOND_MATCH",20,1,"Scenario","Equals","CONFLICT","Text","ReplaceWith","SECOND",null,null,false,true},

            {"AU","SURVEY_A","ALL","ALL","SEQ_ONE",20,"SEQ_ONE_RULE",10,1,"Scenario","Equals","SEQUENTIAL","Text","ReplaceWith","STEP_ONE",null,null,false,true},
            {"AU","SURVEY_A","ALL","ALL","SEQ_TWO",30,"SEQ_TWO_RULE",10,1,"MarketDataCode","Equals","STEP_ONE","Text","ReplaceWith","STEP_TWO",null,null,false,true},

            {"AU","SURVEY_A","ALL","ALL","STOP_GROUP",40,"STOP_RULE",10,1,"Scenario","Equals","STOP_NOOP","Text","ReplaceWith","BASE",null,null,true,true},
            {"AU","SURVEY_A","ALL","ALL","AFTER_STOP",50,"AFTER_STOP_RULE",10,1,"Scenario","Equals","STOP_NOOP","Text","ReplaceWith","SHOULD_NOT_APPLY",null,null,false,true}
        }
    ),

    Actual = #"Table.ApplyMarketMappingOverrides"(TargetTable, RulesTable, AttributeMap, "AddColumn", "OverrideCode"),
    ConflictRow = Actual{0},
    SequentialRow = Actual{1},
    StopRow = Actual{2},

    Assertions = {
        ConflictRow[FinalMarketDataCode] = "FIRST",
        ConflictRow[AppliedRuleIDs] = "FIRST_MATCH",
        ConflictRow[RuleConflictDetected] = true,

        SequentialRow[FinalMarketDataCode] = "STEP_TWO",
        SequentialRow[AppliedRuleIDs] = "SEQ_ONE_RULE|SEQ_TWO_RULE",
        SequentialRow[AppliedRuleCount] = 2,
        SequentialRow[RuleConflictDetected] = false,

        StopRow[FinalMarketDataCode] = "BASE",
        StopRow[AppliedRuleIDs] = "",
        StopRow[AppliedRuleCount] = 0,
        StopRow[OverrideApplied] = false,
        StopRow[RuleConflictDetected] = false
    },

    Result =
        if List.AllTrue(Assertions) then
            #table(type table [Test = text, Pass = logical], {{"Issue #4 ordering, conflicts, sequential groups, and stop semantics", true}})
        else
            error Error.Record("MarketMappingRuleEngineTest", "Issue #4 rule ordering/conflict fixture failed.", Actual)
in
    Result
