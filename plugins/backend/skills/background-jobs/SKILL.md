---
name: background-jobs
description: Make background work correct under retries, crashes, deploys and duplicates — idempotent jobs, timeouts and attempt limits, exponential backoff that is actually respected, leases and dead letters, enqueue after commit (outbox), exactly one scheduler in a process that is really deployed, and async workers that don't share an event loop or DB pool across threads. Laravel queues, arq, Celery, and Postgres-backed queues (SKIP LOCKED). Use when writing or reviewing jobs, workers, queues, cron/scheduled tasks or polling loops, or when the user says "job ran twice", "stuck in the queue", "retry storm", "worker hangs", "cron didn't fire", "dead letter", "scheduled task".
---

# Background jobs, workers and schedulers

**Output:** jobs that satisfy the job contract, a scheduler map (task → process → interval → overlap guard), and failure-path tests.

## Steps
1. **Job contract** — every job meets [references/contract.md](references/contract.md): idempotent, timeout, attempts, backoff (+ jitter), dead letter, after-commit, small payload (ids, not objects).
2. **Pick the runner** — [references/runners.md](references/runners.md): Laravel queue / arq / Celery / Postgres queue / in-process task; where it runs in production *today* (check the deploy files, not the code).
3. **Postgres-backed queue?** Follow [references/postgres-queue.md](references/postgres-queue.md): claim with `FOR UPDATE SKIP LOCKED`, one job per claim, leases, recover expired leases, dedupe key, short transactions.
4. **Scheduler map** — list every periodic task, which process fires it, its interval and its overlap guard. Exactly one firing path per task.
5. **Failure-path tests** — handler raises → retried with backoff, then dead-lettered; job runs twice → same result; worker killed mid-job → lease expires → picked up once; provider down → paused, not hammered.
6. **Observe** — queue depth, oldest job age, failure rate, dead-letter count as metrics with alerts (`devops:observability`).

## Hard rules
- A retry must never cause a second side effect (charge, email, message): idempotency key or state check first.
- "Due" queries respect `next_attempt_at`; a failing item is not picked up again every poll cycle — every failure path sets it, including pauses.
- Classify provider errors before retrying: timeouts, 5xx and 429 are retryable with backoff; 400/401/403/404 fail the item; **402 / quota / out of credits pauses all work for that provider** (persisted pause, not per-item retry) — see `integrations`.
- Never run the same schedule in two places (cron + worker loop, two replicas) without a lock.
- An async engine/pool belongs to one event loop: background tasks run on the app loop or a worker with its own engine.
