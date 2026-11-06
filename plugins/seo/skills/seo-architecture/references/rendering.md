# Rendering for crawlers

| Strategy | What crawlers get | Use for | Stack examples |
|---|---|---|---|
| **Static / prerender (SSG)** | full HTML at build time | marketing, docs, blogs, programmatic pages with data that changes daily or slower | Vite + prerender script, Astro, Next `generateStaticParams`, React Router pre-render |
| **SSR** | full HTML per request | pages with fresh or per-request data that must rank (listings, prices) | Laravel Blade, Inertia SSR, Next/Remix server rendering |
| **ISR / cached SSR** | SSR result cached for N minutes | large catalogues with frequent updates | Next ISR, CDN cache on SSR responses |
| **SPA (client-only)** | an empty shell until JS runs | dashboards, logged-in app, anything not meant to rank | Vite SPA, CRA |

## Rules
- Indexable page types never depend on client-only rendering for title, meta, canonical, h1, main text and internal links.
- Keep marketing/SEO pages in a separate bundle or route group from the app so the app's JS and auth don't slow or block them.
- Logged-in app routes: `noindex` + not linked from public pages.
- Check what a crawler sees: `curl -s <url> | grep -E "<title>|canonical|<h1"` — no JS executed.
- Soft 404s: a missing item returns HTTP 404 (or 410), not a 200 page saying "not found".

## Laravel
Blade or Inertia **with SSR enabled** for public pages; set meta in the layout from the controller (title, description, canonical, OG). Use `URL::route()` for absolute canonicals.

## React (Vite)
Public pages prerendered at build (one HTML file per route with its own `<head>`), or a framework with SSR. Head management per route (React 19 renders `<title>`/`<meta>`/`<link>` in components into `<head>`; libraries like react-helmet-async for older setups).
