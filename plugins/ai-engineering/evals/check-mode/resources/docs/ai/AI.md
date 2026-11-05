---
updated: 2026-11-01
spec_version: 2
---

# MenuMate — AI architecture

## Features
| ID | Feature | Serves | Pattern | Tier | Runs | Card | Status |
|---|---|---|---|---|---|---|---|
| F1 | Menu extraction | R1 | extraction | standard | queued | features/F1-menu-extraction.md | live |
| F3 | Review summaries | R3 | summarisation | fast | queued | features/F3-review-summaries.md | building |

## Where AI code lives
FastAPI backend, Pydantic AI agents under `app/ai/features/<feature>/`. All calls go through `app/ai/calls.py:run_feature()` which applies timeout, failover and usage logging.

## Providers and model tiers
Tiers in `app/ai/tiers.py` from env: fast / standard / smart. Features reference tiers only — never model names.

## Prompts
Files in `app/ai/prompts/<feature>.v<n>.md`, loaded with `load_prompt(feature, version)`. No inline prompt strings.

## Output
Every feature uses `output_type=<Pydantic model>`. No `json.loads` on model output.

## Safety and privacy
Scraped reviews are untrusted: passed inside `<reviews>` delimiters, never concatenated into instructions.

## Execution
Every call has a timeout (≤ 30 s) via `run_feature()`.
