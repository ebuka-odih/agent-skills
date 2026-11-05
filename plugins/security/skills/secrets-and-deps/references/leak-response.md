# Secret leak response

1. **Rotate now.** Create a new key in the provider console, deploy it, revoke the old one. (The agent can't do this for you — tell the user exactly which key and where.)
2. **Verify** the old key is dead (a request with it fails) and the app works with the new one.
3. **Check for use** — provider audit logs / billing for activity since the leak.
4. **Remove from the code** — move to config/env; commit `fix(security): move <name> to environment config`.
5. **History** — if the repo is public or shared, the secret is in history: clean with `git filter-repo` / BFG **only after rotation and with the user's explicit OK** (force-push rewrites everyone's history). Private repo with rotation done → cleaning is optional.
6. **Record** in SECURITY.md: what leaked, when, rotated when, impact found.

Never: "fix" by deleting the line only · paste the secret into chat/issues while reporting it · rewrite shared history without approval.
