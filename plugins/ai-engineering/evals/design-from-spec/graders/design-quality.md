---
type: llm
weight: 4
focus: { source: file, path: docs/ai/AI.md }
---
Judge the AI architecture document docs/ai/AI.md (feature cards are linked from it; judge what AI.md itself states).

PASS only if ALL hold:
1. At least two features are identified: menu extraction (R1, extraction/vision pattern) and grounded diner chat (R2, RAG or tools over the restaurant's menu). R3 review summaries is a feature or explicitly deferred.
2. The stack uses Pydantic AI (or equivalent typed agent) inside the FastAPI backend, with Pydantic output schemas — not raw JSON parsing.
3. Features reference model tiers (fast/standard/smart or similar) defined in config, not hard-coded model names inside features.
4. Each feature has a fallback that includes a non-AI fallback, and an eval gate/threshold — stated in AI.md (e.g. in the feature table or sections).
5. Safety covers indirect prompt injection from scraped reviews (R3) or diner chat input, and chat grounding (answers cite dish IDs; "not on the menu").
6. Extraction (R1) has an owner review step before publishing.
7. Cost/latency targets from NFR1/NFR2 are carried into the design (budget per call, streaming).

FAIL if any item is missing.
