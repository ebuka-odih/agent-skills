---
name: auth-design
description: Design authentication and authorization — build vs buy (framework auth vs managed IdP), sessions vs JWT per client, login methods, MFA, passkeys, SSO, token lifetimes, service-to-service identity, RBAC/ABAC/ReBAC, where permissions are enforced, and multi-tenant isolation. Use when the user asks "how should auth work", "JWT or sessions", "roles and permissions", "SSO", "multi-tenant", or when system-design reaches areas 5–6.
---

# Auth design

Three decisions, in order. Each has its own file.

| Step | Read | Decides |
|---|---|---|
| 1. Authentication | [references/authentication.md](references/authentication.md) | provider, login methods, MFA, session/token per client, lifetimes, service identity |
| 2. Authorization | [references/authorization.md](references/authorization.md) | model, enforcement layer, policy location, audit |
| 3. Tenancy | [references/multi-tenancy.md](references/multi-tenancy.md) | isolation level, how tenant is resolved and enforced |

Skip step 3 only if the product is single-tenant — write "N/A — single tenant" in the doc.

Also read the house defaults: `../system-design/references/defaults.md`.

## Output (goes into ARCHITECTURE.md §7–8)
- Provider / library · login methods · MFA policy
- Table: client type → mechanism → lifetime → revocation
- Service-to-service identity
- AuthZ model · enforcement layer (named class/middleware) · where policies live
- Tenant isolation mechanism + the test that proves it
- Mermaid sequence diagram of the main login flow

Then call the `adr` skill for the auth approach.

## Hard rules
- Never hand-roll password hashing, token signing, or OAuth flows.
- Deny by default. Every endpoint declares its permission; a missing declaration fails a test.
- Object-level checks (IDOR), not just "is logged in".
- Account recovery is an auth path — design it with the same care as login.
