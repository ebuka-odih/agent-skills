---
name: git-workflow
description: How work moves through git on every project — branch per task, naming, syncing with main, pushing, opening and merging PRs, and what never to do (force-push shared branches, commit secrets, commit to main). Use whenever the agent is about to create a branch, commit, push, rebase, merge or open a PR, when the user says "push this", "commit", "open a PR", "ship it", "make a branch", "sync with main", or when a teammate workflow question comes up. Routes to commits, pull-requests, code-review and repo-setup.
---

# Git workflow (orchestrator)

One task → one branch → small commits → one PR → review → squash-merge. Everything links back to the plan and the goal so a reviewer can see *what was asked, what was done, and the proof*.

```
collaboration/skills/
├── git-workflow/   ← you are here: the lifecycle and the hard rules
├── commits/        message format, atomic commits, what never goes in
├── pull-requests/  size, description from PLAN + GOAL evidence, checks, merge
├── code-review/    reviewing others' (or an agent's) PRs; comment labels; approval
└── repo-setup/     PR template, CODEOWNERS, branch protection, CI checks for a repo
```

House defaults: [references/defaults.md](references/defaults.md) — edit to change the team's rules.

## The lifecycle
| Step | Do | Skill |
|---|---|---|
| 1. Start | Sync main, create `type/T<id>-slug` branch from it ([references/branching.md](references/branching.md)) | — |
| 2. Work | Small commits, each passes tests, Conventional Commit messages | `commits` |
| 3. Sync | Rebase onto `origin/main` before pushing if main moved ([references/sync.md](references/sync.md)) | — |
| 4. Verify | `verify-done` (agent-ops) — goal criteria have evidence | agent-ops |
| 5. Push + PR | Push branch, open PR with body built from PLAN + GOAL | `pull-requests` |
| 6. Review | Self-review first, then reviewer; address every blocking comment | `code-review` |
| 7. Merge | Squash-merge when checks green + approved; delete branch; update PLAN progress log | `pull-requests` |

## Before any git command, check
1. **Where am I?** `git status -sb` and `git branch --show-current`. On `main` with changes → create a branch first and carry the changes over (`git switch -c …`).
2. **Whose work is this?** Never stage or discard changes you didn't make. Commit only the files for this task (`git add <paths>`, not `git add -A`, when the tree has unrelated changes).
3. **Did the user ask?** Commit / push / open PR / merge only when the user asked, or when project instructions say to.

## Hard rules
- Never force-push `main`/`master` or anyone else's branch. On your own branch use `--force-with-lease` only.
- Never commit secrets, `.env`, credentials, large binaries or generated build output.
- Never bypass hooks (`--no-verify`) or CI to make a merge happen.
- Never rewrite published history on a shared branch without the user's explicit yes.
- Every PR links its task (`T<id>`), and every claim in it has evidence.

The `collaboration` hook enforces the first rule and the commit-message format, and asks before committing straight to `main`.
