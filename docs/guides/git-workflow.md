# Git Workflow

This guide defines the repository-wide Git and GitHub defaults. It fills in gaps that are not already prescribed by an active Ask Matt / engineering skill.

## Precedence

1. Follow the active Ask Matt / engineering skill when it gives a specific workflow instruction.
2. Otherwise follow this repository Git workflow.
3. Feature-specific specs and ADRs may specialize these defaults, but must not silently override repo-wide safety rules.

If a feature needs a repository-wide exception, record that decision in a repo ADR.

## 🌿 Branches

- Treat `main` as the stable source of truth.
- Do not perform normal feature implementation directly on `main`.
- Use short-lived feature branches named `feature/<feature-slug>` unless an active workflow prescribes something more specific.
- A feature branch should normally represent one coherent feature/workstream.
- Keep unrelated work on separate branches.

## 🧱 Commits

- Keep commits coherent and reviewable: one logical change per commit where practical.
- Use concise outcome-based commit messages such as `Add rule conflict fixtures`, not vague messages such as `updates`.
- Do not mix unrelated refactors, formatting churn, and feature behaviour in one commit unless the change cannot safely be separated.
- Prefer a clean, understandable history over rewriting history solely for cosmetic perfection.

## 🔀 Pull requests

- Merge feature work to `main` through pull requests.
- Keep pull requests in draft while implementation, verification, or required workflow steps are incomplete.
- Link the parent feature issue and relevant implementation tickets.
- Use `Closes #...` only when merging the PR into the default branch should actually close that issue.
- Follow `docs/guides/github-communication.md` for PR structure, review comments, status updates, and action-required messaging.
- Do not merge while required blockers remain.

## 🧪 Merge readiness

Before a feature PR is ready for final merge, confirm the requirements applicable to that feature are complete, including:

- approved specification where the workflow requires one;
- implementation tickets complete;
- tests and synthetic fixtures passing;
- runtime verification complete where relevant;
- documentation aligned with actual behaviour;
- ADRs in the correct final state;
- review comments and requested changes resolved;
- no known unresolved defects that violate the approved scope.

Do not interpret this checklist as replacing a more specific Ask Matt skill gate.

## 🧹 History safety

- Never force-push `main`.
- Avoid rewriting history on branches once other humans or agents may depend on those commits.
- Rebasing local/unshared work is acceptable when it improves integration.
- Do not rebase or force-push shared history casually.
- Prefer normal merge/rebase operations that preserve comprehensible history and keep the working branch recoverable.

## 🔒 Branch protection

Where repository settings allow it, protect `main` with sensible GitHub rules such as:

- require pull requests before merge;
- require conversations to be resolved;
- require status checks once CI checks exist;
- block force pushes;
- block branch deletion;
- require review when practical for the collaboration model.

Repository settings are enforcement; this guide remains the behavioural default even when a rule is not technically enforced by GitHub.

## 🔗 Issues and dependencies

- Keep the parent feature issue open until the feature itself is complete.
- Close implementation tickets when their accepted slice is complete.
- Preserve explicit blocker relationships between tickets.
- Work the dependency frontier: start tickets whose blockers are complete rather than ignoring declared dependencies.

## 📦 Feature lifecycle

For this repository, the normal lifecycle is:

```text
GitHub Issue
    ↓
in-progress/<feature>/
    ↓
spec + ADRs + tests + examples
    ↓
feature/<feature> branch
    ↓
implementation + verification
    ↓
library/<domain>/ published asset
    ↓
features/<feature>/ completed engineering record
    ↓
final PR review and merge
```

- Active engineering records belong in `in-progress/<feature>/`.
- Reusable consumable outputs belong in `library/`.
- Completed permanent engineering records belong in `features/<feature>/`.
- Promotion from `in-progress/` to `features/` should happen only when the feature has actually reached its completion gate.

## 🚨 Destructive actions

- Do not delete unmerged branches that contain unique work.
- Do not delete files, branches, tags, or rewrite shared history without clear intent.
- Do not close the parent feature issue merely because a child ticket or draft PR exists.
- Do not merge a draft PR.
- When a destructive operation could remove unique work, verify the target and recovery path first.

## 🛡️ Repository hygiene

- Never commit credentials, secrets, tokens, private URLs containing sensitive identifiers, or confidential/proprietary source data.
- Prefer synthetic examples and tests for public repository content.
- Keep temporary files, local caches, generated junk, and environment-specific artefacts out of version control using `.gitignore` where appropriate.
- Review staged changes before commit when working locally.

## 💡 Guiding principle

Use Git to make changes easy to review, easy to verify, and easy to recover. Prefer explicit history and safe collaboration over clever history manipulation.
