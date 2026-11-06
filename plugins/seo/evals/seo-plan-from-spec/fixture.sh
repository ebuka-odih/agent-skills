#!/usr/bin/env bash
set -euo pipefail
mkdir -p docs
cat > SPEC.md <<'S'
# SPEC — Cafe guide

A public directory of independent cafes, first in Lagos and Abuja (Nigeria), then Austin and Denver (US).

## Requirements
- R1 Venue page per cafe: name, address, area, opening hours, price range, photos, menu highlights.
- R2 City × category listing pages (e.g. "brunch in Lagos", "work-friendly cafes in Austin"), generated from data. ~40 categories × 4 cities.
- R3 Search with filters (open now, wifi, price) — results page with query parameters.
- R4 Separate Nigerian (NGN prices) and US (USD prices) versions of shared pages such as category guides.
- R5 Logged-in dashboard for cafe owners to edit their listing.
- R6 Many categories will have only 1–3 cafes in a city at launch.

## Stack
Laravel 12 + Inertia + React, hosted on one VPS. Owners' dashboard is the same app.
S
cat > ARCHITECTURE.md <<'A'
# Architecture
Monolith: Laravel 12, Inertia React front end, Postgres. Public pages and owners' dashboard in one app.
A
