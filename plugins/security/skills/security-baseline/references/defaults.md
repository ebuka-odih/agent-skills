# Security house defaults

| Topic | Default |
|---|---|
| Auth | Framework/IdP auth; see architecture `auth-design` |
| Password hashing | argon2id (bcrypt acceptable) |
| Sessions | Server-side, cookie `HttpOnly; Secure; SameSite=Lax` |
| Tokens | Short-lived access, rotating refresh, revocable |
| Secrets | Platform secret store; `.env` only for local dev; never in code, logs, tickets or chat |
| Dependency audit | On every PR in CI; high/critical blocks merge |
| Headers | CSP (start report-only), HSTS 1 year, nosniff, strict Referrer-Policy, frame-ancestors 'none' |
| Uploads | Object storage, private by default, signed URLs, content-type sniffing, max size |
| Webhooks | HMAC-SHA256 signature + 5-minute timestamp window + event-ID dedupe |
| Logging | Structured; IDs hashed; no PII by default |
| Severity SLA | critical 24 h · high 7 days · medium 30 days · low backlog |
| Full audits | Cloudflare `security-audit` skill, output outside the repo |
