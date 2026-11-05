#!/usr/bin/env bash
set -euo pipefail
mkdir -p docs/spec backend
cat > backend/requirements.txt <<'R'
fastapi==0.116.1
pydantic==2.12.0
sqlalchemy==2.0.36
R
cat > docs/spec/SPEC.md <<'S'
---
status: agreed
version: 1
---
# MenuMate — Spec
## Vision
Restaurant owners in Lagos get their menus online and answer diners' questions automatically.
## Requirements
- **R1** (must) An owner uploads a photo or PDF of a paper menu; dishes, prices (NGN) and sections are extracted for them to review before publishing.
  accept: 20 sample menus → ≥ 90% of dishes and prices correct; owner can edit before publish.
- **R2** (must) A diner asks questions in chat ("is the jollof spicy?", "anything vegetarian under 5000?") and gets answers grounded only in that restaurant's menu.
  accept: answers cite dish IDs; questions about dishes not on the menu get "not on the menu".
- **R3** (should) Diner reviews scraped from public sites are summarised per dish for the owner.
  accept: summary per dish with count of reviews used.
- **NFR1** (must) Cost ≤ ₦50 per menu import and ≤ ₦5 per chat answer.
- **NFR2** (must) Chat answers start streaming within 2 s.
## Non-goals
- Ordering and payments
## Constraints
- Backend is FastAPI; ~400 restaurants in year one; NDPR (Nigerian data protection) applies.
S
git init -q && git add -A && git -c user.name=eval -c user.email=eval@example.invalid commit -qm init
