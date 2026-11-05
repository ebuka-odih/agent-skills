---
name: commits
description: Write commits a teammate can read and revert — Conventional Commit messages (type(scope): summary), one logical change per commit, task and requirement references, staging only this task's files, and never committing secrets or generated output. Use before every git commit, when the user says "commit this", "write a commit message", "squash", "amend", or when the collaboration hook rejects a message.
---

# Commits

## Steps
1. **Review what's staged** — `git status -sb`, `git diff --staged --stat`. Stage only files for this change: `git add <paths>`. Unrelated changes stay unstaged.
2. **Check for things that must never be committed** — [references/never-commit.md](references/never-commit.md). Any hit → unstage and tell the user.
3. **One logical change per commit.** Two unrelated changes → two commits (`git add -p` to split).
4. **Tests pass** for what's staged (run the project's fast suite).
5. **Find the task** — branch `type/T<id>-slug` → that task in `docs/plan/PLAN.md`; its `covers:` gives the requirement IDs. The footer `Refs: T<id>, R<n>` is **required** on task branches (the hook enforces it).
6. **Write the message** — [references/conventional-commits.md](references/conventional-commits.md):
   ```
   feat(bookings): let members cancel up to 2 h before class

   Refund is issued in the same transaction; late cancels return 422
   with a reason the UI shows.

   Refs: T7, R7
   ```
7. Commit with a heredoc so formatting survives: `git commit -F - <<'EOF' … EOF`.
8. Add any attribution trailer the environment requires (e.g. `Co-Authored-By:`) as the last lines.

## Amend and fixups
- Not pushed yet → `git commit --amend` or `git commit --fixup <sha>` + `git rebase -i --autosquash` (interactive rebase may be unavailable to agents — use `--fixup` and let squash-merge fold it).
- Already pushed to a shared branch → new commit, never amend.

## Hard rules
- Subject: imperative, ≤ 72 chars, no trailing period, says *what changes for the user/system*, not "update files".
- Never `--no-verify`. A failing hook is information.
- Never commit with "WIP", "fix", "stuff", "changes" as the whole subject.
