#!/usr/bin/env bash
set -euo pipefail
G="git -c user.name=dev -c user.email=dev@example.invalid"
git init -q -b main
mkdir -p docs/spec app/services app/api/v1/endpoints web/src/pages tests
cat > docs/spec/SPEC.md <<'S'
# Studio — Spec
- **J2** Member: open booking → cancel → see refund
- **R7** (must) A member can cancel up to 2 h before class for free; later costs 50%; after start 100%.
  accept: exact-boundary behaviour at 120 minutes; fee in kobo.
- **NFR1** (must) Cancel endpoint p95 < 300 ms at 30 rps.
- **NFR2** (must) Web app meets WCAG 2.2 AA.
S
printf 'from fastapi import FastAPI\napp = FastAPI()\n' > app/main.py
$G add -A && $G commit -qm "chore: init"
$G switch -q -c feat/T7-cancel-fee
cat > app/services/fees.py <<'F'
from datetime import datetime, timedelta


def late_cancel_fee_kobo(price_kobo: int, class_starts_at: datetime, cancelled_at: datetime) -> int:
    """Free if cancelled >= 2 h before start; 50% if < 2 h before; 100% once started."""
    if price_kobo < 0:
        raise ValueError("price_kobo must be >= 0")
    if class_starts_at.tzinfo is None or cancelled_at.tzinfo is None:
        raise ValueError("datetimes must be timezone-aware")
    if cancelled_at >= class_starts_at:
        return price_kobo
    if class_starts_at - cancelled_at >= timedelta(hours=2):
        return 0
    return price_kobo // 2
F
printf 'from fastapi import APIRouter\nrouter = APIRouter()\n\n@router.post("/bookings/{booking_id}/cancel")\nasync def cancel(booking_id: int):\n    ...\n' > app/api/v1/endpoints/bookings.py
printf 'export function CancelBookingDialog() {\n  return <div><button>Cancel booking</button></div>;\n}\n' > web/src/pages/CancelBookingDialog.tsx
