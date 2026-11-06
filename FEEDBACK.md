# Feedback log — from projects back into the skills

Agents working on real projects report what the skills missed. Each report becomes a general change here (`.claude/skills/improve-from-feedback`). Projects are anonymised.

| # | Date | From | Feedback | Class | Change | Version | Status |
|---|---|---|---|---|---|---|---|
| 1 | 2026-11-06 | project 1 agent, after UI fixes | "Add a browser check to CI so these fixes don't slip back (Playwright + axe)" | missing tool | `frontend:browser-checks` skill + `ui-check` runner (axe serious/critical, sideways scroll with culprit elements, broken images, console errors, failed requests; pages × widths × themes) + CI template (PR preview + post-deploy). First real runs: project 1 category page scrolls sideways at 375 px; project 2 pricing page has 2 serious axe violations + sideways scroll | frontend 0.2.0 | closed |
| 2 | 2026-11-06 | project 1 agent, SEO audit handoff | homepage served as a client-rendered shell; backend errors served as 200 shells | wrong or missing guidance | `seo:site-audit` shell detection; `search-console` drop diagnosis; 503-not-200 rule | seo 0.2.0 | closed |
| 3 | 2026-11-06 | real fixes in projects 1 and 2 (job queue hardening, retry storm on a provider without credit, scheduler never deployed, event loop shared across threads) | backend patterns learned the hard way, per project | missing guidance + tool | new `backend` plugin: service-structure, migrations, background-jobs (job contract, Postgres queue, runners/event loops), integrations; `backend-scan.sh` + hook; first scan found the same thread/event-loop pattern still live in a second worker in project 2 | backend 0.1.0 | closed |
