let
    TargetTable = #table(
        type table [Country = text, Survey = text, JobProfile = text, PositionTitle = text, MarketCode = nullable text],
        {
            {"AU", "SURVEY_A", "Home Lending", "Executive 1", "BASE_A"},
            {"AU", "SURVEY_A", "Home Lending", "Executive 2", "BASE_B"},
            {"AU", "SURVEY_A", "Home Lending", "Other", null},
            {"AU", "SURVEY_A", "Operations", "Other", "BASE_C"},
            {"NZ", "SURVEY_A", "Home Lending", "Executive 1", "BASE_D"}
        }
    ),

    AttributeMap = #table(
        type table [CanonicalAttribute = text, TargetColumn = text, DataType = text],
        {
            {"CountryID", "Country", "Text"},
            {"SurveyID", "Survey", "Text"},
            {"JobProfileName", "JobProfile", "Text"},
            {"PositionTitle", "PositionTitle", "Text"},
            {"MarketDataCode", "MarketCode", "Text"}
        }
    ),

    RulesTable = #table(
        type table [
            CountryID = text,
            SurveyID = text,
            JobArchitectureLevel = text,
            JobArchitectureName = text,
            RuleGroupID = text,
            RuleGroupExecutionOrder = number,
            RuleID = text,
            RuleExecutionOrder = number,
            ConditionID = number,
            Field = text,
            Operator = text,
            Value = nullable text,
            ValueType = text,
            ActionType = text,
            ActionValue = nullable text,
            ActionFrom = nullable text,
            ActionTo = nullable text,
            StopAfterRuleGroup = logical,
            Active = logical
        ],
        {
            {"AU", "SURVEY_A", "JobProfile", "Home Lending", "EXECUTIVES", 10, "EXEC_1", 10, 1, "PositionTitle", "Equals", "Executive 1", "Text", "ReplaceWith", "CODE_1", null, null, false, true},
            {"AU", "SURVEY_A", "JobProfile", "Home Lending", "EXECUTIVES", 10, "EXEC_1", 10, 2, "JobProfileName", "Equals", "Home Lending", "Text", "ReplaceWith", "CODE_1", null, null, false, true},
            {"AU", "SURVEY_A", "JobProfile", "Home Lending", "EXECUTIVES", 10, "EXEC_2", 20, 1, "PositionTitle", "Equals", "Executive 2", "Text", "ReplaceWith", "CODE_2", null, null, false, true},
            {"AU", "SURVEY_A", "ALL", "ALL", "FILL_NULL", 20, "FILL_NULL_1", 10, 1, "MarketDataCode", "IsBlank", null, "Text", "ReplaceWith", "FALLBACK_CODE", null, null, false, true}
        }
    ),

    Actual = #"Table.ApplyMarketMappingOverrides"(TargetTable, RulesTable, AttributeMap, "AddColumn", "OverrideCode"),

    Expected = #table(
        type table [ExpectedFinal = nullable text, ExpectedOverrideApplied = logical, ExpectedRuleIDs = text],
        {
            {"CODE_1", true, "EXEC_1"},
            {"CODE_2", true, "EXEC_2"},
            {"FALLBACK_CODE", true, "FILL_NULL_1"},
            {"BASE_C", false, ""},
            {"BASE_D", false, ""}
        }
    ),

    IndexedActual = Table.AddIndexColumn(Actual, "__Index", 0, 1, Int64.Type),
    IndexedExpected = Table.AddIndexColumn(Expected, "__Index", 0, 1, Int64.Type),
    Joined = Table.NestedJoin(IndexedActual, {"__Index"}, IndexedExpected, {"__Index"}, "Expected", JoinKind.LeftOuter),
    Expanded = Table.ExpandTableColumn(Joined, "Expected", {"ExpectedFinal", "ExpectedOverrideApplied", "ExpectedRuleIDs"}),
    Assertions = Table.AddColumn(
        Expanded,
        "Pass",
        each
            [FinalMarketDataCode] = [ExpectedFinal]
            and [OverrideCode] = [ExpectedFinal]
            and [OverrideApplied] = [ExpectedOverrideApplied]
            and [AppliedRuleIDs] = [ExpectedRuleIDs]
    ),
    Failures = Table.SelectRows(Assertions, each [Pass] <> true),
    Result =
        if Table.RowCount(Failures) = 0 then
            #table(type table [Test = text, Pass = logical], {{"Issue #3 core rule evaluation", true}})
        else
            error Error.Record("MarketMappingRuleEngineTest", "Issue #3 core rule evaluation fixture failed.", Failures)
in
    Result
