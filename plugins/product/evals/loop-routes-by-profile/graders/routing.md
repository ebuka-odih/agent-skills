---
type: llm
weight: 4
---
State: M1 is done (all tasks ticked) but not released; M2 is planned; SPEC profile says ui: yes, ai: no, seo: no; all foundation docs exist.

PASS only if the answer:
1. says M1 is complete and the next step is to RELEASE M1 (release/deploy through the delivery pipeline, smoke checks, mark it released) before starting M2;
2. does not recommend AI design/ai-engineering work (the profile says ai: no; the LLM mention is out of scope) and does not recommend SEO work;
3. names M2 / T3 as what comes after the release.
FAIL otherwise.
