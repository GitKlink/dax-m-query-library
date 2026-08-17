# Naming Conventions

## Feature slugs

Use lowercase kebab-case:

```text
market-mapping-rule-engine
dynamic-ranking
fiscal-calendar
```

Use the same slug for the feature folder and normally for the feature branch:

```text
feature/market-mapping-rule-engine
```

## M

Prefer namespace-style function names matching Power Query conventions where practical:

```text
Table.ApplyMarketMappingOverrides.pq
List.SomeFunction.pq
```

Published functions live beneath `library/m/functions/`, grouped by namespace when useful.

## DAX

Use clear descriptive filenames. Keep DAX UDFs distinct from measures:

```text
library/dax/measures/
library/dax/udfs/
library/dax/patterns/
```

## Python

Use standard Python lowercase snake_case for modules/functions. Reusable modules live under `library/python/functions/`; runnable utilities under `scripts/`; adaptable approaches under `patterns/`.

## Deneb

Use kebab-case feature/visual folder names. Keep reusable full visuals under `visuals/`, base specifications under `templates/`, and composable techniques under `patterns/`.

## ADRs

Within a scope, number ADRs sequentially:

```text
001-description.md
002-description.md
```

Repository ADR numbering and each feature's ADR numbering are independent.
