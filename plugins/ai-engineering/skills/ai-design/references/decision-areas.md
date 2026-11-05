# AI decision areas

Every area gets a decision, a driver and a status in AI.md. "N/A — why" is allowed; silence isn't.

| # | Area | Decide | Skill |
|---|---|---|---|
| 1 | Feature inventory | Each AI feature: ID `F1…`, requirement(s) it serves, pattern, owner | `ai-feature` |
| 2 | Where AI code lives | In the main app (Laravel AI SDK), a Python AI service (FastAPI + Pydantic AI), or both — and the contract between them | `ai-stack` |
| 3 | Providers and model tiers | Primary + fallback provider; tiers `fast` / `standard` / `smart` mapped to concrete models in config, never hard-coded in features | `ai-stack`, `ai-ops` |
| 4 | Output contracts | Schema per feature (Pydantic model / JSON schema); validation + retry on invalid output | `ai-feature` |
| 5 | Prompts | Where prompts live (versioned files/classes, not inline strings), version IDs, who can change them | `ai-feature` |
| 6 | Context and knowledge | Direct context vs RAG vs tools; embedding model, chunking, store (pgvector default), refresh | `ai-feature` (rag.md) |
| 7 | Agents and tools | Which features act; tool list, permission level, approval gates, max steps | `ai-feature` (agents.md), `ai-safety` |
| 8 | Evals | Golden set per feature, graders, merge threshold, production sampling | `ai-evals` |
| 9 | Safety and privacy | Injection defense, PII handling, data residency, moderation, human review | `ai-safety` |
| 10 | Execution | Sync / streaming / queued per feature; timeouts; idempotency of AI jobs | `ai-stack` |
| 11 | Observability and cost | Per-call log fields, cost per feature, budgets and alerts, caching | `ai-ops` |
| 12 | Change management | How model/prompt changes are rolled out (eval gate, shadow, flag) | `ai-ops`, `ai-evals` |
| 13 | Learning loop | Where lessons go; when they become house defaults | `ai-learnings` |
