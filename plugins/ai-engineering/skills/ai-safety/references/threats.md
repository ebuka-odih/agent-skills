# AI threat checklist

| Threat | Shows up when | Controls |
|---|---|---|
| **Direct prompt injection** | User types instructions to override behaviour | Delimit input; instructions state precedence; output schema limits what can come back; eval cases |
| **Indirect injection** | Model reads web pages, emails, PDFs, reviews, lead posts | Treat as data; strip/flag instruction-like text; no write tools in the same run without approval; summarise-then-act in separate calls |
| **Excessive agency** | Agent has broad write/send tools | Fewest tools; read-only by default; approval on writes; max steps; per-run budget |
| **Cross-tenant leak** | RAG index or tools shared across tenants | Tenant filter enforced in retrieval/tool code from deps; test that tenant A can't retrieve B's chunks |
| **Conversation hijack** | Chat continues by conversation ID | Check ownership before continuing (Laravel AI SDK `continue()` does not) |
| **PII exposure** | Personal data sent to provider or logged | Minimise fields; redact before send; region-pinned provider; logs hash IDs, no raw prompts with PII unless policy allows |
| **Hallucinated facts / IDs** | Answers cite records, prices, laws | Grounding check against tool results; "I don't know" path; citations required |
| **Harmful / off-brand output** | Public-facing generation | Constraint graders; moderation on input/output; human review for outbound messages |
| **Insecure output handling** | Output rendered as HTML or used in code/SQL | Escape; validate against schema; never `eval`/raw SQL |
| **Cost / DoS abuse** | Public endpoints, long inputs, agent loops | Input size limits; rate limits; spend caps; max steps/tokens; queue long work |
| **Supply chain** | Third-party prompts, MCP servers, tools | Pin versions; review tool descriptions; least-privilege tokens |
| **Model change regressions** | Provider updates or swaps model | Pin model versions where possible; eval gate on change |
