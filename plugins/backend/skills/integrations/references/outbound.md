# Outbound policy

| Setting | Default | Notes |
|---|---|---|
| Connect timeout | 3 s | |
| Read timeout | 10 s (APIs), 30–60 s (LLM/AI, file export) | stream long LLM responses instead of raising the timeout further |
| Retries | 2–3, only GET/PUT/DELETE or POST with idempotency key | exponential backoff 0.2 → 2 s + jitter, honour `Retry-After` |
| Circuit breaker | open after 5 consecutive failures or 50% of last 20 | half-open probe after 30–60 s; while open, fail fast → fallback/queue |
| Quota/credit errors (402, provider "insufficient balance") | pause provider 15–60 min (config) | jobs put items back to pending; alert once |
| Rate limit | client-side token bucket below the provider limit | per API key |
| Fallback | second provider, cached result, degrade the feature, or queue for later | document per feature |
| Client lifetime | one shared client per process (connection pool) | Laravel `Http` facade; Python `httpx.AsyncClient` in lifespan |

## Code shapes
- Laravel: `Http::baseUrl($url)->withToken($key)->connectTimeout(3)->timeout(10)->retry([200, 800], when: fn ($e) => $e instanceof ConnectionException)->get(...)`
- httpx: `httpx.AsyncClient(base_url=url, timeout=httpx.Timeout(10, connect=3), headers=auth)`; retries via `tenacity` (`stop_after_attempt(3)`, `wait_exponential_jitter`) on `httpx.TransportError` and 5xx only.
- requests (sync scripts): always `timeout=(3, 10)`.

## Webhooks in
| Rule | How |
|---|---|
| Authentic | verify HMAC/signature with the raw body, constant-time compare, reject old timestamps |
| Once | store event id with a unique constraint; ignore duplicates |
| Fast | 2xx within the provider's limit after enqueuing; do the work in a job |
| Ordered | compare event timestamps/versions; don't let an older event overwrite newer state |
