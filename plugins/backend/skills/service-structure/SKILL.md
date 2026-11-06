---
name: service-structure
description: Structure backend code so features stay easy to change — thin routes/controllers, one service (use case) per action, domain rules in plain code, persistence behind repositories or the ORM at the edges, one transaction per use case, and one error mapping. Use when adding an endpoint or feature, when a controller/route grows business logic or SQL, when the user says "where should this logic go", "refactor this controller", "service layer", "clean up the backend", or in code review of server code.
---

# Service structure

**Output:** code placed by layer, with the request path readable top to bottom in one service.

## Steps
1. **Name the use case** — one verb phrase per service function/class (`BookSlot`, `cancel_booking`), taking typed input, returning a typed result or raising a domain error.
2. **Place code by layer** — [references/layers.md](references/layers.md): what each layer may and may not do, and the dependency direction.
3. **Transaction boundary** — the service opens it; no network call inside it; side effects that must follow a commit (jobs, emails, webhooks) are enqueued *after commit* (or via an outbox row in the same transaction).
4. **Errors** — raise domain exceptions; one handler maps them to HTTP (problem+json). No `try/except: pass`.
5. **Test the service** directly (real DB), the handler only for wiring (status codes, auth).

## Hard rules
- Handlers don't contain business rules, SQL or calls to other services.
- Services don't import web framework objects (Request, Response, HTTPException).
- One place decides each rule (e.g. "a slot holds one booking") — enforce it in the DB too (unique constraint) when concurrency matters.
