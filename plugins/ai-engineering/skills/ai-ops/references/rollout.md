# Rolling out a model or prompt change

1. **Eval** — run the live eval for the feature on old and new. New must meet every threshold and not regress any grader by > 2 points. Check cost and p95 too.
2. **Shadow** (high-traffic or high-stakes) — run new alongside old on real traffic, store both outputs, users see old. Compare for 1–3 days.
3. **Flag** — feature flag by tenant or percentage: 5% → 25% → 100%, watching invalid-output, fallback and feedback metrics.
4. **Record** — AI.md "Model and prompt changes" row + feature card Changes: date, change, eval before → after, decision.
5. **Rollback** — the old prompt version and tier mapping stay in config until the new one has run at 100% for a week.

Provider-forced changes (model deprecations): schedule the eval as soon as the deprecation is announced; don't wait for the cutoff.
