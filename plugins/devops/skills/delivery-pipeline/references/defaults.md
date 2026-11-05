# DevOps house defaults

| Topic | Default |
|---|---|
| CI | GitHub Actions; required checks on `main`; actions pinned to commit SHA; `permissions: contents: read` by default |
| Artifact | Docker image tagged with git SHA, deployed by digest |
| Hosting | Small apps: PaaS / Dokploy / Laravel Cloud / Forge; scale-up: containers on managed platform. Record the choice in ARCHITECTURE.md §11 |
| Environments | local · preview (optional) · staging · production — staging mirrors prod config with test credentials |
| Config | Env vars from the platform secret store; `.env.example` documents every variable |
| IaC | Terraform/OpenTofu or the platform's config file in the repo; no click-ops for production |
| Deploy | Rolling with health checks; blue/green for risky releases; feature flags for unfinished work |
| Migrations | Expand → migrate → contract across releases; run before new code starts serving |
| Observability | Structured JSON logs with request ID; OpenTelemetry traces; RED metrics per endpoint; error tracking (Sentry or similar) |
| SLOs | Availability and p95 latency per user-facing journey; alerts on burn rate, not single errors |
| Backups | Daily + point-in-time; restore drill quarterly |
| On-call | Named owner per service; alerts go to a channel a human reads |
