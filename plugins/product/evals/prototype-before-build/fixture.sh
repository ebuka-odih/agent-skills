#!/usr/bin/env bash
set -euo pipefail
mkdir -p docs/spec src
cat > docs/spec/SPEC.md <<'S'
# SPEC — Cafe guide
## Requirements
- **R1** (must) Import cafe listings (name, address, opening hours) nightly from the partner directory API. accept: ≥ 95% of listings imported with hours
- **R2** (must) Show each cafe's opening hours on its page. accept: hours visible for imported cafes
## Profile
- ui: yes
- ai: no
- seo: yes
## Risks & unknowns
- [ ] K1 · Does the partner directory API return opening hours for most listings, and in a parseable format? · prototype: directory-hours
## Change log
| Date | Version | IDs | Change | Why |
|---|---|---|---|---|
S
cat > PARTNER_API.md <<'P'
# Partner directory API (docs excerpt)
GET https://partner.example/v2/listings?city=lagos&page=N → { items: [{ id, name, address, hours?: string }] }
`hours` is free text written by owners, e.g. "Mon-Fri 8-6, Sat 9am–2pm", "24/7", "call us". Not every listing has it.
P
git init -q; git add -A; git -c user.name=t -c user.email=t@t commit -qm init
