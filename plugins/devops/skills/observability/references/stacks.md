# Observability by stack

## Laravel
- Logs: `LOG_CHANNEL=stderr` with JSON formatter (`Monolog\Formatter\JsonFormatter`) in containers; `Log::withContext(['request_id' => …, 'tenant_id' => …])` in a middleware.
- Request ID: middleware reads/sets `X-Request-Id`, adds to context and response.
- Errors: Sentry Laravel SDK (`sentry/sentry-laravel`) or Flare/Nightwatch.
- Queues: Horizon metrics (Redis) or job events → metrics; alert on failed jobs and wait time.
- Traces: OpenTelemetry PHP auto-instrumentation where supported.

## FastAPI
- Logs: `structlog` (JSON renderer) with contextvars for `request_id`; middleware sets/propagates `X-Request-Id`.
- Traces: `opentelemetry-instrumentation-fastapi`, `-sqlalchemy`, `-httpx`; or Logfire (`logfire.instrument_fastapi(app)`).
- Metrics: OpenTelemetry metrics or `prometheus-fastapi-instrumentator` (`/metrics`).
- Errors: Sentry Python SDK with FastAPI integration.

## React / frontend
- Errors: Sentry browser SDK with release + source maps uploaded in CI.
- Web vitals (LCP, INP, CLS) reported to analytics/RUM.
- Never log tokens or PII from the browser.

## AI calls
Usage row per call (feature, prompt version, model, tokens, cost, latency, outcome) — see ai-engineering `ai-ops`.
