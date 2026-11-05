---
type: llm
weight: 3
---
PASS if the final message asks a batch of discovery questions before committing to a design, and the questions cover at least FOUR of:
- what knowledge the answers must come from (docs, tickets, DB) and how it changes
- what a wrong answer costs / when a human must take over
- whether the assistant must take actions (refunds, account changes) or only answer
- personal data in conversations / data residency / provider constraints
- volume, latency or cost limits
- whether an example set of real questions + correct answers exists (for evals)
AND most questions come with a proposed default answer (e.g. "I'd assume…", "default:").

FAIL if it jumps straight to a full implementation without asking, or asks only 1–2 questions.
