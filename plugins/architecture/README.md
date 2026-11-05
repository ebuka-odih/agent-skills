# architecture

Designs and records a project's system architecture, then keeps changes honest against it.

| Skill | Triggers on | Produces |
|---|---|---|
| `system-design` | "design the system", "write the architecture doc", new project | `docs/architecture/ARCHITECTURE.md` |
| `repo-and-services` | "monorepo or microservices", "should this be its own service" | §4–5: repo layout, modules, boundaries |
| `auth-design` | "how should auth work", "JWT or sessions", "multi-tenant" | §7–8: authN, authZ, tenancy |
| `data-design` | "which database", "safe migrations" | §6, §9: stores, ownership, lifecycle |
| `api-design` | "REST or GraphQL", "version the API" | §10: contracts and conventions |
| `adr` | "record this decision", changing a decision | `docs/architecture/decisions/NNNN-*.md` |

Start with `system-design`; it calls the others. Change recommendations by editing `skills/system-design/references/defaults.md`.
