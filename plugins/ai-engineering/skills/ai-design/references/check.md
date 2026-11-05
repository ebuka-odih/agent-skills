# Check mode — does this AI change follow AI.md?

Read `docs/ai/AI.md` and the feature card(s) touched, then the diff. Report only real hits, each as `file:line · rule · fix`.

| # | Violation |
|---|---|
| 1 | New model call with no feature card / feature ID |
| 2 | Model name hard-coded instead of a tier from config |
| 3 | Prompt string inline in business code instead of the prompt location in AI.md |
| 4 | Free-text output parsed with string ops/regex where the card says structured |
| 5 | Prompt or model changed without an eval run (no updated eval results) |
| 6 | No timeout, or no fallback when the card names one |
| 7 | User/untrusted content concatenated into instructions without delimiting (see ai-safety) |
| 8 | Tool that writes/sends/deletes without the permission or approval the card requires |
| 9 | PII sent to a provider/region the card or AI.md forbids |
| 10 | Call not logged with feature ID, prompt version, model, tokens, cost, latency |

No hits → "Fits docs/ai/AI.md (checked 1–10)".
