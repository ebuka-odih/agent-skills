# Gates — what must pass, and which domain owns it

| Gate | Stage | Owner skill | Blocks when |
|---|---|---|---|
| Format, lint, types | PR | code-standards `writing-code` (`project-commands.sh`) | any error |
| Unit + feature tests | PR | code-standards `testing` | any failure |
| Extra techniques for the change | PR / nightly | testing `test-strategy` (`test-plan.sh`) | mutation score below threshold on changed files; contract breaking change |
| Dependency audit | PR + weekly | security `secrets-and-deps` | high/critical advisory without recorded exception |
| Secret scan | PR | security `secrets-and-deps` (gitleaks / trufflehog) | any finding |
| PR title / Conventional Commits | PR | collaboration `repo-setup` | invalid title |
| Review approval | PR | collaboration `code-review` | missing required approvals |
| AI evals | PR when prompts/models/schemas change | ai-engineering `ai-evals` | below feature threshold |
| Migrations safe | PR | architecture `data-design` (expand → migrate → contract) | destructive migration in same release as code that needs it |
| E2E smoke | staging | testing `e2e-testing` | any failure |
| Load (NFR) | nightly / pre-release | testing `non-functional` | k6 threshold failed |
| Health + SLO | production | devops `observability` | error rate / latency burn above alert threshold |
