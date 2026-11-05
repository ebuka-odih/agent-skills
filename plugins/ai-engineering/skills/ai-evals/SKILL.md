---
name: ai-evals
description: Build and run evals for AI features — golden case sets per feature in evals/ai/<F-id>/, graders (schema, exact match, grounding, LLM judge, human), thresholds that gate merges on prompt or model changes, offline fixture replay vs live runs, and production sampling. Use when the user asks "how do I test the AI", "is the prompt better", "eval", "golden set", "regression", before changing a prompt or model, or when ai-feature hands off step 9.
---

# AI evals

An AI feature without evals is a demo. Evals turn "seems better" into a number.

## Steps
1. **Collect cases** — [references/cases.md](references/cases.md). ≥ 20 per feature to start: typical, edge, adversarial, and every production bug ever reported.
2. **Pick graders** — [references/graders.md](references/graders.md). Cheapest that works: schema → exact/field match → grounding check → LLM judge → human.
3. **Write the runner** — reads `evals/ai/<F-id>/cases.jsonl`, runs the feature through the same code path as production, writes `results/<date>-<model>-<prompt_version>.json` with per-case pass/fail, latency, tokens, cost.
4. **Two modes** — `offline` (recorded responses/fixtures, free, runs in CI on every PR) and `live` (real models, run on prompt/model/schema change and nightly).
5. **Set thresholds** in the feature card: e.g. schema 100%, field accuracy ≥ 90%, grounding 100%, p95 < 4 s, cost/call ≤ $0.005.
6. **Gate** — CI fails if a PR changes `prompts/`, schemas or tier config and the live eval wasn't run or is below threshold.
7. **Record** — before → after in the feature card and AI.md change table; surprises go to `ai-learnings`.

Template: [templates/cases.jsonl](templates/cases.jsonl)

## Hard rules
- Never tune a prompt without the eval set open. Tune → run → compare.
- Score every model tier you might fall back to, not just the primary.
- Production failures become eval cases within the same fix.
- An LLM judge needs its own check: ≥ 10 cases hand-labelled, judge agrees ≥ 90%.
