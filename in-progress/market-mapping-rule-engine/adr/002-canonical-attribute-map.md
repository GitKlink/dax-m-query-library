# ADR 002: Canonical AttributeMap decouples rules from target schemas

## Status
Accepted

## Context
The same rule configuration may be applied to target tables whose physical column names differ across extracts or models.

## Decision
Rules reference canonical attributes. A separate `AttributeMap` maps each canonical attribute to its physical TargetTable column and declared data type.

Required canonical mappings are validated before row processing. V1 also validates JobProfile-scoped configuration against JobProfile names present in the current TargetTable, with the known limitation that valid-but-unused profiles will fail until an authoritative architecture reference is introduced.

## Consequences
Rule configuration is portable across differently shaped target tables. The engine must validate mappings and physical columns before processing, and V1 JobProfile validation remains intentionally strict.