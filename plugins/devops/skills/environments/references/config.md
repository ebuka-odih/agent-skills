# Configuration rules

| Kind | Example | Where it lives | Notes |
|---|---|---|---|
| Plain, same everywhere | `APP_NAME` | code default / config file | no env var needed |
| Plain, per environment | `APP_URL`, `LOG_LEVEL` | platform env vars | documented in `.env.example` |
| Secret, per environment | `DB_PASSWORD`, `STRIPE_SECRET` | platform secret store / GitHub Environment secrets | rotated; least privilege |
| Build-time public | `VITE_API_URL`, `NEXT_PUBLIC_*` | build env | **public** — shipped to browsers; never secrets |
| Feature flags | `FEATURE_NEW_CHECKOUT` | flag service or env | default off in prod |

## Fail fast on missing config
- Laravel: validate required keys in a service provider `boot()` (throw if `config('services.stripe.secret')` empty in non-local envs).
- FastAPI: `pydantic-settings` fields without defaults → app won't start without them.
- Node: parse `process.env` with Zod at startup.

## .env.example format
```dotenv
# Stripe — test keys in local/staging, live only in production secret store
STRIPE_SECRET=
STRIPE_WEBHOOK_SECRET=
# Public URL of the API (build-time, public)
VITE_API_URL=http://localhost:8000
```
