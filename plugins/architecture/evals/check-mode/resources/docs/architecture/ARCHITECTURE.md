# Invoicer — Architecture

## Summary
- **Repo shape:** monorepo
- **Service shape:** modular monolith (Laravel)
- **Auth:** session cookies (web), Sanctum tokens (mobile)
- **Primary data store:** PostgreSQL

## 5. Modules / services
| Module | Responsibility | Owns data | Depends on | Status |
|---|---|---|---|---|
| Identity | users, login, roles | users, roles | — | Live |
| Billing | invoices, payments | invoices, payments | Identity (via `App\Identity\IdentityApi` only) | Live |

**Dependency rules:** Billing may call Identity only through `App\Identity\IdentityApi`. No module reads another module's tables or Eloquent models.
**Enforced by:** deptrac (`deptrac.yaml`)

## 10. APIs and contracts
REST + OpenAPI.

## 16. Reliability
Every third-party HTTP call has an explicit timeout.
