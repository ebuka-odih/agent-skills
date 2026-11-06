#!/usr/bin/env bash
set -euo pipefail
mkdir -p app
cat > app/crm.py <<'P'
import os
import requests

BASE = "https://api.crm.example"

def get_contact(cid: str) -> dict:
    r = requests.get(f"{BASE}/contacts/{cid}", headers={"Authorization": "Bearer " + os.environ["CRM_KEY"]})
    r.raise_for_status()
    return r.json()

def create_note(cid: str, text: str) -> dict:
    for _ in range(5):
        try:
            r = requests.post(f"{BASE}/contacts/{cid}/notes", json={"text": text}, headers={"Authorization": "Bearer " + os.environ["CRM_KEY"]})
            r.raise_for_status()
            return r.json()
        except Exception:
            continue
    raise RuntimeError("crm failed")
P
echo "requests" > requirements.txt
