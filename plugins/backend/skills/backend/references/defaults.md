# Backend house defaults

| Topic | Default |
|---|---|
| Layers | route/controller → service (use case) → domain/model → repository/adapter |
| Transactions | one per service call (unit of work); never span a network call; commit before enqueueing (or outbox) |
| Errors | domain exceptions → one handler maps them to RFC 9457 problem+json (`type`, `title`, `status`, `detail`) |
| Validation | at the edge (FormRequest / Pydantic models); services receive typed input |
| Config | env vars read once into a settings object; no `env()`/`os.environ` in business code |
| Migrations | expand → migrate → contract across deploys; `lock_timeout` set; indexes concurrently on Postgres |
| Jobs | idempotent, timeout, max attempts, exponential backoff + jitter, dead letter, `after_commit` |
| Scheduler | exactly one, in a deployed process; overlap-protected (`withoutOverlapping` / advisory lock) |
| Outbound HTTP | timeout (connect 3 s, read 10–30 s), retry only idempotent calls with backoff, circuit breaker on 402/429/5xx streaks |
| Time | UTC in the DB, timezone-aware datetimes, convert at the edge |
| Logs | structured, with request/job id; never secrets or full personal data |
| Tests | service tests with a real DB (SQLite only if the code has no Postgres-specific SQL); failure-path tests for jobs and integrations |
