# REST conventions

## Resources and methods
- Plural nouns: `/invoices`, `/invoices/{id}/lines`. Nest at most one level.
- `GET` reads, `POST` creates, `PATCH` partial update, `PUT` full replace, `DELETE` removes.
- Actions that aren't CRUD: `POST /invoices/{id}/send`.
- JSON fields in one case style across the API (pick `snake_case` or `camelCase`, record it).

## Errors — RFC 9457 problem+json
```json
{ "type": "https://api.example.com/errors/validation",
  "title": "Validation failed", "status": 422,
  "detail": "email is invalid", "errors": { "email": ["must be a valid email"] },
  "request_id": "req_01H…" }
```
Never leak stack traces, SQL, or internal hostnames.

## Status codes
200 OK · 201 Created · 202 Accepted (async) · 204 No Content · 400 malformed · 401 not authenticated · 403 not allowed · 404 not found (also for "exists but not yours") · 409 conflict · 422 validation · 429 rate limited · 5xx server

## Pagination
Cursor-based by default: `?limit=50&cursor=…` → `{ data, next_cursor }`. Offset only for small admin lists.

## Idempotency
`Idempotency-Key` header on POSTs that charge, send, or create external side effects. Store key + response for 24 h; replay returns the stored response.

## Rate limiting
Per API key / user / IP. Return `429` with `Retry-After` and `RateLimit-*` headers.
