---
name: ai-ops
description: Run AI features in production — log every model call (feature, prompt version, model, tokens, cost, latency, outcome), tracing, cost budgets and alerts, caching, rate limits, provider failover, and safely rolling out model or prompt changes. Use when the user asks "how much is the AI costing", "log LLM calls", "trace the agent", "the model is slow", "switch models", "upgrade to the new model", "provider is down", or when ai-design reaches areas 11–12.
---

# AI ops

## 1. Log every call — the usage row
| Field | Example |
|---|---|
| ts, request_id, tenant_id, user_hash | — |
| feature_id, prompt_version, schema_version | F1, v3, v2 |
| provider, model, tier, fallback_position | anthropic, claude-…, standard, 0 |
| input_tokens, cached_input_tokens, output_tokens, reasoning_tokens | — |
| cost_usd (priced per token class) | 0.0031 |
| latency_ms, steps, tool_calls | — |
| outcome | ok · invalid_output · fallback_model · fallback_non_ai · timeout · error · blocked |

Write it from the call wrapper / agent middleware (Laravel AI SDK events `AgentPrompted`, `AgentFailed`, `ProviderFailedOver`; Pydantic AI `result.usage()` + Logfire). Never log raw prompts containing PII unless policy allows.

## 2. Watch these numbers
[references/metrics.md](references/metrics.md) — cost per feature per day, p95 latency, invalid-output rate, fallback rate, 402/429 rate, eval score trend.

## 3. Control cost
Tier down where evals allow · prompt caching (static system prompt) · cache identical requests (hash of feature + version + input) · cap max tokens · batch offline work · budgets per feature with alerts at 50/80/100%.

## 4. Change models and prompts safely
[references/rollout.md](references/rollout.md): eval gate → shadow or flag → ramp → full; log before/after in AI.md.

## Hard rules
- No AI feature ships without the usage row and a budget alert.
- Failover is tested, not assumed: an eval run with the primary disabled.
- Provider credit balance / 402 errors alert someone.
