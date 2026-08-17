# In Progress

Active feature engineering records live here.

Each feature should use a lowercase kebab-case folder such as:

```text
in-progress/market-mapping-rule-engine/
```

The normal feature shape is:

```text
README.md
spec.md
adr/
tests/
examples/
```

Optional `experiments/` and `fixtures/` folders should be added only when needed.

The final reusable implementation is published under `library/`; this folder is not a second consumable implementation location.
