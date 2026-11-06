# Evolve — features, fixes and scaling on a running project

Every change enters through the files, so it gets the same gates as the first build.

| Input | First skill | Then |
|---|---|---|
| New feature request | `product:product-spec` change mode → new R… (+ K… if risky) | prototype if K…; ADR if it changes the architecture; `project-plan` adds tasks → build loop |
| Bug report | `mattpocock-skills:diagnosing-bugs` or `code-standards` → failing test first | a task `fix: …` covering the broken R…; build loop |
| Production incident | `devops:release-and-rollback` incident runbook | postmortem → SPEC/ADR changes → tasks |
| Metric/SEO/AI signal (traffic drop, eval regression, slow pages) | `seo:search-console`, `ai-engineering:ai-learnings`, `seo:page-speed` | finding → requirement or NFR change → tasks |
| Scaling (load, data growth, team growth) | `architecture:system-design` Check mode + `testing:non-functional` load test | ADR → tasks in a "scale" milestone |
| Dependency/security updates | `security:secrets-and-deps` | chore tasks, batched per milestone |

## Rules
- No change without a requirement ID or a bug linked to one.
- Fixes start with a failing test that reproduces the bug.
- After each milestone: re-run BASELINE checks (existing projects) and record the delta in LOOP.md.
