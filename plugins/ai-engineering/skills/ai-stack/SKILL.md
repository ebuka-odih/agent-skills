---
name: ai-stack
description: Decide where AI code lives and how to build it — Laravel AI SDK inside a Laravel app, a FastAPI + Pydantic AI service, a split between them, or another stack — plus model tiers in config, provider fallback, streaming, queues and testing with fakes. Use when the user asks "Laravel AI SDK or Python", "how do I call the model from Laravel", "FastAPI AI service", "pydantic ai", "set up the AI layer", or when ai-design reaches area 2.
---

# AI stack

## 1. Pick the shape
| Situation | Shape |
|---|---|
| Python/FastAPI backend (both seed projects) | **Pydantic AI in the FastAPI app** → [references/fastapi-pydantic.md](references/fastapi-pydantic.md) |
| Laravel app; features are extraction, classification, summaries, chat, RAG over app data | **Laravel AI SDK in-app** → [references/laravel-ai-sdk.md](references/laravel-ai-sdk.md) |
| Laravel app + heavy agents, browser automation, Python-only libs, or a separate AI team | **Split**: Laravel ↔ FastAPI AI service → [references/split.md](references/split.md) |
| Anything else (Node, Go, Rails, Django, mobile-only) | [references/other-stacks.md](references/other-stacks.md) — ask the mapping questions |

Read the house defaults first: `../ai-design/references/house-defaults.md`.

## 2. Build the AI layer once, before the first feature
Every shape needs the same six pieces. Build them in this order:

| # | Piece | Done when |
|---|---|---|
| 1 | **Tier config** — `fast`/`standard`/`smart` → provider + model + fallback chain | Features reference tiers only; changing a model is a config change |
| 2 | **Call wrapper / middleware** — timeout, retry on invalid output, failover, logging | Every call goes through it; logs the `ai-ops` fields |
| 3 | **Prompt location** — files or agent classes with a version constant | No inline prompt strings in business code |
| 4 | **Schemas** — Pydantic models / JsonSchema per feature | All outputs validated |
| 5 | **Fakes for tests** — no real model calls in unit tests | CI blocks real requests |
| 6 | **Eval runner** — `evals/ai/<F-id>/` executable offline and live | `ai-evals` |

## 3. Record in AI.md
Shape and why · where code lives · tier table · prompt location + versioning · test fakes · eval runner command.

## Hard rules
- Provider SDK calls appear only inside the wrapper / agent classes, never in controllers or views.
- No real model calls in unit tests (`models.ALLOW_MODEL_REQUESTS = False` / `Agent::fake()->preventStrayPrompts()`).
- Long or multi-step AI work runs on a queue or streams; never block a request > 30 s.
