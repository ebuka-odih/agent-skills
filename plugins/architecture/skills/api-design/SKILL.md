---
name: api-design
description: Design APIs and contracts — REST vs GraphQL vs gRPC vs tRPC per boundary, contract source of truth (OpenAPI, schema, proto), versioning and deprecation, error format, pagination, idempotency keys, rate limiting, and webhooks. Use when the user asks "REST or GraphQL", "how should the API look", "how do I version this API", "error format", "design endpoints", or when system-design reaches area 8.
---

# API design

| Step | Read | Decides |
|---|---|---|
| 1. Style per boundary | [references/style.md](references/style.md) | REST / GraphQL / gRPC / tRPC for each consumer |
| 2. Conventions | [references/conventions.md](references/conventions.md) | naming, errors, pagination, idempotency, rate limits |
| 3. Evolution | [references/versioning.md](references/versioning.md) | contract source, versioning, deprecation, webhooks |

Also read the house defaults: `../system-design/references/defaults.md`.

## Output (goes into ARCHITECTURE.md §10)
- Table: boundary (e.g. web → api, partner → api, api → worker) → style → contract file path
- Error format, pagination style, idempotency rule, rate limits
- Versioning and deprecation policy

Then call the `adr` skill for the API style.

## Hard rules
- The contract file (OpenAPI/schema/proto) is the source of truth, checked into the repo, and CI fails if code and contract drift.
- Breaking changes never ship to an existing version.
- Every non-idempotent write that moves money or sends messages accepts an `Idempotency-Key`.
