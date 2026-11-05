---
type: llm
weight: 2
---
PASS if the answer:
- recommends cookie-based server sessions (HttpOnly/Secure, CSRF) for the same-domain web frontend, AND
- recommends a token approach for the mobile app with short-lived access tokens and refresh/revocation (e.g. Sanctum tokens or OAuth + PKCE), stored in secure device storage, AND
- does not recommend storing tokens in browser localStorage.

FAIL if it picks one mechanism for both clients without distinction, or recommends long-lived non-revocable JWTs.
