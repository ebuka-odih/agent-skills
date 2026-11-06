---
name: project-plan
description: Turn docs/spec/SPEC.md (and ARCHITECTURE.md if present) into docs/plan/PLAN.md — milestones that each ship something usable, broken into small tasks that name the requirements they cover and their dependencies. Also re-syncs the plan after spec changes. Use when the user says "plan the project", "break this down", "roadmap", "milestones", "create tasks", after the spec is agreed, or after a spec change.
---

# Project plan

## Modes
| Situation | Mode |
|---|---|
| SPEC.md agreed, no PLAN.md | **Create** → steps 1–5 |
| SPEC.md changed (new version in its change log) | **Re-sync** → step 6 |
| User asks to reorder or re-scope | **Re-plan**: edit, log it under Plan changes, re-run the trace |

## 1. Read inputs
SPEC.md (requirements, journeys, non-goals, constraints). ARCHITECTURE.md if present (modules, setup work). No agreed SPEC.md → stop and run `product-spec`.

## 2. Cut milestones — vertical slices
Follow [references/slicing.md](references/slicing.md). M1 is the thinnest end-to-end path of the most important journey, deployable and demoable. Each later milestone adds whole journeys, not layers.

## 3. Break milestones into tasks
Each task, on one line, in [templates/PLAN.md](templates/PLAN.md) format:
```
- [ ] T7 · Cancel booking endpoint + refund · covers: R7 · depends: T5 · size: M
```
- Size S (< 2 h agent work) or M (half a day). L → split it.
- Every task covers ≥ 1 requirement, **or** is marked `covers: setup` / `covers: NFR…`.
- `depends:` lists only tasks that must be `[x]` first.

## 4. Check coverage
Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/trace.sh" docs/spec/SPEC.md docs/plan/PLAN.md`.
Every `must` requirement is covered by a task in some milestone, or listed under "Deferred" with a reason. Fix gaps before showing the user.

## 5. Show and confirm
Show: milestones with goal + task count, the first 3 ready tasks, deferred requirements. Set the first milestone `status: active`.

## 6. Re-sync after a spec change
Read the spec's newest change-log rows. For each ID: add tasks (add), re-open or add rework tasks (change), mark tasks `[-] dropped` (drop). Log under Plan changes. Re-run the trace.

## Status markers
`[ ]` todo · `[~]` in progress · `[x]` done · `[!]` blocked (reason after `—`) · `[-]` dropped
Details: [references/status.md](references/status.md).

## Hard rules
- Task IDs are permanent; never renumber.
- Only `next-task` and `verify-done` change a task to `[x]`, and only with evidence.
- A milestone is done when all its tasks are `[x]` or `[-]` **and** its demo check passes.

Milestone status moves `planned → active → done → released`; `loop.sh` uses it to send a done milestone to release.

## Hand-off (project loop)
Skills share work through files, not memory. When this skill's output is written, log it and let the loop pick the next step:
`bash <product plugin>/scripts/loop.sh log foundation/plan "PLAN.md"` then `loop.sh next` (skill `product:project-loop`). If an input file this skill needs is missing, name it and the skill that writes it instead of guessing.
