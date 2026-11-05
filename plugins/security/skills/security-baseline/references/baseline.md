# Security baseline checklist

Each line: in place (evidence) · N/A (why) · gap (severity, owner, fix).

## Identity and access
- [ ] Auth uses framework/IdP primitives; passwords argon2id/bcrypt; no custom crypto
- [ ] Sessions: `HttpOnly`, `Secure`, `SameSite`; rotated on login; logout invalidates server-side
- [ ] MFA available, required for admins
- [ ] Rate limiting + lockout on login, password reset, OTP, magic links
- [ ] Authorization enforced in one layer; deny by default; object-level checks (IDOR) tested
- [ ] Multi-tenant scoping automatic; cross-tenant test exists
- [ ] Admin/impersonation audited

## Input and output
- [ ] All input validated at the edge (Form Requests / Pydantic / Zod)
- [ ] Queries parameterised; no string-built SQL/shell/LDAP
- [ ] Output encoded; no raw HTML from users (`{!! !!}`, `dangerouslySetInnerHTML`, `|safe`)
- [ ] Mass assignment controlled (`$fillable`, explicit Pydantic models)
- [ ] File uploads: type by content (not extension), size limits, stored outside web root / object storage, served with safe `Content-Type` + `Content-Disposition`
- [ ] Outbound requests to user-supplied URLs blocked or allow-listed (SSRF)
- [ ] Webhooks: signature + timestamp verified, replay-protected

## Transport and browser
- [ ] HTTPS everywhere, HSTS
- [ ] Security headers: CSP, `X-Content-Type-Options: nosniff`, `Referrer-Policy`, `frame-ancestors`/`X-Frame-Options`
- [ ] CORS allow-list, no `*` with credentials
- [ ] CSRF protection for cookie-authenticated state changes

## Secrets and dependencies
- [ ] No secrets in repo or history; `.env` gitignored; `.env.example` has placeholders only
- [ ] Secrets in a platform secret store; least-privilege keys; rotation documented
- [ ] Dependency audit runs in CI (`composer audit`, `pip-audit`/`uv`, `npm audit`); lockfiles committed
- [ ] Automated update PRs (Dependabot/Renovate)

## Data
- [ ] PII inventory; encryption at rest for sensitive columns; backups encrypted + restore tested
- [ ] Logs contain no passwords, tokens, full card numbers, or unnecessary PII
- [ ] Data deletion/export path for users (GDPR/NDPR)

## AI (if docs/ai/AI.md exists)
- [ ] Untrusted content delimited and declared as data; write tools need approval
- [ ] Provider keys server-side only; per-user rate limits and spend caps

## Operations
- [ ] Error pages leak no stack traces / versions in production (`APP_DEBUG=false`, `debug=False`)
- [ ] Security events logged (login, failed authz, admin actions) and alerting on anomalies
- [ ] Incident contact and secret-rotation runbook exist
