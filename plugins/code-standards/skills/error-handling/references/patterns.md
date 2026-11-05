# Error patterns

## Domain error → HTTP
| Domain situation | Status | Body |
|---|---|---|
| Input invalid | 422 | field errors (problem+json `errors`) |
| Not authenticated | 401 | — |
| Authenticated, not allowed | 403 (or 404 to hide existence) | — |
| Record not found / not yours | 404 | — |
| State conflict (already cancelled, version mismatch) | 409 | what to do next |
| Business rule refused (too late to cancel) | 422 | human message |
| Rate limited | 429 + `Retry-After` | — |
| Dependency down / timeout | 503 / 504 | "try again" — log + alert |
| Bug | 500 | generic message + request ID |

## Mapping in one place
- **Laravel:** custom exceptions with `render()`/`report()`, or `->render()` in `bootstrap/app.php` `withExceptions()`.
- **FastAPI:** `@app.exception_handler(DomainError)` → `JSONResponse`.
- **React:** error boundaries for render errors; query `onError` → toast/inline message; never blank screens.

## Retry rules
| Operation | Retry? |
|---|---|
| GET / read | yes, 2–3× with backoff + jitter |
| Write with idempotency key | yes |
| Write without idempotency (charge, send email) | **no** — make it idempotent first |
| 4xx (except 408/429) | no |
| 429 | yes, honour `Retry-After` |
| Queued jobs | `$tries`/`max_tries` + backoff; dead-letter after the last |

## Log fields
`level, message, error_type, request_id, tenant_id, user_hash, entity_id, operation, duration_ms` — never full request bodies with PII, tokens or passwords.

## Examples of swallowing (all wrong)
```php
try { $this->payments->refund($id); } catch (\Throwable $e) {}         // lost money, no trace
```
```python
try: send_email(user) 
except Exception: pass                                                   # silent failure
```
```ts
fetch(url).catch(() => {})                                               // UI shows stale data forever
```
