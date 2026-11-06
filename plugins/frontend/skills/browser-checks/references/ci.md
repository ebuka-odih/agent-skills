# CI wiring (`scripts/ui-check/templates/ui-check.yml`)

| Job | When | Against | Why |
|---|---|---|---|
| `preview` | every PR | built app on a local preview server (`vite preview`, `next start`, `php artisan serve`…) | catches regressions before merge |
| `live` | after the deploy workflow succeeds | production URL | catches what only exists in production: server-rendered pages, CDN/config, real data |

- Cache npm; install only Chromium (`--with-deps chromium`) — ~1 min.
- Upload `ui-check-report/` as an artifact (report.md, report.json, screenshots).
- Backend-rendered pages need the backend running for the PR job (docker compose) — if that's heavy, rely on the `live` job for them and say so in the config's page names.
- Make `ui-check` a required check once the first run is green.
