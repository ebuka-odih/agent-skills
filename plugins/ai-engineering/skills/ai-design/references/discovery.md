# AI discovery questions

Answer from SPEC.md, ARCHITECTURE.md, LEARNINGS.md and code first. Ask only the gaps, one batch per round, each with a proposed answer the developer can accept.

## Round 1 — the job (per candidate feature)
| # | Ask | Why it matters | Typical proposal |
|---|---|---|---|
| 1 | What does the model do, in one verb? (extract, classify, summarise, answer, generate, decide, act) | Picks the pattern | "Extract fields from uploaded invoices" |
| 2 | Who sees the output, and what do they do with it? | Free text vs structured; human review | "Stored, then shown for confirmation" |
| 3 | What does a wrong answer cost? (annoying / money / legal / safety) | Review gate, model tier, eval threshold | "Annoying — user can edit" |
| 4 | Could rules, search or SQL do it instead? | Avoids needless AI | "No — layouts vary too much" |
| 5 | Is there an existing example set (real inputs + right answers)? | Eval set from day 1 | "We have ~50 past cases" |

## Round 2 — the context
| # | Ask | Proposal |
|---|---|---|
| 6 | What information must the model see? Where does it live? (DB rows, files, web, user chat) | "Row + the attached PDF" |
| 7 | Does it need private or changing knowledge? → RAG / tools | "Yes, our help docs" |
| 8 | Does it need to *act* (write data, call APIs, send messages)? → tools + permissions | "Read-only for v1" |
| 9 | Is it multi-turn (chat) or one-shot? Memory needed? | "One-shot" |
| 10 | Personal or sensitive data in inputs? Which region must data stay in? | "Names + emails, EU" |

## Round 3 — limits
| # | Ask | Proposal |
|---|---|---|
| 11 | Latency the user will accept? Sync, streaming, or background job? | "Background job, notify when done" |
| 12 | Volume: calls/day now and in 12 months | "~500/day" |
| 13 | Cost ceiling per call or per month | "≤ $0.01 per call, $150/month" |
| 14 | Provider constraints: preferred, banned, self-hosted, BYO key per tenant | "Anthropic primary, OpenAI fallback" |
| 15 | Stack: Laravel AI SDK in-app, FastAPI + Pydantic service, or other? | House default (see `ai-stack`) |

## Rules
- Batch questions; max 3 rounds; leftovers → Open questions with owner.
- Turn vague answers into numbers ("fast" → "p95 < 3 s — right?").
- Record each answer with its source: `(SPEC R7)`, `(LEARNINGS 2026-10-02)`, `(developer)`, `(default)`.
