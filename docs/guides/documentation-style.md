# Documentation Style

Repository documentation should be easy to scan, understand, execute, pause, and resume. The default style is visual-first, task-first, and designed to reduce unnecessary cognitive load while preserving complete technical detail.

This guide applies to feature READMEs, implementation guides, handover documents, test instructions, troubleshooting guides, examples, and generated HTML documentation unless a more specific approved format is required.

## Core principles

1. **Lead with purpose and outcome.** State what the reader is doing, why it matters, and what successful completion looks like before background detail.
2. **Use progressive disclosure.** Present the minimum useful overview first, the task workflow second, and detailed reference material afterward.
3. **Prefer visual explanation for relationships.** Use diagrams, flows, timelines, before/after examples, comparison matrices, and small concept cards where they communicate structure more efficiently than prose.
4. **Keep visuals functional.** Visuals must explain a relationship, sequence, decision, state, or comparison. Avoid decorative visual noise.
5. **One action per step.** Procedural instructions should avoid requiring the reader to remember or execute several operations at once.
6. **Externalize memory.** Repeat exact names, commands, values, prerequisites, and expected results near the step where they are needed.
7. **Make decisions explicit.** Prefer clear defaults such as `Use AddColumn for verification` over unnecessary choice when one option is recommended.
8. **Design for interruption and re-entry.** A reader returning later should be able to identify what is complete, where they stopped, and what comes next.
9. **Separate doing from learning.** Do not force readers through the entire technical reference before they can execute the primary task.
10. **Preserve technical completeness.** Cognitive accessibility is not a reason to omit constraints, edge cases, validation rules, or implementation detail; place deeper detail in the appropriate layer.

## Three-layer documentation model

Use this structure by default for substantial technical documentation.

### Layer 1 — 30-second view

Give the reader a quick mental model before details.

Include, where relevant:

- purpose;
- desired outcome;
- one primary system/process diagram;
- major inputs and outputs;
- what success looks like;
- approximate scope or effort when useful;
- the clear starting point.

Keep this layer short enough to scan without scrolling through a manual-sized introduction.

### Layer 2 — Do the task

Provide the happy path as an executable workflow.

Each step should normally contain:

```text
STEP N OF M

ACTION
What to do now.

EXACT INPUT
The query name, filename, command, value, or code needed here.

EXPECTED RESULT
What the reader should see when the step succeeds.
```

Where practical, add:

- visible completion markers;
- checkpoints after meaningful phases;
- direct copy controls in HTML documentation;
- troubleshooting links beside the relevant failure point.

Do not make the reader search another section for code required by the current step.

### Layer 3 — Understand / reference

Place complete technical depth here, including:

- architecture;
- data contracts and schemas;
- terminology;
- evaluation semantics;
- edge cases;
- validation behaviour;
- ADR rationale;
- complete examples;
- troubleshooting reference;
- full code listings when appropriate.

This layer may be long because it is reference material, not the entry barrier to the task.

## Visual documentation rules

Use visuals when they explain one of the following:

- architecture or component relationships;
- execution sequence;
- hierarchy;
- state transition;
- decision path;
- before/after transformation;
- contrast between two behaviours;
- coverage or dependency relationships.

Good visual forms include:

- left-to-right process flows;
- top-down hierarchy diagrams;
- short timelines;
- comparison cards;
- small decision trees;
- input → transformation → output examples;
- coverage maps;
- compact matrices.

Avoid presenting too many concepts in one diagram. Prefer several small diagrams over one dense diagram.

### Colour semantics

When colour is available, use consistent meaning:

- **green** — success, completed, valid;
- **yellow/amber** — attention, caveat, review needed;
- **red** — failure, blocker, destructive risk;
- **blue/neutral** — information, structure, ordinary states.

Do not rely on colour alone to communicate meaning. Pair it with text, icons, labels, or shape.

### Icons

Icons may aid scanning when used consistently. Follow `docs/guides/github-communication.md` where its vocabulary applies.

Use one meaningful icon per heading or key status. Avoid decorative icon strings.

## Writing rules

- Prefer short paragraphs and descriptive headings.
- Front-load the important information in each section.
- Use concrete nouns and explicit verbs.
- Prefer examples before abstract explanation when the concept is difficult.
- Avoid unnecessary jargon; define unavoidable domain terms near first use.
- Do not use vague references such as `do the above` when the exact action can be repeated.
- Avoid long uninterrupted walls of prose.
- Use tables for genuine comparisons or structured contracts, not ordinary paragraphs.
- Use lists when items are independently scannable; do not turn every sentence into a bullet.
- Keep naming consistent with code, issues, specs, and UI labels.

## Procedural documentation

For workflows, setup instructions, runtime verification, or operational tasks:

- number steps;
- keep one primary action per step;
- show exact UI navigation when relevant;
- place code directly beside the step that uses it;
- name the destination before showing the content to paste there;
- show the expected result immediately after the action;
- add a checkpoint after a meaningful cluster of steps;
- state explicitly what not to do when an error is useful diagnostic evidence;
- make the final completion condition unambiguous.

Example:

```text
Step 3 of 8 — Create the engine query

Action
Create a Blank Query and rename it exactly:

Table.ApplyMarketMappingOverrides

Then open Advanced Editor and replace its contents with the code below.

Expected result
Power Query displays a function value and no error banner.
```

## Code and copyability

When documentation contains code or exact text the reader must reuse:

- use fenced code blocks in Markdown;
- use copy buttons in generated HTML where practical;
- keep the exact query/file/object name directly above the code;
- do not alter executable code merely to make the documentation visually compact;
- distinguish commands from illustrative pseudo-code;
- avoid splitting one copy/paste unit across multiple sections.

## Checkpoints and recovery

Substantial procedural guides should include explicit checkpoints such as:

```text
✅ Checkpoint
You should now have:
- two function queries;
- five test fixture queries;
- no unresolved Power Query errors.

Next: run the aggregate verification query.
```

A returning reader should not need to reconstruct state from memory.

For long workflows, use stable step numbering such as `Step 4 of 10` and preserve those numbers during minor edits where practical.

## Troubleshooting format

Prefer symptom-first troubleshooting:

```text
SYMPTOM
The query shows Expression.Error.

LIKELY CAUSE
One of the required query names does not match exactly.

ACTION
Compare the query name with the required name shown in Step 4.
```

For test or diagnostic workflows, do not instruct readers to improvise fixes before capturing evidence if the failure needs engineering investigation.

## Handover documentation

A handover should allow a technically competent reader with no prior project conversation to answer:

1. What problem does this solve?
2. What are the main components?
3. How does data move through the system?
4. What are the important rules and constraints?
5. What is implemented now?
6. What is not implemented or intentionally out of scope?
7. How do I run or verify it?
8. What does success look like?
9. What should I do when something fails?
10. Where is the deeper reference material?

Do not assume access to chat history as required context.

## README expectations for reusable features

Feature READMEs should normally include, in this order:

1. purpose;
2. visual or compact architecture overview;
3. public API / primary usage;
4. quick example;
5. important behaviour and constraints;
6. verification/testing status;
7. links to the approved spec, ADRs, tests, and examples;
8. deeper implementation notes where useful.

## Generated HTML documentation

When generating HTML guides, prefer:

- a visible `Start here` section;
- sticky or obvious navigation for long documents where practical;
- compact visual cards and process diagrams;
- generous whitespace;
- responsive layouts;
- copy buttons for reusable code;
- strong step numbering;
- clear success/warning/error callouts;
- no autoplay animation, flashing elements, or moving content;
- a clear split between workflow and reference material.

Interactive enhancements must not make the document unusable when JavaScript is unavailable unless interactivity is itself the purpose of the artifact.

## Accessibility and cognitive-load guardrails

- Do not rely exclusively on colour, iconography, hover states, or memory.
- Avoid unnecessary animation or interruption.
- Avoid visually dense dashboards masquerading as documentation.
- Keep layout and terminology predictable across sections.
- Prefer explicit state over implied state.
- Keep required context physically close to the action that depends on it.

## Precedence

This guide defines repository documentation defaults.

When an active Ask Matt / engineering skill, approved spec, accessibility requirement, or output-format requirement gives more specific instructions, follow the more specific instruction while preserving these principles where they do not conflict.
