# Postgres-backed queue

```sql
-- claim ONE job; short transaction; lease so a dead worker's job comes back
UPDATE jobs SET status = 'running', lease_until = now() + interval '5 minutes', attempts = attempts + 1, updated_at = now()
WHERE id = (
  SELECT id FROM jobs
  WHERE status = 'queued' AND run_at <= now()
  ORDER BY priority DESC, run_at
  FOR UPDATE SKIP LOCKED
  LIMIT 1)
RETURNING *;
```

| Rule | Why |
|---|---|
| Claim one job at a time (or lease ≥ batch duration) | claiming a batch lets later jobs' leases expire while earlier ones run → double processing |
| Lease (`lease_until`) + recovery sweep | a killed worker's job returns to `queued` — or to `dead` when attempts are spent |
| Commit the claim, then run the handler in its own transaction | no idle-in-transaction connections; locks held seconds, not minutes |
| Handler raised and the transaction is aborted → `ROLLBACK`, reload the job, then mark failed | writing to an aborted transaction fails again and loses the failure |
| Dedupe key + **partial unique index** (`WHERE status IN ('queued','running')`) and `INSERT … ON CONFLICT DO NOTHING` | enqueue the same work once; the index must exist in every schema path (migrations *and* `create_all`) |
| Retry: `run_at = now() + backoff(attempts)`; due query filters `run_at <= now()` | no hot loop on failing jobs |
| Advisory locks (`pg_advisory_xact_lock`) for singleton work, always taken in the **same order** | avoids deadlocks between a sweep and an ingest touching the same rows |
| Index `(status, run_at)`; archive/delete finished jobs | queue scans stay fast |
| Metrics: queued count, oldest `run_at`, running past lease, dead count | alert before users notice |
