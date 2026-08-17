# ADR 002: Canonical AttributeMap decouples rules from target schemas

## Status
Accepted

## Context
The same rule configuration may be applied to target tables whose physical column names differ across extracts or models.

## Decision
Rules reference canonical attributes. A separate `AttributeMap` maps each canonical attribute to its physical TargetTable column and declared data type.

## Consequences
Rule configuration is portable across differently shaped target tables. The engine must validate mappings and physical columns before processing.
