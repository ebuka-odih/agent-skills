#!/usr/bin/env bash
set -euo pipefail
mkdir -p app tests
cat > app/geocode.py <<'P'
"""Geocoding worker: polls every 5 s for addresses to geocode."""
import time
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone


class ProviderError(Exception):
    def __init__(self, status: int):
        super().__init__(f"provider error {status}")
        self.status = status


@dataclass
class Address:
    id: int
    text: str
    status: str = "pending"          # pending | done | failed
    attempts: int = 0
    next_attempt_at: datetime | None = None
    lat: float | None = None


@dataclass
class Store:
    rows: list[Address] = field(default_factory=list)

    def due(self, now: datetime) -> list[Address]:
        return [a for a in self.rows if a.status in ("pending", "failed")]


def cycle(store: Store, provider, now: datetime | None = None) -> int:
    now = now or datetime.now(timezone.utc)
    calls = 0
    for a in store.due(now):
        calls += 1
        try:
            a.lat = provider(a.text)
            a.status = "done"
        except ProviderError:
            a.attempts += 1
            a.status = "failed"
            a.next_attempt_at = now + timedelta(minutes=5 * 2 ** a.attempts)
    return calls


def run_forever(store: Store, provider) -> None:
    while True:
        cycle(store, provider)
        time.sleep(5)
P
echo "pytest" > requirements.txt
