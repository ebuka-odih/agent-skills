# OWASP-mapped checks

| Class | Look for | Fix |
|---|---|---|
| **Broken access control / IDOR** | Handler loads a record by ID without checking owner/tenant; admin routes without role check; client-sent `user_id`/`tenant_id` trusted | Policy/ownership check per object; derive user/tenant from the session; test second-user → 403/404 |
| **SQL injection** | String concatenation/interpolation into SQL, `whereRaw("… $x")`, f-strings into `text()` | Bound parameters; query builder/ORM; allow-list for column/sort names |
| **Command injection** | `exec`, `shell_exec`, `subprocess(..., shell=True)`, backticks with input | Arg arrays, no shell; allow-list values |
| **XSS** | `{!! $x !!}`, `|safe`, `dangerouslySetInnerHTML`, `innerHTML =`, markdown rendered without sanitising | Default escaping; sanitise (DOMPurify / HTML Purifier) when HTML is required; CSP |
| **CSRF** | Cookie-auth state change without CSRF token; `SameSite=None` | Framework CSRF middleware; SameSite=Lax |
| **Mass assignment** | `$guarded = []`, `Model::create($request->all())`, Pydantic model with extra fields allowed on write | `$fillable` / `$request->validated()`; separate input schema; `model_config = ConfigDict(extra="forbid")` |
| **File upload** | Extension-only checks, files in `public/`, original filename used as path, SVG/HTML accepted | Validate MIME by content, size limit, random names, private storage, `Content-Disposition: attachment` |
| **SSRF** | Fetching URLs from input (avatars by URL, webhooks targets, link previews, AI web tools) | Allow-list hosts; block private/link-local/metadata IPs after DNS resolution; no redirects to them |
| **Webhook spoofing / replay** | Parsing body before verifying signature; no timestamp window; no dedupe | Verify HMAC on raw body, 5-min window, store event IDs |
| **Auth/session flaws** | Long-lived JWTs, tokens in localStorage, no rate limit on login/reset, user enumeration in messages | See architecture `auth-design`; uniform error messages; throttling |
| **Sensitive data exposure** | Secrets in code/logs, PII in URLs/logs/analytics, debug mode on, verbose errors | Config/secret store; redaction; `APP_DEBUG=false`; generic error responses |
| **Insecure deserialization** | `unserialize()`, `pickle.loads`, YAML `load` on untrusted data | JSON + schema; `yaml.safe_load` |
| **Open redirect** | `redirect($request->next)` | Relative paths only, or allow-list |
| **Race conditions** | Check-then-act on balances, coupons, seats | DB constraints, row locks, idempotency keys |
| **AI-specific** | Untrusted text in instructions; write tools without approval | See ai-engineering `ai-safety` |
