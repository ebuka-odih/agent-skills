---
name: data-design
description: Design the data layer — choosing the primary database and any extra stores (cache, search, object storage, analytics), table ownership per module, ID strategy, zero-downtime migrations, backups and restore, retention and deletion, PII handling. Use when the user asks "which database", "do I need Redis/Elasticsearch", "how do I run migrations safely", "where should this data live", or when system-design reaches area 7.
---

# Data design

| Step | Read | Decides |
|---|---|---|
| 1. Stores | [references/stores.md](references/stores.md) | primary DB + each extra store with its reason |
| 2. Ownership and IDs | [references/ownership.md](references/ownership.md) | which module owns which tables, ID format |
| 3. Change and lifecycle | [references/lifecycle.md](references/lifecycle.md) | migrations, backups, retention, deletion, PII |

Also read the house defaults: `../system-design/references/defaults.md`.

## Output (goes into ARCHITECTURE.md §6 and §9)
- Store table: store → purpose → why not the primary DB
- Ownership table: table group → owning module
- ID strategy (internal vs public)
- Migration rule, backup schedule + tested restore, retention per data class, PII inventory

Then call the `adr` skill for the primary database and any extra store.

## Hard rules
- One primary database until a measured need says otherwise. Every extra store needs a written reason.
- One owning module per table.
- Migrations are backward-compatible: expand → migrate → contract.
- A backup that has never been restored is not a backup. Schedule a restore drill.
