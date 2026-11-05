---
name: repo-and-services
description: Decide repository shape and service shape — monorepo vs polyrepo, modular monolith vs microservices vs serverless, module boundaries, how parts communicate (sync calls, jobs, events), and when to extract a service. Use when the user asks "monorepo or microservices", "should this be its own service", "how do I split this app", "folder structure", "module boundaries", or when system-design reaches areas 2–3.
---

# Repo and service shape

Two structural calls, made in this order, each from a decision table. Then boundaries and communication.

| Step | Read | Produces |
|---|---|---|
| 1. Repo shape | [references/repo-shape.md](references/repo-shape.md) | monorepo/polyrepo + tool + folder layout |
| 2. Service shape | [references/service-shape.md](references/service-shape.md) | module/service list with owners and data |
| 3. Boundaries | [references/boundaries.md](references/boundaries.md) | dependency rules + enforcement tool |
| 4. Communication | [references/communication.md](references/communication.md) | sync/async choice per interaction |

Also read the house defaults: `../system-design/references/defaults.md`.

## Output (goes into ARCHITECTURE.md §4–5)

```markdown
**Repo:** monorepo (pnpm workspaces + Turborepo) — driver: one team, shared types
**Shape:** modular monolith — driver: team of 3, product pre-fit

| Module | Responsibility | Owns data | Depends on | Status |
|---|---|---|---|---|
| billing | subscriptions, invoices | plans, invoices | identity | Live |

**Dependency rules:** <direction>  ·  **Enforced by:** <tool + config path>
**Planned extraction:** <module> when <measurable trigger>
```

Then call the `adr` skill for repo shape and service shape.

## Hard rules
- Default is **monorepo + modular monolith**. Departing needs a named driver from the tables.
- A service exists only if you can name its owning team, the data it alone owns, and why it must deploy separately.
- One owner per table. Never two writers.
- No extraction without a written, measurable trigger.
