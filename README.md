# agent-skills

My engineering standards, written as Claude Code skills. Every project I start installs them, so every project gets the same architecture discipline, code standards, security baseline, delivery pipeline, and team workflow.

## Install — once per machine, works in every project

```bash
claude plugin marketplace add ebuka-odih/agent-skills
claude plugin install product@ebuka-skills
claude plugin install agent-ops@ebuka-skills
claude plugin install architecture@ebuka-skills
claude plugin install ai-engineering@ebuka-skills
```

Working on the skills from a local clone? Run `claude plugin marketplace add ./` from the repo root instead.

Pull updates:

```bash
claude plugin marketplace update ebuka-skills
```

## How it's organised

Three levels. An agent reads only as deep as the task needs.

```
plugins/<domain>/                  level 1 — a domain, installed as one plugin
└── skills/<skill>/                level 2 — one job, triggers on its own
    ├── SKILL.md                   the workflow: steps, outputs, hard rules (short)
    ├── references/<topic>.md      level 3 — decision tables, loaded only when a step needs them
    └── templates/<file>.md        files the skill fills into the project
```

Each domain has an **orchestrator** skill that runs the whole flow and hands deep questions to its sibling skills. Each sibling also triggers alone — asking "JWT or sessions?" loads `auth-design` without the rest.

## The contract between domains

`architecture` writes `docs/architecture/ARCHITECTURE.md` in the project. Every other domain reads it first.

```mermaid
flowchart LR
  P[product] -->|writes| SP[(docs/spec/SPEC.md)]
  SP --> A
  A[architecture] -->|writes| D[(docs/architecture/ARCHITECTURE.md + ADRs)]
  SP --> PL[(docs/plan/PLAN.md)]
  D --> PL
  PL --> AO[agent-ops<br/>GOAL.md per task]
  SP --> AI[ai-engineering<br/>docs/ai/AI.md]
  D --> AI
  D --> C[code-standards]
  D --> S[security]
  D --> O[devops]
  D --> G[collaboration]
```

## Domains

| Plugin | Status | Skills |
|---|---|---|
| `product` | ✅ 0.1 | `product` (orchestrator) · `product-spec` · `project-plan` · `next-task` + session-start hook |
| `agent-ops` | ✅ 0.1 | `agent-ops` (orchestrator) · `goal-contract` · `verify-done` · `session-report` + logging and done-gate hooks |
| `ai-engineering` | ✅ 0.1 | `ai-design` (orchestrator) · `ai-feature` · `ai-stack` · `ai-evals` · `ai-safety` · `ai-ops` · `ai-learnings` + session-start drift hook |
| `architecture` | ✅ 0.2 | `system-design` (orchestrator) · `repo-and-services` · `auth-design` · `data-design` · `api-design` · `adr` |
| `code-standards` | planned | see [ROADMAP.md](ROADMAP.md) |
| `security` | planned | builds on [Cloudflare's security-audit skill](UPSTREAM.md) |
| `devops` | planned | |
| `collaboration` | planned | git workflow, commits, PRs, code review |

## What `architecture` does in a project

1. Asks ≤ 6 questions about drivers: scale, team, constraints, uptime, stack.
2. Walks 18 decision areas — repo shape, services, auth, data, APIs, async, infra, observability, security, testing, cost.
3. Writes `docs/architecture/ARCHITECTURE.md` with Mermaid diagrams, plus an ADR per costly decision.
4. Later, in **Check** mode, reviews a PR against the doc and flags boundary violations with file:line.

House defaults live in [`plugins/architecture/skills/system-design/references/defaults.md`](plugins/architecture/skills/system-design/references/defaults.md). Edit that file to change what gets recommended.

## What `product` does — long projects, one task at a time

| | Spec | Plan | Goal |
|---|---|---|---|
| File | `docs/spec/SPEC.md` | `docs/plan/PLAN.md` | `.agent-log/GOAL.md` |
| Answers | What, for whom, what not | In what order | This task's checkable outcome |
| Lives | Whole project | Whole project, updated every task | One task |

1. **`product-spec`** interviews you in 3 short rounds (problem & users → journeys → limits). Each question comes with a proposed answer. It writes requirements `R1…` with priority and an `accept:` check, plus non-goals. Changes go through a change log.
2. **`project-plan`** cuts the spec into vertical-slice milestones (each one demoable) and small tasks: `- [ ] T7 · Cancel booking · covers: R7 · depends: T5 · size: M`.
3. **`next-task`** picks the first ready task, opens a GOAL.md linked to it (`task: T7`, `covers: R7`), builds it, verifies it, then ticks the task and writes a progress-log line.
4. **Session-start hook** tells every new session the active milestone, the task in progress, the next ready task and blockers, so no session starts from zero.
5. **`trace.sh`** reports project status and requirements with no task, tasks covering nothing, and tasks pointing at unknown requirements.

## What `ai-engineering` does — AI features that keep learning

1. **`ai-design`** reads the house AI defaults, the project's `LEARNINGS.md`, SPEC.md and ARCHITECTURE.md *first*, then asks only what's missing (3 short rounds: the job, the context, the limits). It writes `docs/ai/AI.md`: features, where AI code lives, model tiers, prompts, evals, safety, cost.
2. **`ai-feature`** writes one card per feature: pattern (extraction, classification, RAG, agent…), output schema, tier, prompt version, fallback (including a non-AI fallback), eval set, budget.
3. **`ai-stack`** builds it: Laravel AI SDK in-app, FastAPI + Pydantic AI, a split between them, or a mapped "other" stack. The API names are checked against the official docs.
4. **`ai-evals` · `ai-safety` · `ai-ops`** cover golden sets that gate merges, prompt-injection and tool-permission controls, and a usage row plus a budget alert for every call.
5. **`ai-learnings`** is the loop. Eval results, incidents, model swaps and spec changes become `LEARNINGS.md` entries, each with an action. Lessons seen across projects are promoted (with your approval) into `house-defaults.md`, which every new project reads first. The first defaults were seeded from two real projects (FastAPI + Pydantic AI).
6. **Session-start hook** flags AI projects with no AI.md, spec changes since the AI design, features with no card or eval set, and lessons waiting to be promoted.

## What `agent-ops` does in a project — closing the "said done ≠ actually done" gap

```mermaid
flowchart LR
  P[User request] --> G[goal-contract<br/>.agent-log/GOAL.md<br/>criteria + checks]
  G --> W[Work]
  W -->|every tool call| L[(.agent-log/sessions/*.jsonl)]
  W --> V[verify-done<br/>fresh evidence per criterion]
  V --> S{Stop}
  S -->|criteria still open| B[done-gate hook blocks] --> V
  S -->|all PASS or BLOCKED| D[Honest final message]
  L --> R[session-report<br/>claims vs actions]
```

- **Logs everything** via hooks: prompts, every tool call (ok/failed, output excerpt, secrets redacted), final claims, gate blocks. One JSONL file per session in `.agent-log/sessions/` (gitignored by default).
- **Goal contract**: before work, the request is written down verbatim with checkable acceptance criteria.
- **Done-gate**: a Stop hook refuses to let the agent end its turn while criteria are unverified. It blocks once per attempt, so it can't loop. `AGENT_OPS_GATE=off` disables it.
- **Session report**: `bash plugins/agent-ops/scripts/report.sh .agent-log/sessions/<file>.jsonl` lists failures, files touched, and gap signals like "claims tests pass but none ran after the last edit".

## Testing the skills

Two layers. Both must pass before bumping a version.

| Layer | What it proves | Run |
|---|---|---|
| Script tests | Hooks log correctly, redact secrets, gate blocks/releases; plan parsing, ready logic, traceability | `bash plugins/agent-ops/tests/run.sh` · `bash plugins/product/tests/run.sh` · `bash plugins/ai-engineering/tests/run.sh` |
| Skill evals | A real agent with the plugin does what SKILL.md promises, compared with the same agent without it | `cd plugins/<domain> && claude plugin eval . --allow-tools Write Edit Bash --no-publish` |

### Latest results — 2026-11-05 (Claude Opus 5.5)

| Case | With plugin | Without | What it shows |
|---|---|---|---|
| ai-engineering · design-from-spec | **1.0** | 0.0 | AI.md + feature cards: tiers, non-AI fallbacks, eval gates, injection + grounding, owner review |
| ai-engineering · laravel-structured | **1.0** | 0.0 | Correct Laravel AI SDK structured agent, failover, `fake()` tests |
| ai-engineering · discovery-asks | **1.0** | 0.25 | Batched discovery questions with proposals before designing |
| ai-engineering · check-mode | 1.0 | 1.0 | Finds hard-coded model, inline prompt, unvalidated JSON, injection, no timeout |
| product · spec-from-brief | **1.0** | 0.0 | SPEC.md with numbered, checkable requirements and non-goals |
| product · plan-from-spec | **1.0** | 0.625 | Vertical milestones, tasks trace to every must requirement |
| product · next-task-picks-ready | **1.0** | 0.625 | Picks the ready task, links GOAL.md to T4/R3, marks it in progress |
| product · spec-asks-first | 1.0 | 1.0 | Interviews before writing a spec |
| agent-ops · goal-then-verify | **1.0** | 0.1 | Goal written before code, tests re-run, honest final status, session logged |
| architecture · design-new-project | **0.875** → fixed grader | 0.0 | Full ARCHITECTURE.md + ADRs following house defaults |
| architecture · check-mode | 1.0 | 1.0 | Catches planted boundary violations with file:line |
| architecture · microservices-pushback | 1.0 | 1.0 | Recommends modular monolith for a 2-person team |
| architecture · auth-question | 1.0 | 1.0 | Per-client auth advice (skill did not fire — model answered directly) |

Where both arms score 1.0, the base model already knows the general advice. Next step for those cases: test house-specific rules from `defaults.md` that a model without the plugin can't guess.

The first agent-ops run scored 0.3: logging worked, but the agent never chose to write a goal. That's the "said done ≠ goal" gap in practice. The fix was enforcement through hooks (`goal-nudge` + done-gate rule 2), not better wording.

Eval cases live in `plugins/<domain>/evals/<case>/` — `prompt.md` (the task) + `graders/*.md` (skill fired, files written, regex on contents, LLM-judged quality).

## Contributing / extending
See [CLAUDE.md](CLAUDE.md) for authoring rules, [ROADMAP.md](ROADMAP.md) for what's next, [UPSTREAM.md](UPSTREAM.md) for third-party skills we use or learn from.
