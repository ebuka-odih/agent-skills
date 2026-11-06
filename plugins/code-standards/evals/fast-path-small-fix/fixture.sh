#!/usr/bin/env bash
set -euo pipefail
mkdir -p app tests
printf 'def format_price(amount: float) -> str:\n    return f"₦{amount}"\n' > app/money.py
printf 'from app.money import format_price\n\ndef test_whole():\n    assert format_price(2) == "₦2"\n' > tests/test_money.py
touch app/__init__.py
