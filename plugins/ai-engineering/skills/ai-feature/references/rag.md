# RAG

Use when answers depend on knowledge the model doesn't have or that changes.

## Decide
| Decision | Default | Change when |
|---|---|---|
| Store | pgvector in the main Postgres | > ~5M chunks or heavy filtering → dedicated vector DB; provider-hosted file search when you don't own the docs pipeline |
| Embedding model | one model per index, recorded in AI.md | changing it = full re-embed; plan it as a migration |
| Chunking | by structure (headings, paragraphs), 300–800 tokens, 10–15% overlap | records (rows, places, leads) → one chunk per record + its key fields |
| Retrieval | hybrid: keyword/filters + vector, top 20 → rerank → top 5 | small corpora: vector alone may be fine — measure |
| Freshness | re-embed on write (queue job) | bulk sources → nightly batch |
| Citations | answer must cite chunk/record IDs | — always |

## Evaluate retrieval on its own
Build 20+ question → expected-document pairs. Measure recall@k before tuning prompts. Most "the AI is wrong" bugs are retrieval bugs.

## Stack notes
- Laravel AI SDK: `Embeddings::for([...])->generate()`, `$table->vector('embedding', dimensions: 1536)`, `whereVectorSimilarTo(...)`, agent tool `SimilaritySearch::usingModel(Model::class, 'embedding')`, reranking `Reranking::of($docs)->rerank($query)`; provider stores via `Stores::create()` + `FileSearch` tool.
- Pydantic AI: retrieval as a tool (`@agent.tool` that queries pgvector and returns IDs + snippets), or retrieve first and pass results in the prompt for fixed pipelines.
- Avoid comparing vectors in Python over a full table — push similarity to the database index.
