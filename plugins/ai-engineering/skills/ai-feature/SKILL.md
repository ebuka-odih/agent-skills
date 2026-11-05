---
name: ai-feature
description: Design one AI feature end to end — choose the pattern (extraction, classification, generation, summarisation, RAG, agent with tools, chat), define the input/output contract and schema, model tier, prompt and context, failure handling and fallback, eval set, latency and cost budget. Use when adding or changing a single AI capability, when the user says "add an AI feature", "use the LLM to…", "build a RAG", "build an agent", "chatbot", or when ai-design hands off a feature. Writes docs/ai/features/<F-id>-<slug>.md.
---

# AI feature card

One card per feature. Code for a feature isn't written until its card exists.

## Steps
1. **ID and driver.** Next free `F<n>` from AI.md. Link the requirement(s) it serves (`R…`) and the user's words.
2. **Is AI needed?** Try the deterministic option first (rules, SQL, search, regex). Record why it's not enough.
3. **Pick the pattern** — [references/patterns.md](references/patterns.md). One primary pattern per feature; compose only when needed.
4. **Contract** — [references/contract.md](references/contract.md): input fields, output schema, validation, what "invalid" means and what happens then.
5. **Context** — direct, RAG ([references/rag.md](references/rag.md)) or tools ([references/agents.md](references/agents.md)).
6. **Model tier** — `fast` / `standard` / `smart` from AI.md. Start one tier lower than you think; the eval decides.
7. **Prompt** — where it lives (per AI.md), version `v1`, data vs instructions separated.
8. **Failure plan** — timeout, retries on invalid output (max 2), provider fallback, **non-AI fallback** the user sees.
9. **Eval set** — hand off to `ai-evals`: ≥ 20 cases incl. edge and adversarial, threshold.
10. **Budget** — p95 latency, cost per call, monthly ceiling; execution mode (sync / stream / queue).
11. Fill [templates/feature.md](templates/feature.md) → `docs/ai/features/<F-id>-<slug>.md`; add the row to AI.md.

## Hard rules
- Output the app acts on is structured and validated. No regex over free text.
- Agents get the fewest tools that do the job; writes need approval (see `ai-safety`).
- If a wrong answer costs money, legal exposure or safety → human review step in the flow.
- Change the prompt or model → re-run the eval set and log before/after in AI.md.
