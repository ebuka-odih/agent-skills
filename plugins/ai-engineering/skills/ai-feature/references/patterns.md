# Choosing the pattern

| Job | Pattern | Output | Typical tier | Watch out for |
|---|---|---|---|---|
| Pull fields out of text/docs/images | **Extraction** | Schema with nullable fields + confidence | standard | Hallucinated values for missing fields — allow `null` |
| Put input in a bucket / yes-no / score | **Classification** | Enum or score + probability | fast | Calibrate threshold on eval set; "unsure" bucket |
| Shorten or restate | **Summarisation** | Text (+ cited source spans) | fast/standard | Dropped facts; length limits |
| Write new content (drafts, copy) | **Generation** | Text or structured sections | standard | Tone/brand rules; human edit before send |
| Answer from private/changing knowledge | **RAG** | Answer + citations (IDs) | standard | Retrieval quality is the real bottleneck — eval retrieval separately |
| Decide and take steps using functions | **Agent with tools** | Structured final answer + tool trace | smart | Loops, cost, unsafe actions — max steps, approvals |
| Multi-turn assistant | **Chat** (agent + memory) | Streamed text + structured events | standard | Memory growth — trim/summarise; ownership checks on conversations |
| Rank or match items | **Embeddings + rerank** | Ordered IDs + scores | — | Embedding model change = re-index |
| Speech, images | **Media** (STT/TTS/vision/image gen) | Files + metadata | — | Size limits, cost per second/image |

## Composition rules
- Classify/route with `fast` before invoking a `smart` agent.
- Extraction → deterministic validation → (optional) LLM judge on low-confidence only.
- Prefer a fixed pipeline (A → B → C) over an agent when the steps are known. Agents are for when the path varies by input.
