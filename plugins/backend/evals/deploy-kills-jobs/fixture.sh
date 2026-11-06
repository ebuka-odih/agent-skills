#!/usr/bin/env bash
set -euo pipefail
mkdir -p app
cat > app/worker.py <<'P'
"""Import worker: claims one job at a time from Postgres and runs it (imports take up to ~90 s)."""
import time
from app.queue import claim_one, mark_done, mark_failed, run_import

def main() -> None:
    while True:
        job = claim_one(lease_seconds=300)   # sets status='running', lease_until=now()+300s
        if job is None:
            time.sleep(5)
            continue
        try:
            run_import(job)
            mark_done(job)
        except Exception as e:
            mark_failed(job, str(e))

if __name__ == "__main__":
    main()
P
cat > compose.yaml <<'C'
services:
  web:
    image: app
    command: uvicorn app.main:app --host 0.0.0.0
    restart: unless-stopped
  worker:
    image: app
    command: python -m app.worker
    restart: unless-stopped
C
