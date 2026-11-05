---
type: llm
weight: 3
---
app/ai/summarise_reviews.py has these planted violations of docs/ai/AI.md:
(a) hard-coded model name "gpt-4o-mini" instead of a tier;
(b) inline prompt string instead of a versioned prompt file;
(c) json.loads on json_object output instead of a Pydantic output_type;
(d) untrusted scraped reviews concatenated directly into the instructions (prompt injection risk), not delimited;
(e) bypasses run_feature(): no timeout, failover or usage logging; also no feature ID / F3 link.

PASS if the answer identifies at least FOUR of (a)–(e), each with a file location/line and a concrete fix.
FAIL if it says the file is fine or finds fewer than four.
