---
name: browser-checks
description: Guard a running web app in a real browser so UI fixes don't slip back — axe accessibility (serious/critical), pages that scroll sideways on phones, broken images, console errors and failed requests, across key pages × phone/desktop widths × light/dark themes; on every PR (against the built app) and after every deploy (against the live site). Use when the user says "add UI tests to CI", "browser tests", "accessibility check", "axe", "Playwright", "keep these fixes from regressing", "the page scrolls sideways on mobile", or after a UI/a11y fix lands.
---

# Browser checks (page level, in CI)

Component tests (`component-testing`) prove pieces work; browser checks prove the **assembled pages** stay usable. One runner, one config, two CI jobs.

**Output:** `ui-check.config.json` + `.github/workflows/ui-check.yml` in the project, and a report (`ui-check-report/report.md` + JSON + screenshots) on every run.

## Steps
1. **Pick pages** — one URL per *template* (home, listing, detail, form, dashboard), not every page: templates share code, so they share bugs. Add a page when a bug was found on it.
2. **Install (dev only)** — `npm i -D playwright @axe-core/playwright` and `npx playwright install --with-deps chromium` (or `"browserChannel": "chrome"` locally to use the installed Chrome).
3. **Copy the runner and config** — `cp -r "${CLAUDE_PLUGIN_ROOT}/scripts/ui-check" scripts/` and `scripts/ui-check/templates/ui-check.config.json` → project root; set `baseUrl`, pages, theme strategy ([references/config.md](references/config.md)).
4. **Run locally** — `node scripts/ui-check/ui-check.mjs --config ui-check.config.json`; fix or explicitly ignore (with a reason) everything failing *before* turning on the gate.
5. **CI** — copy `templates/ui-check.yml`: PR job against the built app (preview server) + post-deploy job against production ([references/ci.md](references/ci.md)).
6. **Read failures** with [references/checks.md](references/checks.md) — each finding names page · width · theme and the culprit element.

## Hard rules
- Gate on serious/critical axe + sideways scroll + broken images + console errors; minor/moderate axe are warnings until the backlog is clear.
- Ignores live in the config with a comment-worthy reason (`ignore.axeRules`, `ignore.console`), never by deleting a page.
- Server-rendered pages (SEO pages rendered by a backend) are only covered by the post-deploy job — make sure it runs.
- A fixed UI bug gets its page added to the config in the same PR.
