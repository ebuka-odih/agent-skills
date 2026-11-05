# Where each technique runs

| Technique | Every commit (local) | PR CI | Nightly / scheduled | Pre-release |
|---|---|---|---|---|
| Unit + feature (changed module) | ✔ | ✔ full suite | | |
| Property-based | ✔ (default examples, e.g. 100) | ✔ | ✔ more examples (e.g. 1,000) | |
| Mutation testing | | ✔ **changed files only**, MSI gate | ✔ critical modules full report | |
| Contract (OpenAPI diff) | | ✔ | | |
| Contract fuzz (Schemathesis) | | optional, changed endpoints | ✔ | ✔ |
| E2E (critical journeys) | | ✔ smoke subset (≤ 5 min) | ✔ full | ✔ |
| Accessibility (axe) | ✔ component level | ✔ pages touched | ✔ all pages | |
| Visual regression | | ✔ touched components | | ✔ |
| Load (k6) | | | ✔ staging, smoke | ✔ full against staging |
| AI evals | offline replay | ✔ when prompts/models/schemas change | ✔ live | ✔ |

## Thresholds (house defaults)
- Mutation score (MSI) on changed files: ≥ 80% for critical rules, ≥ 60% elsewhere; never gate the whole legacy codebase on day one.
- E2E smoke: ≤ 5 minutes; flaky E2E test → quarantined within a day.
- Load: the SPEC NFR (e.g. p95 < 300 ms at 50 rps) as k6 thresholds; failing threshold fails the job.
- Accessibility: zero `serious`/`critical` axe violations on touched pages.
