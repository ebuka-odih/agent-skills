# CI rules and cross-domain jobs

## Workflow skeleton rules
- `on: pull_request` + `push: branches: [main]`; `workflow_dispatch` for manual runs.
- `concurrency: { group: ${{ github.workflow }}-${{ github.ref }}, cancel-in-progress: true }` for PRs.
- `timeout-minutes` on every job.
- Cache: `actions/setup-node` `cache:`, `astral-sh/setup-uv` `enable-cache:`, Composer cache dir via `actions/cache`.
- Services (Postgres/Redis) as job `services:` with health checks; never point CI at shared databases.

## Cross-domain jobs (add as separate jobs so failures are obvious)
| Job | Command | Owner |
|---|---|---|
| Dependency audit | `composer audit` · `uvx pip-audit` · `npm audit --omit=dev --audit-level=high` | security |
| Secret scan | `gitleaks/gitleaks-action@<sha>` (or `gitleaks detect --redact`) | security |
| PR title | collaboration `repo-setup/templates/pr-title-check.yml` | collaboration |
| Mutation (changed files) | `vendor/bin/pest --mutate --min=80` · `infection --git-diff-filter=AM --git-diff-base=origin/main` · `stryker run --incremental` | testing |
| Contract diff | `oasdiff breaking base.yaml openapi.yaml --fail-on ERR` | testing |
| AI evals (paths: prompts/, app/ai/**) | project's eval runner, offline mode | ai-engineering |

## Pinning actions
```yaml
- uses: actions/checkout@v4                      # first-party: major tag ok
- uses: gitleaks/gitleaks-action@<full-commit-sha> # v2.3.9 — third-party: pin SHA
```
Dependabot `package-ecosystem: github-actions` keeps pins updated.

## Debugging a red build
1. Read the first failing step's log, not the last.
2. Reproduce locally with the same command and versions.
3. Flaky → quarantine with an issue ID (testing `e2e-testing` flake policy); never "re-run until green".
