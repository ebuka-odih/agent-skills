---
name: ai-design
description: Entry point for designing how AI is built into a project — which features use a model, what pattern each uses (extraction, classification, generation, RAG, agent with tools, chat), the stack (FastAPI + Pydantic, Laravel AI SDK, or other), evals, safety, cost and observability. Use when a project uses or will use LLMs, embeddings, vision or speech; when the user says "add AI", "integrate an LLM", "AI architecture", "how should the AI part work", "RAG", "agent", "chatbot"; or when SPEC.md has requirements a model would fulfil. Writes docs/ai/AI.md and one card per AI feature.
---

# AI design (orchestrator)

AI features fail in ways normal code doesn't: wrong-but-confident output, drift when models change, cost spikes, prompt injection. This skill makes those decisions explicit and keeps them up to date as the project learns.

```
ai-engineering/skills/
├── ai-design/     ← you are here: discovery, AI.md, routing, review
├── ai-feature/    one feature: pattern, input/output contract, model tier, prompt, fallback
├── ai-stack/      build it: Laravel AI SDK · FastAPI + Pydantic AI · split · other stacks
├── ai-evals/      golden cases, graders, thresholds that gate merges
├── ai-safety/     injection, tool permissions, PII, human review
├── ai-ops/        logging every call, cost budgets, caching, failover, model upgrades
└── ai-learnings/  record what each project learns; promote lessons to house defaults
```

**Outputs in the project:** `docs/ai/AI.md` (from [templates/AI.md](templates/AI.md)) · `docs/ai/features/<F-id>-<slug>.md` · `docs/ai/LEARNINGS.md` · `evals/ai/<F-id>/`

## 1. Pick the mode
| Situation | Mode |
|---|---|
| No `docs/ai/AI.md` | **Design** → steps 2–5 |
| AI code exists, no AI.md | **Recover**: inventory every model call in code first (grep providers/SDKs), then steps 2–5 |
| AI.md exists, new AI requirement or feature | **Add**: `ai-feature`, then update AI.md feature table |
| Reviewing a change that touches AI | **Check**: [references/check.md](references/check.md) |
| An eval ran, an incident happened, a model changed | **Learn**: `ai-learnings` |

## 2. Load what's already known — in this order
1. House defaults: [references/house-defaults.md](references/house-defaults.md) (grows over time via `ai-learnings`).
2. `docs/ai/LEARNINGS.md` in this project, if any.
3. `docs/spec/SPEC.md` — mark every requirement a model would fulfil (`R…` → candidate AI feature).
4. `docs/architecture/ARCHITECTURE.md` — stack, services, data stores, tenancy.

## 3. Ask only what's missing
Follow [references/discovery.md](references/discovery.md). Answer from step 2 first; ask the rest in one batch per round, each with a proposed answer. Never ask what the spec already says.

## 4. Decide, area by area
Walk [references/decision-areas.md](references/decision-areas.md). For each area: decision · driver (requirement ID, learning, or house default) · status (Decided / Default / Open). Hand off:

| Area | Skill |
|---|---|
| Each AI feature's design | `ai-feature` (one card per feature) |
| Where AI code lives, SDK, service split | `ai-stack` |
| Quality bar and regression gates | `ai-evals` |
| Threats and guardrails | `ai-safety` |
| Logging, cost, caching, failover | `ai-ops` |

## 5. Write and present
1. Fill `docs/ai/AI.md`. Every feature row names its non-AI fallback and eval gate, and links its card. Open items go in Open questions.
2. Add to the project's CLAUDE.md: `AI: docs/ai/AI.md — read before adding or changing any model call.`
3. If the project has `docs/plan/PLAN.md`: propose tasks per feature (contract → eval set → implementation → ops), each `covers:` its requirement.
4. Tell the user: feature table (feature · pattern · model tier · stack) → top risks → Open questions.

## Hard rules
- **No model call without a feature card**: contract, eval set, fallback, owner.
- **Structured output by default.** Free text only when the output is shown to a human as-is.
- **Evals before prompt tuning.** No eval set → no "it works".
- **Deterministic code first.** If a rule, regex or SQL query solves it reliably, don't use a model.
- **Every call is logged** with feature ID, prompt version, model, tokens, cost, latency, outcome.

## Hand-off (project loop)
Skills share work through files, not memory. When this skill's output is written, log it and let the loop pick the next step:
`bash <product plugin>/scripts/loop.sh log foundation/design "AI.md"` then `loop.sh next` (skill `product:project-loop`). If an input file this skill needs is missing, name it and the skill that writes it instead of guessing.
