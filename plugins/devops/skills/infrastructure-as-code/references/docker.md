# Production Dockerfiles

## Rules
- Multi-stage: build deps in one stage, copy only the runtime result.
- Pin base images (`python:3.12-slim`, `php:8.4-fpm-alpine`, `node:22-alpine`); update via Dependabot.
- Run as non-root (`USER app`).
- No secrets in `ARG`/`ENV`/layers; inject at runtime.
- `.dockerignore`: `.git`, `node_modules`, `vendor` (rebuilt), `.env*`, tests, `.agent-log/`.
- `HEALTHCHECK` or platform health check hitting a cheap `/health` endpoint that checks DB connectivity.

## FastAPI (uv)
```dockerfile
FROM python:3.12-slim AS build
COPY --from=ghcr.io/astral-sh/uv:0.5 /uv /bin/uv
WORKDIR /app
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-install-project
COPY . .
RUN uv sync --frozen --no-dev

FROM python:3.12-slim
RUN useradd --create-home app
WORKDIR /app
COPY --from=build /app /app
ENV PATH="/app/.venv/bin:$PATH"
USER app
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--proxy-headers"]
```

## Laravel (php-fpm + nginx, or FrankenPHP/Octane)
Build stage: `composer install --no-dev --optimize-autoloader`, `npm ci && npm run build`. Runtime: copy app, `php artisan config:cache route:cache view:cache` at **start** (needs runtime env), storage linked to a volume or object storage, queue worker and scheduler as separate processes/containers.

## Node/React static frontend
Build with `npm ci && npm run build`, serve `dist/` from a static host/CDN or `nginx:alpine`; no Node runtime needed in production.
