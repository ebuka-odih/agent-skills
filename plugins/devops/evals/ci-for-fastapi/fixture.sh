#!/usr/bin/env bash
set -euo pipefail
mkdir -p backend/app backend/tests
cat > backend/pyproject.toml <<'P'
[project]
name = "studio-api"
requires-python = ">=3.12"
dependencies = ["fastapi", "sqlalchemy[asyncio]", "asyncpg"]
[dependency-groups]
dev = ["pytest", "ruff", "mypy", "httpx"]
[tool.ruff]
line-length = 100
P
touch backend/uv.lock backend/app/__init__.py
printf 'from fastapi import FastAPI\napp = FastAPI()\n\n@app.get("/health")\ndef health():\n    return {"ok": True}\n' > backend/app/main.py
printf 'def test_ok():\n    assert True\n' > backend/tests/test_health.py
