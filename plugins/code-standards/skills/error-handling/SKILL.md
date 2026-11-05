---
name: error-handling
description: Handle errors so failures are visible and recoverable — validate input at the edge, use typed domain errors inside, map them to HTTP/UI responses in one place, never swallow exceptions, add timeouts and retries only where safe, and log with context but without PII. Use when writing code that can fail (I/O, external APIs, queues, user input), when the user asks "how should I handle errors", "this fails silently", "add retries", "what status code", or when reviewing try/catch blocks.
---

# Error handling

## The three layers
| Layer | Job | Example |
|---|---|---|
| **Edge** (controller/router/form) | Validate input; map domain errors → response | Form Request / Pydantic model / Zod; one exception handler |
| **Inside** (services, domain) | Raise specific, typed errors; don't catch what you can't handle | `BookingTooLateToCancel`, `PaymentDeclined` |
| **Outside calls** (DB, HTTP, queues, AI) | Timeout, retry only idempotent ops, translate vendor errors to domain errors | `Http::timeout(5)->retry(3, 200)` · `httpx.Timeout(5)` · `AbortSignal.timeout(5000)` |

## Steps
1. List what can fail in this change: input, missing records, permissions, conflicts, external calls, timeouts.
2. For each: who can act on it? User (show a message) · caller (return/raise a typed error) · operator (log + alert) · nobody (crash loudly, it's a bug).
3. Pick the response from [references/patterns.md](references/patterns.md) — status codes, retry rules, logging fields.
4. Test the failure paths, not just the happy path (`testing` skill).

## Hard rules
- **Never swallow:** no empty `catch`, no `except: pass`, no `catch (e) {}`. Catch → handle, or catch → add context → rethrow.
- **Catch specific errors**, not `Exception`/`Throwable`, except at the top-level handler.
- **No error codes as return values** (`false`, `-1`, `null` meaning "failed") — raise or return a typed result.
- **Timeouts on every external call.** Retries only for idempotent operations, with backoff + jitter and a cap.
- **Log once,** where handled, with request ID / tenant / entity IDs — no secrets, tokens or PII.
- **User-facing messages are safe:** no stack traces, SQL or internal hostnames.
