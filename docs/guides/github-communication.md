# GitHub Communication Conventions

Use a small, consistent emoji vocabulary as visual icons in GitHub Issues, pull requests, review comments, implementation summaries, and status updates. The purpose is scanability, not decoration.

## Icon vocabulary

- 🧭 **Status / current stage** — workflow position or current state.
- 🎯 **Goal / outcome** — intended result of an issue, PR, or change.
- ✅ **Done / verified** — completed work, confirmed behaviour, or met acceptance criteria.
- 🛠️ **Implementation** — code, configuration, or structural changes.
- 🧪 **Testing / verification** — tests, fixtures, runtime checks, or validation.
- 📚 **Docs / spec / ADR** — documentation and design records.
- 🔗 **Dependencies / blockers** — related issues, prerequisites, or blocking work.
- ⚠️ **Risk / attention** — caveats, unresolved concerns, breaking behaviour, or important review points.
- ❌ **Failed / rejected / unsupported** — explicit failure or unsupported behaviour.
- 🚧 **In progress / incomplete** — work started but not complete.
- 👀 **Review required** — human review is needed.
- 🧑‍💻 **Action required** — the repository owner or reviewer must take a specific action.
- 📦 **Deliverable / published asset** — final reusable output or release target.
- 🔀 **Branch / PR / merge** — Git workflow state when useful.
- 💡 **Decision / rationale** — notable design choice or rationale.

## Usage rules

1. Use one icon per heading or meaningful status bullet; do not stack decorative emoji.
2. Keep each icon's meaning consistent across the repository.
3. Prefer icon-led headings for long Issue and PR descriptions because they are easier to scan.
4. Do not add emoji where it reduces clarity, especially inside code, identifiers, paths, schemas, or acceptance criteria.
5. When a human must do something, make it unmistakable with `## 🧑‍💻 Action required` and state the exact action.
6. Use `⚠️` only for genuine risks, caveats, unresolved decisions, or important attention points.
7. Use `✅` only for work that is actually complete or verified; do not use it for planned work.

## Preferred PR structure

Use the sections that are relevant; omit empty sections.

```text
## 🎯 Goal
## 🧭 Current stage
## ✅ Completed
## 🛠️ Changes
## 🧪 Verification
## ⚠️ Known issues / risks
## 🔗 Related tickets
## 👀 Review focus
## 🧑‍💻 Action required
```

## Preferred status update structure

```text
## 🧭 Current stage
Implementation

## ✅ Completed
- Core rule evaluation

## 🚧 Remaining
- Runtime verification

## ⚠️ Known issue
- Power Query runtime verification has not yet occurred.

## 🧑‍💻 Action required
- Review the updated specification.
```

The same vocabulary should be used by humans and agents so GitHub communication remains predictable and quickly scannable.