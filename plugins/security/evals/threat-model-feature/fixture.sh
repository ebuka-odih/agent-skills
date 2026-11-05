#!/usr/bin/env bash
set -euo pipefail
mkdir -p docs/spec
cat > docs/spec/SPEC.md <<'S'
---
status: agreed
version: 2
---
# Studio — Spec
## Requirements
- **R8** (must) A member can upload a profile photo (JPG/PNG) that other members of their studio see.
  accept: upload ≤ 5 MB shows on the member's profile within 10 s.
- **R9** (must) When Stripe reports a subscription payment succeeded, the member's plan is activated.
  accept: Stripe `invoice.paid` webhook → plan active within 1 minute.
## Constraints
- Laravel 12, multi-tenant (one studio = one tenant), files on S3-compatible storage.
S
