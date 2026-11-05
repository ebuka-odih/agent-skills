# House defaults

**Edit this file to make the skill yours.** Anything here wins over generic advice. When a default is used without discussion, mark the decision "Default" in ARCHITECTURE.md.

Lines marked `TODO` are placeholders — replace them with your real preferences.

## Structure
- Repo: monorepo
- Service shape: modular monolith; extract only with a written trigger
- Layout: `apps/`, `packages/`, `infra/`, `docs/architecture/`

## Stack
- Backend: TODO (e.g. Laravel 12 / PHP 8.4, or Node + TypeScript)
- Frontend: TODO (e.g. Inertia + React, or Next.js)
- Primary DB: PostgreSQL
- Cache/queue: Redis
- Object storage: S3-compatible
- Search: Postgres full-text until it measurably isn't enough

## Auth
- Web: framework session auth, cookie-based, CSRF on
- Mobile/API: OAuth 2.1 + PKCE or framework token package (e.g. Sanctum)
- B2B SSO needed → managed IdP (TODO: preferred vendor)
- AuthZ: RBAC via policy classes; ReBAC only when sharing/ownership rules appear
- IDs: UUIDv7 for public identifiers

## APIs
- REST + OpenAPI as the contract; problem+json errors; cursor pagination
- Idempotency-Key header on non-idempotent POSTs that move money or send messages

## Infra
- Hosting: TODO (e.g. Laravel Cloud / Forge, Fly.io, Render, AWS)
- Environments: local, preview-per-PR, staging, production
- IaC: TODO (e.g. Terraform / OpenTofu)
- Secrets: platform secret store; never in the repo
- Observability: OpenTelemetry → TODO (e.g. Grafana, Datadog, Sentry for errors)

## Non-negotiables
- Tests run in CI and block merge
- Migrations are backward-compatible (expand → migrate → contract)
- Every third-party call has a timeout
