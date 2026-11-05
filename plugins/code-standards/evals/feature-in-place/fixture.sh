#!/usr/bin/env bash
set -euo pipefail
mkdir -p app/api app/services app/schemas tests docs/architecture
cat > docs/architecture/ARCHITECTURE.md <<'A'
# Studio — Architecture
## 5. Modules
| Module | Responsibility | Owns data |
|---|---|---|
| bookings | bookings, cancellations, fees | bookings |
**Dependency rules:** routers in `app/api/` are thin and call services in `app/services/`; services never import FastAPI. Money is integer kobo (minor units). Time is UTC; pass `now` in, never call the clock inside services.
A
cat > app/services/pricing.py <<'P'
"""Pricing rules for bookings. Pure functions; money in kobo."""
from __future__ import annotations


def class_price_kobo(base_kobo: int, is_member: bool) -> int:
    """Members get 20% off, rounded down to the kobo."""
    if base_kobo < 0:
        raise ValueError("base_kobo must be >= 0")
    return base_kobo * 80 // 100 if is_member else base_kobo
P
cat > tests/test_pricing.py <<'T'
import pytest

from app.services.pricing import class_price_kobo


def test_member_discount():
    assert class_price_kobo(10_000, True) == 8_000


def test_non_member_full_price():
    assert class_price_kobo(10_000, False) == 10_000


def test_negative_price_rejected():
    with pytest.raises(ValueError):
        class_price_kobo(-1, False)
T
cat > app/api/bookings.py <<'R'
from fastapi import APIRouter

router = APIRouter(prefix="/bookings")
R
touch app/__init__.py app/services/__init__.py app/api/__init__.py
