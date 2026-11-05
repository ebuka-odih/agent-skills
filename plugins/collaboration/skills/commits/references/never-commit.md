# Never commit

Check `git diff --staged --name-only` and the staged content.

| What | How to spot | Do |
|---|---|---|
| Secrets | `.env`, `*.pem`, `*.key`, `id_rsa`, `credentials.json`; strings like `sk-`, `ghp_`, `AKIA`, `xox`, `-----BEGIN` | Unstage; rotate the secret if it was ever committed |
| Local paths / usernames | `/Users/<name>/`, `/home/<name>/`, `C:\Users\` | Replace with relative paths or env vars |
| Generated output | `dist/`, `build/`, `node_modules/`, `vendor/` (unless the project commits it), `__pycache__/`, coverage reports | Add to `.gitignore` |
| Large binaries | files > 5 MB, media, datasets, DB dumps | Git LFS or object storage |
| Agent scratch | `.agent-log/sessions/`, eval `results/`, temp files | Already gitignored by agent-ops; check |
| Other people's work | files you didn't change for this task | Leave unstaged |

Quick scan before committing:
```bash
git diff --staged --name-only
git diff --staged | grep -nE 'sk-[A-Za-z0-9]{16}|ghp_[A-Za-z0-9]{20}|AKIA[A-Z0-9]{12}|-----BEGIN [A-Z ]*PRIVATE KEY|/Users/[a-z]+/'
```
