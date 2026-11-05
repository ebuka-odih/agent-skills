# Collaboration house defaults

Edit this file to change the team's rules. Project-level overrides go in the project's `AGENTS.md` / `CLAUDE.md` under "## Git".

| Topic | Default |
|---|---|
| Branching model | Trunk-based: `main` is always deployable; short-lived branches (≤ 3 days) |
| Branch name | `<type>/<task-id>-<slug>` e.g. `feat/T7-cancel-booking`; no task → `<type>/<slug>` |
| Types | `feat` `fix` `refactor` `perf` `test` `docs` `build` `ci` `chore` `revert` |
| Commit format | Conventional Commits: `type(scope)!: summary` ≤ 72 chars, imperative |
| Commit body | Why + what changed; `Refs: T7, R3` footer when a plan exists |
| Sync | Rebase your branch on `origin/main`; never merge `main` into a feature branch |
| PR size | ≤ 400 changed lines (excluding lockfiles/generated); larger → split or explain |
| PR title | Same format as a commit subject (it becomes the squash commit) |
| Merge | Squash-merge; delete branch after merge |
| Required checks | Tests, lint, type-check; evals when prompts/models change (ai-engineering) |
| Reviews | 1 approval; 2 for auth, payments, data migrations, infra |
| Protected | `main`: no direct pushes, no force-push, checks required, linear history |
| Draft PRs | Open as draft early for visibility; mark ready when verify-done passes |
| Releases | Tag `vX.Y.Z` from `main`; changelog from Conventional Commits |
