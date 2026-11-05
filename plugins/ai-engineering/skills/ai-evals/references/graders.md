# Graders

| Grader | Checks | Cost | Use for |
|---|---|---|---|
| **schema** | Output validates against the schema | free | every feature, threshold 100% |
| **fields** | Expected fields equal (normalised: case, whitespace, number format) | free | extraction, classification |
| **grounding** | Every referenced ID/citation exists in tool results / retrieved chunks | free | RAG, agents |
| **retrieval** | Expected doc IDs in top-k | free | RAG (run before answer quality) |
| **constraint** | Rules: length, banned words, required sections, language | free | generation |
| **tool trace** | Called / didn't call tool X; ≤ N steps; no write without approval | free | agents |
| **LLM judge** | Rubric with PASS/FAIL criteria, majority of 3 votes | $ | tone, helpfulness, summary faithfulness |
| **pairwise** | Judge picks better of A/B (old vs new prompt) | $ | prompt/model comparisons |
| **human** | Reviewer labels a sample | $$ | calibrating judges, high-stakes features |

## Judge rubric rules
- Binary criteria ("cites at least one source", "no invented prices"), not 1–10 scales.
- Give the judge the input, the output and the reference — never only the output.
- Use a different (or stronger) model than the one being judged when possible.

## Report per run
pass rate per grader · failures listed by case ID · p50/p95 latency · tokens · cost · model + prompt version.
