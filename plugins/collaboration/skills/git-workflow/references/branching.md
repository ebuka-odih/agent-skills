# Starting a branch

```bash
git fetch origin
git switch main && git pull --ff-only          # or: git switch -c <branch> origin/main
git switch -c feat/T7-cancel-booking
```

## Naming
- Task from `docs/plan/PLAN.md` → `<type>/T<id>-<slug>`; the slug is 2–5 words from the task title.
- No plan → `<type>/<slug>`; bug from an issue → `fix/<issue-number>-<slug>`.
- Lowercase, hyphens, no spaces, ≤ 50 chars.

## Type from the task
| Task is | Type |
|---|---|
| New user-visible behavior | `feat` |
| Wrong behavior fixed | `fix` |
| Same behavior, better code | `refactor` |
| Faster | `perf` |
| Tests only | `test` |
| Docs only | `docs` |
| Build/deps | `build` |
| CI config | `ci` |

## Already on main with changes?
```bash
git switch -c feat/T7-cancel-booking     # moves uncommitted changes onto the new branch
```
Committed on main by mistake but not pushed:
```bash
git branch feat/T7-cancel-booking        # keep the commits on a branch
git reset --keep origin/main             # move main back (keeps working-tree changes)
git switch feat/T7-cancel-booking
```
Confirm with the user before resetting anything.
