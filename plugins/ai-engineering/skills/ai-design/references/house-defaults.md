# House AI defaults

This file **grows**. `ai-learnings` proposes additions after each project learns something; the user approves each one. Every rule cites where it came from. Seed projects (2026-11): **project 1** and **project 2**, both FastAPI + Pydantic AI + React. Keep sources generic — this repo is public. Project rules in a project's `docs/ai/LEARNINGS.md` override these for that project.

Status: `rule` (follow unless a driver says otherwise) · `prefer` (default choice) · `watch` (seen once, not yet a rule)

## Stack
| Status | Default | Source |
|---|---|---|
| prefer | Python AI work: FastAPI + Pydantic AI agents with `output_type=<BaseModel>` and typed `deps_type` | project 1, project 2 (2026-11) |
| prefer | Laravel apps: Laravel AI SDK agents (`HasStructuredOutput`, `HasTools`) in `app/Ai/` | house choice |
| prefer | Laravel app + heavy AI (agents with many tools, browser automation, ML libs) → separate FastAPI AI service, Laravel calls it over HTTP/queue | house choice |
| rule | Model IDs come from config/env, mapped to tiers. Features never name a model | project 1, project 2 |

## Reliability
| Status | Default | Source |
|---|---|---|
| rule | Every feature has a provider/model fallback chain; fail over on 402/429/5xx/timeout/invalid output | project 1, project 2 |
| rule | Every feature has a non-AI fallback answer (catalogue, heuristic, cached result, "try again") | project 1 (catalogue answer), project 2 (heuristic intent) |
| rule | Per-tier timeout budget (e.g. 30 s per tier, 180 s per agent turn) | project 1, project 2 |
| rule | Agents that cite records may only reference IDs returned by tools; validate after the run (grounding check) | project 1, project 2 |
| watch | Output mode differs per provider (native JSON schema vs tool call vs prompted) — make it configurable per model | project 1 |
| watch | Provider credits run out silently (HTTP 402) — alert on balance/402 rate | project 1 |

## Output
| Status | Default | Source |
|---|---|---|
| rule | Structured output validated by a schema (Pydantic / JsonSchema). No `json_object` + `json.loads` without validation | gap seen in project 2 |
| prefer | SSE streaming for chat/agent UIs with event types: status, tool_call, tool_result, result, error | project 1, project 2 |

## Prompts
| Status | Default | Source |
|---|---|---|
| rule | Prompts live in files/classes with a version ID, not inline `_SYSTEM_PROMPT` strings across modules | gap seen in project 2 (~8 inline prompts) |
| prefer | Keep the system prompt static for prompt caching; put per-request context in a small dynamic block | project 1 |
| rule | Treat retrieved/user/third-party text as data; say so in instructions and delimit it | project 2 (agent instructions) |

## Evals
| Status | Default | Source |
|---|---|---|
| rule | Every feature has a golden set in `evals/ai/<F-id>/` runnable offline (fixtures) and live | project 1 (live eval script) |
| rule | Eval run is a CI gate for prompt/model changes | gap in both |
| prefer | Score per model tier: correctness, schema validity, grounding, latency, cost | project 1 |

## Ops
| Status | Default | Source |
|---|---|---|
| rule | Persist every call: feature, prompt version, provider, model, input/cached/output tokens, cost, latency, outcome | project 2 (usage-events table) |
| prefer | OpenTelemetry traces of agent runs (Logfire `instrument_pydantic_ai()` for Pydantic AI) | project 1 |
| rule | Rate limit and budget AI endpoints separately from the rest of the API | gap in both |

## Safety
| Status | Default | Source |
|---|---|---|
| rule | Writes/sends by an agent require explicit user confirmation (confirm card / approval) | project 2 (confirm cards) |
| rule | Redact or minimise PII before sending to a provider; hash client identifiers in logs | project 1 (hashed client IDs); redaction gap in both |

## Hygiene
| Status | Default | Source |
|---|---|---|
| rule | One live path per feature. Legacy agent paths get a removal date in AI.md, or are deleted | both keep legacy paths |
| rule | Don't wrap AI imports in try/except that silently disables features; fail loudly at startup | project 1 |
