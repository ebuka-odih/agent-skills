#!/usr/bin/env bash
set -euo pipefail
mkdir -p web app
cat > web/nginx.conf <<'N'
server {
  listen 80;
  root /usr/share/nginx/html;
  location / { try_files $uri $uri/index.html @render; }
  location @render {
    proxy_pass http://api:8000/render$request_uri;
    proxy_intercept_errors on;
    error_page 500 502 503 504 = @spa;
  }
  location @spa { try_files /index.html =404; }
}
N
printf 'from fastapi import FastAPI\napp = FastAPI()\n\n@app.get("/render/{path:path}")\nasync def render(path: str):\n    return {"html": "..."}\n' > app/main.py
printf 'services:\n  api:\n    build: .\n    command: uvicorn app.main:app --host 0.0.0.0 --port 8000\n  web:\n    image: nginx:1.27\n    volumes: ["./web/nginx.conf:/etc/nginx/conf.d/default.conf"]\n' > compose.yaml
