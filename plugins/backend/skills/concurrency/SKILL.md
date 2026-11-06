---
name: concurrency
description: Make the same action impossible to apply twice or to lose an update — idempotency keys for retried requests and double clicks, unique constraints as the final guard against check-then-insert races, optimistic locking (version columns) for concurrent edits, atomic updates or SELECT … FOR UPDATE for counters and balances, advisory/atomic locks for singleton work, and tests that actually run requests in parallel. Use when building payments, bookings, sends, credits, stock, counters, anything "exactly once", or when the user says "it charged twice", "double booking", "sent twice", "race condition", "two people edited", "idempotent", "duplicate".
---

# Concurrency correctness

Two requests, two workers or one retried message arrive at the same time. The code must give the same answer as if they came one after another.

**Output:** for each state-changing action, its race and the guard that stops it, plus a parallel test.

## Steps
1. **List the actions that must not double** — money, messages, bookings, stock, credits, quotas, external side effects.
2. **Name the race for each** and pick its guard from [references/patterns.md](references/patterns.md): double submit → idempotency key; check-then-insert → unique constraint; lost update → version column; counter → atomic update; singleton work → lock.
3. **Put the final guard in the database** (constraint, atomic statement, row lock) — application checks are a fast path, not the guarantee.
4. **Side effects after commit** — send/charge/enqueue only after the state change commits, keyed by the same idempotency key (`background-jobs` contract).
5. **Test in parallel** — fire N identical requests/jobs at once (`asyncio.gather`, `Promise.all`, parallel processes) against the real database; assert exactly one effect.
6. **Check** — `backend-scan.sh` flags check-then-insert code and read-modify-write on balances/counters.

## Hard rules
- "Check if it exists, then insert" is never the only guard.
- POST endpoints that create money, messages or bookings accept an `Idempotency-Key` (or derive one) and return the original result on replay.
- Counters and balances change with one atomic statement (`UPDATE … SET n = n - :x WHERE n >= :x`), not load-modify-save.
- Concurrency tests use the production database engine (SQLite won't show row locks or SKIP LOCKED behaviour).
