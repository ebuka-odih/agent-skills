# Dependency hygiene

## Audit commands
| Stack | Command | Notes |
|---|---|---|
| PHP / Composer | `composer audit` | built into Composer 2.4+ |
| Python / uv | `uvx pip-audit` (or `uv run pip-audit`) | reads the environment / requirements |
| Python / pip | `pip-audit -r requirements.txt` | |
| Node / npm | `npm audit --omit=dev` | `pnpm audit`, `yarn npm audit` |
| Containers | `trivy image <image>` / `docker scout cves` | if images are built |
| GitHub | Dependabot alerts + `actions/dependency-review-action` on PRs | |

## Rules
- Lockfiles committed; CI installs frozen.
- Automated update PRs weekly (Dependabot/Renovate); security updates immediately.
- Pin GitHub Actions to a commit SHA for third-party actions.
- High/critical advisory → fix (upgrade/patch) or record an exception with reason and review date.

## Before adding a package
Is it needed (stdlib/existing dep)? Maintained (recent release, issues answered)? Popular enough to be scrutinised? License compatible? Install scripts (`postinstall`) reviewed? Typosquat check on the name.
