# Multi-tenancy

## Isolation level
| Level | When | Cost |
|---|---|---|
| Shared tables + `tenant_id` | Default. Many small tenants | Cheapest; isolation depends on code discipline |
| Shared tables + Postgres RLS | Same, but you want the DB to enforce it | Small setup cost; strongest shared option |
| Schema per tenant | Tenants need custom fields or per-tenant restore | Migrations run N times |
| Database per tenant | Contractual isolation, data residency, very large tenants | Highest ops cost |

## Rules
- Resolve the tenant **once** per request (subdomain, path, or token claim) and store it in request context.
- Scope every query automatically (global scopes, RLS, repository base class). No manual `where tenant_id` in feature code.
- Background jobs carry the tenant ID explicitly and re-establish context.
- Caches, file paths, search indexes, and queue names include the tenant.
- A test proves cross-tenant reads and writes fail. It runs in CI.
