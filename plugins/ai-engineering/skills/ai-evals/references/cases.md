# Building the case set

## Sources, in order of value
1. Real production inputs (anonymised) with corrected outputs
2. Bug reports and support tickets → one case each
3. Spec acceptance lines (`accept:` in SPEC.md) → one case each
4. Synthesised edge cases (empty input, huge input, wrong language, missing fields, contradictory data)
5. Adversarial: prompt injection in inputs, requests outside scope, attempts to get other tenants' data

## Mix for a first set of ~20–40
| Kind | Share |
|---|---|
| Typical | 50% |
| Edge | 30% |
| Adversarial / safety | 20% |

## Case format (`cases.jsonl`, one per line)
```json
{"id":"f1-007","kind":"edge","input":{"text":"Invoice #44 … total: —"},"expect":{"total_cents":null,"missing":["total_cents"]},"graders":["schema","fields"],"source":"bug #212"}
```
- `expect` holds only what you can check; leave free-text quality to a judge rubric.
- Never delete a case; mark `"retired": true` with a reason.
