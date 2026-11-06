---
status: draft
version: 0
updated: YYYY-MM-DD
---

# <Project name> — Spec

## Vision
<One sentence: who it's for and what it lets them do.>

## Problem
<What's painful today, and for whom.>

## Users
| Role | Goal | How often |
|---|---|---|

## Key journeys
- **J1** <role>: <step> → <step> → <step>
- **J2** …

## Requirements
- **R1** (must) <observable behavior>
  accept: <how a person or test checks it>
  journey: J1 · status: open

## Non-functional requirements
- **NFR1** (must) <measurable quality>
  accept: <check>
  status: open

## Non-goals (this release)
- <tempting thing we are not doing>

## Constraints
- Deadline · budget · platforms · compliance · integrations

## Success metrics
| Metric | Target | By |
|---|---|---|

## Profile
Which domains this project needs. The project loop routes only to these (and `loop.sh plugins` switches the others off for this repo, so their skills don't cost context).
- ui: yes        <!-- web/app screens → frontend -->
- ai: no         <!-- LLM / embeddings / ML features → ai-engineering -->
- seo: no        <!-- public pages that should rank → seo -->

## Risks & unknowns
Questions that could change the plan. Each gets a prototype before architecture (`product:prototype`).
- [ ] K1 · <question that could sink or reshape the project> · prototype: <slug>

## Open questions
| Question | Owner | Blocks |
|---|---|---|

## Change log
| Date | Version | IDs | Change | Why |
|---|---|---|---|---|
