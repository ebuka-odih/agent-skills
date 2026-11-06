---
name: integrations
description: Call other services safely — timeouts on every request, retries only for idempotent calls with backoff and jitter, circuit breakers and quota pauses for failing or out-of-credit providers, rate limits, a fallback path, one shared client, verified and idempotent inbound webhooks, and tests that fake the provider. Use when adding or reviewing an API client, SDK call, webhook, scraper, LLM/AI provider call, payment or email integration, or when the user says "the provider is down", "we're getting rate limited", "it hangs on the API call", "webhook", "retry the request".
---

# Outbound and inbound integrations

**Output:** one client module per provider (timeouts, retries, breaker, error mapping) and tests that fake it.

## Steps
1. **One client per provider** — a module/class that owns the base URL, auth, timeouts, retry policy and error mapping; the rest of the code calls it, never raw HTTP.
2. **Set the policy** from [references/outbound.md](references/outbound.md): timeouts, which calls are retryable, backoff, breaker thresholds, quota pause, fallback.
3. **Map failures to domain errors** (`ProviderUnavailable`, `QuotaExhausted`, `InvalidRequest`) so services and jobs decide: retry, pause, fall back or fail.
4. **Inbound webhooks** — verify the signature, dedupe by event id, respond fast (enqueue the work), handle out-of-order events.
5. **Test** with the provider faked (`Http::fake` + `preventStrayRequests`, `respx`/`MockTransport`): timeout, 429 with Retry-After, 402/quota, 5xx streak → breaker open, malformed body.

## Hard rules
- No request without a timeout (Python `requests` has none by default).
- Never retry non-idempotent calls (payments, sends) without an idempotency key the provider honours.
- A provider that says "no credit / quota" pauses, it isn't retried every cycle.
- Secrets come from config; request/response logs redact them.
