# Laravel

| Concern | Use | Notes |
|---|---|---|
| Handlers | Controller + FormRequest (validation + `authorize()`) → Action/Service class | resource controllers stay thin; API Resources shape output |
| Domain logic | `app/Actions` or `app/Services` (invokable, injected) | Models: relations, casts, scopes — not workflows |
| Transactions | `DB::transaction(fn () => …)` inside the service | dispatch jobs with `->afterCommit()` (or `after_commit` in queue config) |
| Errors | custom exceptions + `->render()` / `withExceptions()` in `bootstrap/app.php` | consistent JSON for APIs |
| Jobs | `ShouldQueue` + `$tries`, `$timeout`, `$backoff = [10, 60, 300]`, `failed()` | `ShouldBeUnique` / `WithoutOverlapping` middleware for one-at-a-time; `$maxExceptions`; `retryUntil()` for time-boxed retries |
| Queue driver | Redis (Horizon) or database | `retry_after` in `config/queue.php` **>** the longest job `$timeout`, or a job runs twice |
| Scheduler | `routes/console.php` `Schedule::job(...)->withoutOverlapping()->onOneServer()` | exactly one `schedule:work`/cron entry in production |
| Migrations | expand/contract; `$table->…->nullable()` first; `public $withinTransaction = false;` + raw `CREATE INDEX CONCURRENTLY` on Postgres | never `renameColumn` / `dropColumn` in the same deploy as the code change |
| HTTP client | `Http::timeout(10)->connectTimeout(3)->retry(3, 200, throw: false)` | retry only idempotent requests; `->throw()` on non-2xx |
| Tests | `RefreshDatabase`, `Queue::fake()`, `Http::fake()` + `Http::preventStrayRequests()`, `$this->travel()` for time | test `failed()` and retry paths |
