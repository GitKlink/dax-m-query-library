let
    TestResults = {
        #"03-core-rule-evaluation",
        #"04-rule-ordering-and-conflicts",
        #"05-condition-operators-and-types",
        #"06-actions-and-output-modes",
        #"07-fail-fast-validation"
    },
    Combined = Table.Combine(TestResults),
    Failures = Table.SelectRows(Combined, each [Pass] <> true),
    Result =
        if Table.RowCount(Failures) = 0 then
            Combined
        else
            error Error.Record("MarketMappingRuleEngineTest", "One or more core engine verification fixtures failed.", Failures)
in
    Result
