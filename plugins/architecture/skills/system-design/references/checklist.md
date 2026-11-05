# Architecture decision checklist

Walk every area in order. Each needs a decision, a reason, and a status (Decided / Default / Open / N/A).

## 1. Context and quality attributes
- Users and actors (human roles, other systems)
- Top 3 quality attributes, ranked: e.g. time-to-market, security, availability, cost, latency
- Availability target (99.5% ≈ 3.6 h/month down; 99.9% ≈ 43 min/month)
- RPO (data you can lose) and RTO (time to recover)
- Compliance regimes in scope

## 2. Repository shape
- Monorepo or polyrepo → `repo-and-services` skill (repo-shape.md)
- Workspace tool (pnpm/npm workspaces, Turborepo, Nx, Composer path repos, Go workspaces)
- Folder layout: `apps/`, `packages/` (or `services/`, `libs/`)
- Shared code policy: what may be shared, how it's versioned

## 3. Service shape and boundaries
- Monolith / modular monolith / microservices / serverless → `repo-and-services` skill (service-shape.md, boundaries.md)
- List of modules or services, each with: responsibility in one line, data it owns, who calls it
- Allowed dependency direction between modules (draw it)
- How boundaries are enforced (lint rule, package visibility, deptrac, eslint-plugin-boundaries, Nx tags)

## 4. Domain model
- Core entities and their owner module
- Bounded contexts and where the same word means different things
- Identifiers: UUIDv7 / ULID / auto-increment; public IDs vs internal IDs

## 5. Authentication (who are you)
→ `auth-design` skill (areas 5–6)
- Build vs buy (managed IdP vs framework auth)
- Session cookies vs tokens, per client type (browser, mobile, service)
- Login methods: password, magic link, OAuth/social, passkeys, SSO (SAML/OIDC)
- MFA policy
- Token/session lifetimes, refresh, revocation
- Service-to-service identity

## 6. Authorization (what may you do)
- Model: RBAC / ABAC / ReBAC
- Where it's enforced (one layer, named) and where the policy lives
- Multi-tenancy isolation: row-level tenant_id, schema per tenant, DB per tenant
- Admin and support access, impersonation, audit

## 7. Data
→ `data-design` skill
- Primary database and why
- Additional stores: cache, search, blob/object storage, analytics — each needs a reason
- Ownership: which module owns which tables
- Migrations: tool, who runs them, zero-downtime rule (expand → migrate → contract)
- Backups, retention, deletion (GDPR erase), PII inventory and encryption at rest
- Read scaling plan: indexes → cache → read replicas → partitioning (in that order)

## 8. APIs and contracts
→ `api-design` skill
- Style per boundary: REST, GraphQL, gRPC, tRPC, server actions
- Contract source of truth: OpenAPI / GraphQL schema / proto, generated clients
- Versioning and deprecation rule
- Pagination, filtering, error format (e.g. RFC 9457 problem+json), idempotency keys for writes
- Rate limiting

## 9. Async work, events and integrations
→ `repo-and-services` skill (communication.md); webhooks in `api-design`
- Background jobs: queue tech, retries, dead-letter, idempotency
- Events: in-process vs broker; outbox pattern if events must match DB commits
- Scheduled jobs: where they run, how they avoid double-runs
- Third-party services: list each, its failure mode, and the fallback
- Webhooks in/out: signature verification, replay protection

## 10. Frontend / clients
- Rendering: SPA, SSR, static, hybrid; mobile apps
- Where the backend-for-frontend lives, if any
- State management and data fetching approach
- Design system / component library

## 11. Infrastructure and environments
→ The `devops` plugin (planned) expands this; record the decisions here.
- Hosting/platform (PaaS, containers on managed k8s, serverless, VPS)
- Environments: local, preview, staging, production — and what differs
- IaC tool
- Regions, CDN, DNS
- Config and secrets management

## 12. Delivery
- Branching model and release flow
- CI checks required to merge
- Deploy strategy: rolling, blue/green, canary; feature flags
- Rollback procedure

## 13. Observability
- Structured logs: format, where they go, retention, PII scrubbing
- Metrics and the 3–5 SLIs that matter
- Tracing: OpenTelemetry, propagation across services and queues
- Error tracking and alert routing (who gets paged)

## 14. Reliability
- Failure modes per dependency: what happens when DB / cache / queue / third party is down
- Timeouts, retries with backoff + jitter, circuit breakers
- Graceful degradation rules
- Load expectations and the first bottleneck you expect

## 15. Security baseline
→ The `security` plugin (planned) expands this; record the decisions here.
- Threat model owner and the top 3 threats
- Transport (TLS everywhere), encryption at rest, key management
- Input validation and output encoding layer
- Dependency and container scanning
- Audit logging of security-relevant events

## 16. Testing strategy
- Test pyramid per module: unit / integration / contract / e2e
- Test data and fixtures, how integration tests get a database
- What blocks a merge

## 17. Cost
- Monthly estimate at launch and at 12-month scale
- The biggest cost driver and its ceiling/alert

## 18. Open questions and planned evolution
- Every Open item: question, owner, blocking date, recommended answer
- Planned changes with trigger conditions ("move search to OpenSearch when Postgres full-text p95 > 300 ms")
