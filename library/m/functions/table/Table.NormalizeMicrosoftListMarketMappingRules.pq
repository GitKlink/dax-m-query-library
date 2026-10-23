let
    func =
        (
            SourceTable as table,
            SourceColumnMap as record
        ) as table =>
        let
            CanonicalColumns = {
                "CountryID", "SurveyID", "JobArchitectureLevel", "JobArchitectureName",
                "RuleGroupID", "RuleGroupExecutionOrder", "RuleID", "RuleExecutionOrder",
                "ConditionID", "Field", "Operator", "Value", "ValueType", "ActionType",
                "ActionValue", "ActionFrom", "ActionTo", "StopAfterRuleGroup", "Active"
            },

            ChoiceColumns = {"CountryID", "SurveyID", "JobArchitectureLevel", "Field", "Operator", "ValueType", "ActionType"},
            NullableTextColumns = {"Value", "ActionValue", "ActionFrom", "ActionTo"},
            RequiredSourceMappings = List.Difference(CanonicalColumns, Record.FieldNames(SourceColumnMap)),
            _ValidateMappings =
                if List.Count(RequiredSourceMappings) > 0 then
                    error Error.Record("MicrosoftListRuleNormalization", "SourceColumnMap is missing canonical RulesTable mappings.", RequiredSourceMappings)
                else
                    null,

            SourceColumns = List.Transform(CanonicalColumns, each Text.From(Record.Field(SourceColumnMap, _))),
            MissingSourceColumns = List.Difference(SourceColumns, Table.ColumnNames(SourceTable)),
            _ValidateSourceColumns =
                if List.Count(MissingSourceColumns) > 0 then
                    error Error.Record("MicrosoftListRuleNormalization", "SourceTable is missing mapped Microsoft List columns.", MissingSourceColumns)
                else
                    null,

            ValidationComplete = _ValidateMappings = null and _ValidateSourceColumns = null,

            Selected =
                if ValidationComplete then
                    Table.SelectColumns(SourceTable, SourceColumns)
                else
                    error Error.Record("MicrosoftListRuleNormalization", "Microsoft List rule normalization validation failed."),

            RenamePairs = List.Transform(CanonicalColumns, each {Text.From(Record.Field(SourceColumnMap, _)), _}),
            Renamed = Table.RenameColumns(Selected, RenamePairs),

            FlattenChoice = (Value as any) as nullable text =>
                if Value = null then
                    null
                else if Value is list then
                    error Error.Record("MicrosoftListRuleNormalization", "Multi-select Choice values are not supported in V1.", Value)
                else if Value is record then
                    if Record.HasFields(Value, "Value") then Text.Trim(Text.From(Record.Field(Value, "Value")))
                    else error Error.Record("MicrosoftListRuleNormalization", "Choice record does not contain a Value field.", Value)
                else
                    Text.Trim(Text.From(Value)),

            NormalizeNullableText = (Value as any) as nullable text =>
                if Value = null then null
                else
                    let T = Text.Trim(Text.From(Value))
                    in if T = "" then null else T,

            NormalizeRequiredText = (Value as any) as nullable text =>
                if Value = null then null else Text.Trim(Text.From(Value)),

            NormalizeLogical = (Value as any) as nullable logical =>
                if Value = null then null
                else if Value is logical then Value
                else if Value is text then
                    let T = Text.Upper(Text.Trim(Value))
                    in
                        if List.Contains({"YES", "TRUE", "1"}, T) then true
                        else if List.Contains({"NO", "FALSE", "0"}, T) then false
                        else Logical.From(Value)
                else
                    Logical.From(Value),

            ChoiceNormalized = Table.TransformColumns(
                Renamed,
                List.Transform(ChoiceColumns, each {_, FlattenChoice, type nullable text})
            ),

            TextNormalized = Table.TransformColumns(
                ChoiceNormalized,
                List.Combine({
                    List.Transform(NullableTextColumns, each {_, NormalizeNullableText, type nullable text}),
                    List.Transform(
                        List.Difference({"JobArchitectureName", "RuleGroupID", "RuleID"}, NullableTextColumns),
                        each {_, NormalizeRequiredText, type nullable text}
                    )
                })
            ),

            Typed = Table.TransformColumns(
                TextNormalized,
                {
                    {"RuleGroupExecutionOrder", each if _ = null then null else Number.From(_), type nullable number},
                    {"RuleExecutionOrder", each if _ = null then null else Number.From(_), type nullable number},
                    {"ConditionID", each if _ = null then null else Number.From(_), type nullable number},
                    {"StopAfterRuleGroup", NormalizeLogical, type nullable logical},
                    {"Active", NormalizeLogical, type nullable logical}
                }
            ),

            Canonical = Table.SelectColumns(Typed, CanonicalColumns)
        in
            Canonical,

    documentation = [
        Documentation.Name = "Table.NormalizeMicrosoftListMarketMappingRules.pq",
        Documentation.Description = "Normalizes a Microsoft List-shaped table into the canonical Market Mapping RulesTable contract.",
        Documentation.LongDescription = "Uses an explicit source-column map to isolate Microsoft List display/internal field names from the rule engine. Flattens single-choice records, normalizes blanks and booleans, applies numeric types to ordering fields, excludes unmapped List metadata such as item ID, and returns only the canonical RulesTable columns.",
        Documentation.Category = "Table",
        Documentation.Source = "GitKlink/dax-m-query-library",
        Documentation.Version = "1.0",
        Documentation.Author = "GitKlink"
    ]
in
    Value.ReplaceType(func, Value.ReplaceMetadata(Value.Type(func), documentation))