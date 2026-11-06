---
type: llm
weight: 4
---
The repo has a React + Vite app in web/ with 4 public route templates (/, /:city, /:city/:category, /place/:slug), a class-based dark mode (.dark), a deploy workflow named "deploy", and production at https://www.example.city.

PASS only if the agent added:
1. a browser-check config covering one URL per template (4 pages), phone (~375px) and desktop widths, light AND dark with a class-based theme strategy;
2. gating on serious/critical axe violations and sideways scrolling (plus console errors/broken images or equivalent);
3. a CI workflow that runs on pull requests against the built app (preview server) AND after the deploy workflow against https://www.example.city;
4. Playwright/axe as dev-only dependencies (documented or in package.json devDependencies), not runtime dependencies.
FAIL otherwise.
