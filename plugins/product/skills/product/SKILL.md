---
name: product
description: Entry point for running a long project from idea to shipped — spec, architecture, plan, then one task at a time. Use when starting a new project or product, when the user says "new project", "let's build X", "where are we", "what's next", "resume the project", "what's left", or when a session starts in a project that has docs/spec/SPEC.md or docs/plan/PLAN.md. Routes to product-spec, system-design, project-plan and next-task.
---

# Product lifecycle (orchestrator)

Long projects fail when each session starts from zero. Three files carry the project between sessions:

| File | Answers | Lives for | Written by |
|---|---|---|---|
| `docs/spec/SPEC.md` | **What** must it do, for whom, and what not | Whole project | `product-spec` |
| `docs/architecture/ARCHITECTURE.md` | **How** is it built | Whole project | `system-design` |
| `docs/plan/PLAN.md` | **In what order**: milestones → tasks, each tied to requirements | Whole project, updated every task | `project-plan`, `next-task` |
| `.agent-log/GOAL.md` | **This task's** checkable outcome | One task | `goal-contract` (agent-ops) |

```
product/skills/
├── product/        ← you are here: decide which stage the project is in
├── product-spec/   interview the user → SPEC.md with numbered requirements R1, R2…
├── project-plan/   slice SPEC into milestones M1… and tasks T1… → PLAN.md
└── next-task/      pick the next ready task → GOAL.md → work → verify → update PLAN
```

## Pick the stage

Check which files exist, in this order. The first missing one is the stage.

| Missing | Stage | Do |
|---|---|---|
| SPEC.md | Define | `product-spec` |
| ARCHITECTURE.md | Design | `system-design` (architecture plugin) — it reads SPEC.md |
| `docs/ai/AI.md`, and SPEC has requirements a model would fulfil | AI design | `ai-design` (ai-engineering plugin) |
| PLAN.md | Plan | `project-plan` |
| — all exist | Build | `next-task` |

User asks "where are we" / "what's left" → run
`bash "${CLAUDE_PLUGIN_ROOT}/scripts/trace.sh" docs/spec/SPEC.md docs/plan/PLAN.md`
and report: active milestone, tasks done/total, next ready task, uncovered requirements, blockers.

## The trace — why this works incrementally

```
R3 (SPEC) ──covered by──▶ T7 (PLAN) ──goal──▶ GOAL.md C1..Cn ──evidence──▶ T7 [x] ──▶ R3 progress
```
Every task names the requirements it covers. Every goal names its task. Finishing a goal ticks the task; a requirement is met when all its tasks are done and its acceptance check passes.

## Hard rules
- Never start building without SPEC.md, unless the user explicitly says "skip the spec" — then write a 10-line SPEC.md from their request anyway.
- Spec changes go through `product-spec` change control, never silent edits.
- One task in progress at a time per agent.
- The plan is the source of truth for "what's next". Don't pick work from memory.
