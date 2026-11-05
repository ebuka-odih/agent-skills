# Syncing and conflicts

## Keep the branch current
```bash
git fetch origin
git rebase origin/main
# resolve conflicts → git add <files> → git rebase --continue
git push --force-with-lease          # only on YOUR branch, only after a rebase
```

## Resolving conflicts
1. Read both sides; understand why each changed (`git log -p origin/main -- <file>`).
2. Keep both intents where possible; never silently drop the other side.
3. Re-run tests after resolving — a clean merge can still be a broken build.
4. Unsure which side is right → stop and ask the user, with the two versions shown.

## Abort when it goes wrong
`git rebase --abort` · `git merge --abort` · `git reflog` to find the previous state.

## Never
- `git push --force` (without lease) — the hook blocks it on main/master.
- `git pull` with merge commits into feature branches (use `--rebase` or `--ff-only`).
- Resolve a conflict by deleting tests or checks.
