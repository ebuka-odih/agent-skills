# The job contract

| Property | Rule | Laravel | arq | Celery |
|---|---|---|---|---|
| Idempotent | running twice = running once (check state / idempotency key / unique constraint before the side effect) | `ShouldBeUnique`, state check in `handle()` | `_job_id` for dedupe + state check | `task_id` dedupe + state check |
| Timeout | shorter than the lease/visibility timeout | `$timeout`; `retry_after` > `$timeout` | `job_timeout` / `func(timeout=)` | `time_limit`, `soft_time_limit`; broker `visibility_timeout` > limit |
| Attempts | bounded | `$tries` / `retryUntil()` | `max_tries` | `max_retries` |
| Backoff | exponential + jitter, capped; respected by "due" queries | `$backoff = [10, 60, 300]` | `raise Retry(defer=…)` | `retry_backoff=True, retry_jitter=True, retry_backoff_max=…` |
| Dead letter | after the last attempt: record why, alert, keep the payload for replay | `failed()` + `failed_jobs` | `on_job_failure`/result store + table | `on_failure` + DLQ queue |
| After commit | enqueue only after the DB transaction commits, or write an outbox row in it | `->afterCommit()` | enqueue after `commit()` | `transaction.on_commit` (Django) / after commit |
| Payload | ids + small values; reload state inside the job | `SerializesModels` re-fetches | pass ids | pass ids |
| Acks | ack after success (late ack) so a crash re-delivers | default | default | `acks_late=True` |

## Provider failures inside jobs
| Response | Do |
|---|---|
| 429 / `Retry-After` | defer until `Retry-After` |
| 402 / quota exhausted / account suspended | **pause** that provider for a window (circuit open), put items back to pending — don't burn attempts or retry every cycle |
| 5xx / timeout | retry with backoff; open the circuit after N consecutive failures |
| 4xx (bad input) | don't retry; dead-letter with the reason |
