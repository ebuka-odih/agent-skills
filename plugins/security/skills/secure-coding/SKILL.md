---
name: secure-coding
description: Write and review code so common vulnerabilities don't ship — broken access control/IDOR, injection (SQL, command, template), XSS, CSRF, mass assignment, insecure file uploads, SSRF, unverified webhooks, weak auth/session handling, secrets and sensitive data exposure, insecure deserialization — with concrete rules for Laravel, FastAPI and React. Use when writing or reviewing code that touches auth, user input, files, URLs, webhooks, payments or personal data, when the user asks "is this secure", "security review this PR", "check for vulnerabilities", or when security-baseline routes a review.
---

# Secure coding

## Review a change (or your own code before committing)
1. **Find the trust boundaries in the diff:** new routes/endpoints, request input, file uploads, outbound URLs, webhooks, queue messages, AI tool calls, DB queries, HTML rendering.
2. **For each boundary, walk** [references/owasp.md](references/owasp.md) — only the rows that apply.
3. **Check the stack rules:** [references/stacks.md](references/stacks.md) (Laravel, FastAPI, React).
4. **Report each finding** as: `file:line · class (e.g. IDOR) · how it's exploited in one sentence · fix · severity`. Use `blocking:` for anything exploitable (see `code-review` comment labels).
5. **Every fix gets a regression test** that fails without it (e.g. second user gets 403).

## The rules that catch most bugs
- **Authorize the object, not just the user.** Every handler that takes an ID checks ownership/tenant (`$this->authorize()`, policy, `WHERE tenant_id = :t`).
- **Never build queries, commands or templates from strings.** Bind parameters; use arrays for process args.
- **Validate input with a schema at the edge;** reject unknown fields; whitelist what can be mass-assigned.
- **Encode output by default;** raw HTML only from trusted, sanitised sources.
- **Don't fetch user-supplied URLs** without an allow-list and blocking private IP ranges.
- **Verify every webhook** (signature + timestamp + dedupe) before parsing the body.
- **Secrets come from config,** never code; errors never echo secrets, stack traces or SQL.

## Hard rules
- Defensive only: demonstrate a finding with a local test, never against a live system.
- Don't "fix" by hiding: removing an error message isn't fixing the authorization bug behind it.
