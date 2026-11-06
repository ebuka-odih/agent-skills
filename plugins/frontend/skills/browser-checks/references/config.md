# ui-check.config.json

| Key | Default | Notes |
|---|---|---|
| `baseUrl` | — | `http(s)://…`; overridden by `--base-url` (CI passes preview/prod URL) |
| `pages` | — | `[{ "name": "category", "path": "/ng/lagos/pharmacies", "widths"?: [375], "themes"?: ["dark"] }]` — one per template |
| `widths` | `[375, 1280]` | phone + desktop; add 768 if tablet layouts differ |
| `themes` | `["light"]` | add `"dark"` when the app has a dark theme |
| `themeStrategy` | `{ "type": "media" }` | how the app picks dark: `media` (prefers-color-scheme) · `class` (`name`, default `dark` on `<html>`) · `attribute` (`name`: e.g. `data-theme`, `dark`/`light` values) · `storage` (`key` in localStorage) — match `ui-system`'s dark-mode setup |
| `failOn` | `["serious","critical"]` | axe impacts that fail the run |
| `checks` | all on | `axe`, `overflow`, `images`, `console`, `requests` (same-origin 4xx warn, 5xx fail) |
| `ignore` | `{}` | `axeRules: ["region"]`, `console: ["regex"]` — each with a reason in the PR |
| `screenshots` | off | `true` → full-page PNG per run in the report folder (attach as CI artifact) |
| `browserChannel` | — | `"chrome"` uses an installed Chrome instead of Playwright's download |
| `waitMs` / `timeoutMs` | 500 / 30000 | raise `waitMs` for pages that render after data loads |
