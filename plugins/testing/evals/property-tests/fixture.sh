#!/usr/bin/env bash
set -euo pipefail
mkdir -p app tests
touch app/__init__.py
printf '[project]\nname="studio"\n[dependency-groups]\ndev=["pytest","hypothesis"]\n' > pyproject.toml
cat > app/fees.py <<'F'
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
