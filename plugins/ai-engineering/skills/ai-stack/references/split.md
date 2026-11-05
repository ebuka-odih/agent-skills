# Split: Laravel app ↔ FastAPI AI service

Use when the AI work needs Python (Pydantic AI agents with many tools, browser automation, ML libraries) but the product is a Laravel app.

## Contract
- The AI service exposes **feature endpoints**, not a generic "chat with the model" proxy: `POST /v1/features/f1-invoice/extract`.
- Request/response models are Pydantic; FastAPI publishes OpenAPI → generate or hand-write PHP DTOs from it. CI fails on contract drift.
- Every request carries: `tenant_id`, `user_id` (hashed if possible), `feature_id`, `idempotency_key`, `request_id` for tracing.

## Calls
| Work | Transport |
|---|---|
| < 5 s, user waiting | HTTP from Laravel with timeout + `Http::retry()` on 429/5xx only |
| Streaming chat | Browser ↔ AI service SSE directly (signed short-lived token from Laravel), or Laravel proxies the stream |
| Long / batch | Laravel queue job → AI service → callback webhook (signed) or result polling |

## Auth between services
Short-lived signed token (JWT/HMAC) issued by Laravel; AI service verifies it and enforces tenant scope. No shared static API key in both repos.

## Data ownership
AI service owns only AI data (embeddings, eval results, usage rows). Business tables stay in Laravel; the AI service reads them through Laravel APIs or a read replica — never writes them directly.

## Record in AI.md
Endpoint list per feature, transport, auth method, timeout, retry policy, who owns which tables.
