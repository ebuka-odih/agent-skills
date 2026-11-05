# Authentication — who are you

## Build vs buy
| Situation | Choose |
|---|---|
| Single web app, framework has mature auth (Laravel, Rails, Django, Next + Auth.js) | Framework auth |
| B2B with enterprise SSO (SAML/OIDC), SCIM, many orgs | Managed IdP (WorkOS, Auth0, Clerk, Cognito) |
| Several apps sharing one login | Central IdP via OIDC |
| Data residency / air-gapped | Self-hosted (Keycloak, Ory, Zitadel) |

## Mechanism per client
| Client | Default |
|---|---|
| Browser, same-site backend | Server session in `HttpOnly; Secure; SameSite=Lax` cookie + CSRF |
| Browser SPA on another domain | BFF: SPA → its own backend holding the session. No tokens in localStorage |
| Mobile app | OAuth 2.1 Auth Code + PKCE; short access token, rotating refresh token in secure storage |
| Third-party API consumers | Scoped API keys, hashed at rest, or OAuth client credentials |
| Service to service | mTLS or short-lived workload-identity tokens. No shared static secrets |

## JWT rules (only where JWTs are used)
- Access token ≤ 15 min. Refresh tokens rotate and are revocable server-side.
- Validate `iss`, `aud`, `exp`, `nbf`; algorithm allow-list; reject `alg: none`.
- Asymmetric signing (ES256/EdDSA/RS256) when more than one service verifies.
- Identity and coarse claims only — not permissions that change often.

## Login methods
- **Passwords:** argon2id or bcrypt, breached-password check, rate limit + lockout
- **Passkeys/WebAuthn:** offer as primary where possible
- **Magic links:** single use, ≤ 15 min, bound to requesting browser
- **Social/OIDC:** require `email_verified` before linking to an existing account
- **MFA:** required for admins; TOTP or WebAuthn; recovery codes
- **Sessions:** rotate ID on login and privilege change; "log out everywhere" works
