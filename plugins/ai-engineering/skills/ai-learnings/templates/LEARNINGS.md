# <Project> — AI learnings

Newest first. One lesson per entry. Fields: trigger · feature · evidence · lesson · action · scope · status.

## L1 — YYYY-MM-DD · <short title>
- **trigger:** eval | incident | model-change | spec-change | review | cost
- **feature:** F<n> (serves R<n>)
- **evidence:** <eval results file / incident link / log query and result>
- **lesson:** <what we now believe, one sentence>
- **action:** <card change / new eval case f1-0xx / config change / AI.md update / no change — why>
- **scope:** project | house-candidate
- **status:** applied | hunch | superseded by L<n> | promoted: YYYY-MM-DD

<!-- example
## L3 — 2026-11-04 · Gemini needs native JSON-schema output mode
- trigger: eval
- feature: F1 chat assistant (serves R2)
- evidence: evals/ai/F1/results/2026-11-04-gemini-v4.json — 6/18 invalid with tool-call output, 0/18 with native
- lesson: output mode must be configurable per model; tool-call mode fails on this provider
- action: output_mode_overrides added to config; case f1-019 added
- scope: house-candidate
- status: applied
-->
