#!/usr/bin/env bash
set -euo pipefail
mkdir -p docs/spec docs/plan docs/architecture docs/security docs/ops docs/ui
cat > docs/spec/SPEC.md <<'S'
# SPEC — Clinic bookings
Patients book appointments online; staff see the day's list. An admin dashboard shows bookings.
We may use an LLM later to summarise notes (not in scope now).
## Requirements
- **R1** (must) Book a slot. accept: booking created, no double booking
- **R2** (must) Staff day list. accept: list sorted by time
## Profile
- ui: yes
- ai: no
- seo: no
## Risks & unknowns
- [x] K1 · Can we prevent double booking without a DB lock? · prototype: double-booking → keep
S
for f in architecture/ARCHITECTURE security/SECURITY ops/DELIVERY ui/UI; do echo "# ${f#*/}" > "docs/$f.md"; done
cat > docs/plan/PLAN.md <<'P'
# PLAN
## M1 — Booking MVP · status: done
- [x] T1 · Booking API · covers: R1
- [x] T2 · Staff day list · covers: R2
## M2 — Reminders · status: planned
- [ ] T3 · SMS reminders · covers: R3
## Progress log
- 2026-11-05 · T2 done · staff list live on staging
P
git init -q; git add -A; git -c user.name=t -c user.email=t@t commit -qm init
