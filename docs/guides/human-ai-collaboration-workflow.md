# Human + AI Collaboration Workflow

## Purpose

This guide defines how humans and AI agents collaborate through GitHub in this repository.

The workflow must remain understandable and usable for collaborators who have **no AI tools at all**.

GitHub is therefore the shared collaboration interface and canonical workflow record.

```text
Human owner / maintainer
        ↕
GitHub Issues + PRs + repository docs
        ↕
Human collaborator without AI tools
        ↕
AI agent / AI-assisted developer
```

AI can accelerate planning, implementation, testing, review, documentation, and coordination, but it must not become a prerequisite for understanding or participating in the work.

---

# 1. 30-second workflow

```text
Idea / problem
    ↓
Feature Issue
    ↓
Discovery / design / spec
    ↓
Human approval of important decisions
    ↓
Implementation tickets
    ↓
ready-for-agent
    ↓
AI or developer implements
    ↓
Tests / evidence
    ↓
ready-for-human when a real human action is required
    ↓
Human tests / reviews / decides
    ↓
ready-for-agent if more work remains
    ↓
Final code/spec review
    ↓
Final human PR review
    ↓
Merge
    ↓
Feature complete
```

The central rule is:

> **The repository manages the workflow. The chat does not.**

Anything another collaborator needs to understand, decide, test, or review must be represented in GitHub or the repository documentation.

---

# 2. User types

## 2.1 Feature owner / maintainer

The feature owner is accountable for the intended outcome.

Typical responsibilities:

- define the problem and desired outcome;
- choose priorities;
- approve significant product or architecture decisions;
- resolve ambiguity or disagreement;
- perform environment actions unavailable to the AI when necessary;
- review the completed PR;
- approve merge or perform the merge.

The owner should **not** need to manually manage every implementation step or keep all ticket state in their head.

---

## 2.2 Human collaborator without AI tools

This person participates using normal GitHub and development tools.

They can:

- read and comment on Issues;
- ask questions;
- provide domain expertise;
- take ownership of an Issue;
- implement code on a branch;
- open or review PRs;
- run Power BI, Power Query, Python, or other runtime tests;
- post screenshots, errors, and test results;
- approve or reject behaviour;
- make design recommendations.

They never need access to the AI conversation to participate successfully.

A ticket assigned to them must contain enough context to complete the requested action from GitHub alone.

---

## 2.3 AI agent / AI-assisted developer

The AI acts as an engineering participant and workflow coordinator.

Typical responsibilities:

- read repository context before acting;
- refine problems into specs and implementation tickets;
- identify dependencies;
- implement unblocked tickets;
- add tests and evidence;
- review implementation against the approved spec;
- update Issues and PR status;
- keep repository documentation current;
- continue automatically until a genuine human gate is reached.

The AI must not rely on private chat context when another collaborator needs the information.

The AI must not ask a human to manage routine workflow state that it can maintain itself.

---

## 2.4 Human developer using AI locally

A human may also use Cursor, Copilot, ChatGPT, Codex, or another AI tool locally.

For workflow purposes, this is still a human contributor.

Their AI tooling is an implementation aid, not a separate source of authority.

Their commits, Issue comments, test evidence, and PR remain the shared record.

---

# 3. The hierarchy of work

Use three levels.

```text
FEATURE
The overall independently valuable outcome

    ↓

TICKET / ISSUE
A meaningful independently verifiable unit of work

    ↓

TASK / CHECKLIST ITEM
A small implementation step inside a ticket
```

Example:

```text
Feature
Market Mapping Rule Engine

Ticket
Fail-fast configuration validation

Tasks
- validate operator values
- validate action values
- validate AttributeMap
- add failure fixtures
```

Do not create a GitHub Issue for every tiny implementation action.

Create a separate Issue when the work:

- has its own acceptance criteria;
- can fail independently;
- may block other work;
- needs its own review or discussion;
- is meaningful enough to remain discoverable later.

Use checklist items when the work is only a step toward the ticket outcome.

---

# 4. GitHub is the shared interface

## Canonical collaboration record

For collaborative work, durable information belongs in one or more of:

```text
GitHub Issue
Pull Request
README
spec.md
ADR
tests / verification record
```

Avoid instructions such as:

```text
Do the thing we discussed earlier.
```

Prefer self-contained instructions:

```text
🎯 Goal
Validate Prototype V0.1 in Power BI Desktop.

▶️ Action
Refresh the project and verify the five named scenarios.

✅ Expected result
NORMAL, NO_MATCH, NULL_FILL and SEQUENTIAL pass;
CONFLICT flags RuleConflictDetected = true.

🧪 Report back
Comment on this Issue with PASS/FAIL and the exact error for any failed scenario.
```

---

# 5. Ownership: assignees vs workflow labels

## Assignees

Use GitHub assignees for **real people who own a current human action**.

Examples:

```text
Assignee: Alex
```

means Alex is personally accountable for the current human action.

Do not assign all AI work to the repository owner merely because the AI is operating on their behalf.

Unless an actual GitHub bot/account exists for an AI agent, do not invent an AI assignee.

---

## Agent-state labels

Use labels to describe what kind of actor can proceed next.

Core states:

```text
needs-triage
    ↓
needs-info
    ↓
ready-for-agent
    ↓
ready-for-human
    ↓
done / closed
```

### `ready-for-agent`

The ticket contains enough information for AI-assisted implementation to continue without a human decision.

Typical state:

```text
Assignee: none
Label: ready-for-agent
```

### `ready-for-human`

A genuine human action is required.

Typical state:

```text
Assignee: specific person
Label: ready-for-human
```

Examples:

- run Power BI Desktop;
- verify a visual interaction;
- approve a product decision;
- review a PR;
- access a system unavailable to the agent.

### `needs-info`

The work cannot proceed because required information is missing.

The Issue should state exactly what information is needed.

---

# 6. What a good implementation ticket contains

Every meaningful implementation ticket should make these things visible:

## 🎯 Outcome

What must exist or be true when this ticket is complete?

## 🛠️ Scope

What can change? What is explicitly out of scope?

## ✅ Acceptance criteria

Observable checks that determine whether the ticket is complete.

## 🔗 Dependencies

What must complete first?

## 🧪 Verification

What test, runtime evidence, screenshot, or review proves completion?

## ⚠️ Human gates

Only include a human gate when a person really needs to act.

## 🧑‍💻 Action required

When present, this must state exactly what the human should do and what result to return.

---

# 7. End-to-end feature workflow

## Stage 1 — Idea / problem

A human identifies a problem, opportunity, defect, or reusable capability.

The initial Issue may be rough.

```text
Human
    ↓
Feature Issue
```

The AI can help clarify the goal and identify missing information.

---

## Stage 2 — Discovery and design

For non-trivial features:

```text
grill / discovery
    ↓
spec
    ↓
ADR(s) when decisions need durable rationale
```

The AI may draft the spec, but important behaviour and trade-offs are approved by a human.

The approved spec becomes the behavioural contract.

---

## Stage 3 — Ticket decomposition

The approved feature is decomposed into implementation tickets when useful.

```text
Feature Issue
    ├── Ticket A
    ├── Ticket B
    ├── Ticket C
    └── Runtime / completion tickets
```

Each ticket should be independently understandable and verifiable.

Dependencies should be explicit.

---

## Stage 4 — Agent execution

An unblocked ticket becomes:

```text
Label: ready-for-agent
Assignee: none
```

The AI:

1. reads the ticket and repository context;
2. implements the requested scope;
3. runs available tests;
4. updates documentation where required;
5. records evidence;
6. updates the Issue / PR;
7. continues to the next unblocked ticket.

The AI should not stop after every minor commit for permission.

---

## Stage 5 — Human gate

When the next step requires a person:

```text
ready-for-agent
    ↓
AI completes everything it can
    ↓
ready-for-human
```

The Issue should identify the specific person when known.

Example:

```text
Assignee: Alex
Label: ready-for-human

## 🧑‍💻 Action required

Open the PBIP in Power BI Desktop.
Refresh all.
Run the CONFLICT scenario.

Expected:
RuleConflictDetected = true

Comment with:
- PASS, or
- FAIL + exact Power Query error
```

---

## Stage 6 — Human response

The human works entirely through normal GitHub/dev tools.

Example response:

```text
🧪 Runtime result

NORMAL ✅
NO_MATCH ✅
NULL_FILL ✅
SEQUENTIAL ✅
CONFLICT ❌

Error:
Expression.Error: ...
```

The comment becomes shared evidence available to the owner, AI, and other collaborators.

---

## Stage 7 — Handoff back to the agent

After the human provides the required result:

```text
ready-for-human
    ↓
human evidence / decision
    ↓
ready-for-agent
```

The human assignee can be cleared when their action is complete.

The AI then:

- reads the result;
- fixes defects if necessary;
- adds regression coverage;
- updates the Issue;
- requests only the smallest necessary retest.

Example:

```text
🛠️ Fixed

The runtime error was caused by ...

✅ Implementation corrected
✅ Regression fixture added

🧑‍💻 Action required
Please rerun only the CONFLICT scenario.
```

---

## Stage 8 — PR review

The PR is the integrated review surface for the feature.

A useful PR status structure is:

```text
🎯 Goal

🧭 Current stage

✅ Completed

🚧 In progress

🧪 Verification

⚠️ Known issues

🔗 Related tickets

👀 Review focus

🧑‍💻 Action required
```

A collaborator without AI should be able to determine from the PR:

- what the change does;
- what has been completed;
- what remains;
- what evidence exists;
- what they are being asked to review.

---

## Stage 9 — Final completion

Before merge:

```text
implementation complete
    ↓
verification complete
    ↓
documentation complete
    ↓
code/spec review complete
    ↓
ready-for-human
    ↓
final owner PR review
    ↓
merge
```

The AI must not treat previous design approval as final merge approval.

---

# 8. Crossover and interaction patterns

## Pattern A — AI implements, human without AI tests

```text
AI
implements change
    ↓
Issue becomes ready-for-human
    ↓
Human collaborator
runs application/runtime test
    ↓
posts result to Issue
    ↓
AI
reads result and continues
```

This is ideal when the AI cannot access Power BI Desktop, a production-like environment, or a physical device.

---

## Pattern B — Human developer implements, AI reviews

```text
Human developer
implements ticket normally
    ↓
opens / updates PR
    ↓
AI
reviews against spec + repo conventions
    ↓
AI posts findings
    ↓
Human fixes or discusses
```

The implementation source does not matter. The shared contract and evidence are the same.

---

## Pattern C — AI proposes design, human domain expert decides

```text
AI
identifies options and trade-offs
    ↓
ready-for-human
    ↓
Domain expert
chooses / corrects behaviour
    ↓
decision captured in Issue / spec / ADR
    ↓
ready-for-agent
    ↓
AI implements
```

Important decisions must be recorded outside private chat.

---

## Pattern D — Human without AI finds a defect

```text
Human collaborator
comments on Issue / opens Issue
    ↓
provides reproduction + error
    ↓
ready-for-agent
    ↓
AI investigates
    ↓
fix + regression test
    ↓
ready-for-human if retest required
```

---

## Pattern E — Two humans and an AI collaborate on one feature

```text
Owner
sets goal and approves spec

Human specialist
validates domain/runtime behaviour

AI
implements, tests, documents, coordinates state

All three
communicate through GitHub
```

No participant should require access to another participant's private AI conversation.

---

# 9. Example: Market Mapping Rule Engine

```text
#1 Feature — Market Mapping Rule Engine

    #3 Core rule evaluation
    #4 Ordering and conflicts
    #5 Operators and types
    #6 Actions and outputs
    #7 Validation
    #8 Microsoft List adapter
    #9 Core verification suite
    #10 Adapter verification
    #11 Runtime verification
    #12 Completion review
```

Example lifecycle:

```text
#3–#10
ready-for-agent
    ↓
AI implements and statically verifies
    ↓
complete

#11
ready-for-agent
    ↓
AI prepares Prototype V0.1
    ↓
ready-for-human
    ↓
human opens Power BI Desktop and reports runtime result
    ↓
ready-for-agent
    ↓
AI resolves defects
    ↓
full runtime suite
    ↓
complete

#12
AI aligns docs + performs final review
    ↓
ready-for-human
    ↓
owner performs final PR review
    ↓
merge
```

---

# 10. When the AI should interrupt a human

The AI should continue automatically until one of these conditions is reached:

## Product / design decision

The correct behaviour is genuinely ambiguous or requires owner judgement.

## Access / environment gate

The next verification requires a runtime, system, device, credential, or UI unavailable to the AI.

## Risky or irreversible action

Examples:

- merge;
- delete;
- publish;
- production change;
- destructive migration.

## Final acceptance

The work is ready for the owner to perform final PR review.

Routine implementation choices, issue updates, documentation edits, and normal tests should not become unnecessary human interruptions.

---

# 11. Resuming work after interruption

A collaborator should be able to resume work from GitHub without reconstructing chat history.

At minimum, the active Issue or PR should answer:

```text
Where are we?
What is complete?
What is being worked on?
What is blocked?
Who acts next?
What exactly do they need to do?
What happens after that?
```

For long-running features, keep the PR `🧭 Current stage` and Issue state current.

---

# 12. Anti-patterns

Avoid:

## Assigning all AI work to the owner

This makes the owner's workload misleading.

Prefer:

```text
Assignee: none
Label: ready-for-agent
```

---

## Private-chat-only decisions

If a decision affects implementation or another collaborator, record it in GitHub/spec/ADR.

---

## Human as workflow secretary

Do not require a human to repeatedly tell the AI which ticket is next when dependencies and status are already represented in GitHub.

---

## AI-only tickets

A ticket must not assume access to AI-specific conversation context or tooling.

---

## Over-ticketing

Do not turn every code edit into its own Issue.

---

## Vague human gates

Bad:

```text
Please test this.
```

Good:

```text
Open the prototype in Power BI Desktop.
Refresh all.
Verify the SEQUENTIAL row ends as SPECIAL.MGR and conflict = false.
Comment PASS or provide the exact error/result.
```

---

# 13. Responsibility summary

| Activity | Feature owner | Human collaborator | AI agent |
|---|---:|---:|---:|
| Define priority | Owns | Advises | Advises |
| Clarify requirements | Approves | Contributes | Drives analysis |
| Draft spec | Reviews/approves | Contributes | Can draft |
| Architecture decision | Approves significant decisions | Contributes expertise | Proposes/trade-offs |
| Create tickets | Can | Can | Usually maintains |
| Implement ticket | Can | Can | Can |
| Run available automated tests | Can | Can | Should |
| Run inaccessible GUI/runtime test | Can | Can | Requests human gate |
| Maintain Issue/PR status | Can | Can | Should proactively |
| Review against spec | Can | Can | Should before final review |
| Final PR acceptance | Owns / delegated human | May review | Does not replace human approval |
| Merge | Human-controlled | If authorized | Only if explicitly authorized and policy permits |

---

# 14. Repository operating rule

The repo should behave as if **every collaborator has only GitHub and normal development tools**.

AI-assisted participants may move faster, but they must leave behind a clear, conventional engineering trail.

The durable workflow is:

```text
Issue
→ spec / ADR when needed
→ implementation ticket
→ branch / commits
→ tests / evidence
→ PR
→ human review
→ merge
```

AI sits inside that workflow; it does not replace it.
