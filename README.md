# DAX & M Query Library

Reusable library of custom Power Query (M) functions, DAX patterns, utilities, and examples for Power BI development, data modelling, transformation, reporting, and analytics.

## Repository structure

```text
.
├── AGENTS.md
├── CONTEXT.md
├── README.md
├── dax/
│   ├── measures/
│   └── patterns/
├── m/
│   ├── functions/
│   └── patterns/
├── docs/
│   ├── adr/
│   ├── agents/
│   └── specs/
└── examples/
```

### M

- `m/functions/` — reusable Power Query functions.
- `m/patterns/` — reusable transformation/query patterns that are not standalone functions.

### DAX

- `dax/measures/` — reusable measure implementations and measure families.
- `dax/patterns/` — reusable modelling/calculation patterns and worked examples.

### Documentation

- `docs/specs/` — feature and design specifications.
- `docs/adr/` — architecture decision records.
- `docs/agents/` — repository-local workflow conventions used by engineering/Ask Matt skills.
- `CONTEXT.md` — domain vocabulary, repository boundaries, and durable design context.
- `AGENTS.md` — concise instructions for agents working in this repository.

### Examples

- `examples/` — synthetic examples and demonstrations. Do not commit confidential employee, remuneration, company, survey-vendor, SharePoint, or other proprietary data.

## Development workflow

GitHub Issues is the canonical issue tracker. Significant additions should generally follow:

```text
grill-with-docs → to-spec → to-tickets → implement → code-review
```

See `AGENTS.md` and `docs/agents/` for repository-specific workflow conventions.

## Public-repository rule

Use synthetic/anonymised examples only. Do not commit credentials, private URLs, real employee data, confidential business rules, proprietary market survey data, or internal company identifiers.
