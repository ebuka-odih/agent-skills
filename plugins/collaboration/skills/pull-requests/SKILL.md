---
name: pull-requests
description: Open pull requests a reviewer can approve quickly — right size, title in Conventional Commit form, a body built from the PLAN task, the GOAL acceptance criteria and their evidence, architecture/AI impact, test and eval results, screenshots for UI, and honest "not done" items; then handle checks, review rounds and squash-merge. Use when the user says "open a PR", "create a pull request", "write the PR description", "ship this", "merge it", or after verify-done passes on a branch.
---

# Pull requests

## 1. Before opening
- `verify-done` has run for the goal (agent-ops) — or run it now.
- Branch is rebased on `origin/main`, tests pass locally.
- Size check: `git diff --stat origin/main...HEAD`. > 400 changed lines (excluding lockfiles/generated) → split ([references/sizing.md](references/sizing.md)) or say why in the body.

## 2. Build the body
Run the prep script — it fills what it can from the repo:
```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/pr-prep.sh" > /tmp/pr-body.md
```
It reads the task ID from the branch name, the task and requirements from `docs/plan/PLAN.md` / `docs/spec/SPEC.md`, the newest goal file for that task from `.agent-log/goals/`, diff size, and whether ARCHITECTURE.md / AI.md areas changed. Then edit by hand into [templates/PULL_REQUEST.md](templates/PULL_REQUEST.md) shape: **Why · What changed · Evidence · Not done · Risk · How to review**.

## 3. Open
```bash
git push -u origin HEAD
gh pr create --title "feat(bookings): let members cancel up to 2 h before class" --body-file /tmp/pr-body.md [--draft]
```
Title = the squash commit subject. Draft until checks pass and evidence is in. Add any attribution line the environment requires at the end of the body.

## 4. Checks and review
- Failing check → read the log, fix on the branch, push; never re-run until green by luck.
- Each review comment: fix, or reply with why not. Resolve only your own threads after fixing.
- Re-request review after substantive changes.

## 5. Merge (only when the user asks, or project rules allow)
Checks green + required approvals → squash-merge → delete branch → append to PLAN.md progress log: `· T7 [x] · PR #<n> merged`.

## Hard rules
- Evidence section lists commands and results, not adjectives. Copy from the goal file.
- "Not done" is mandatory — write "nothing" only if every criterion passed.
- Architecture or AI changes → run the check mode from `system-design` / `ai-design` and paste the result.
- Never merge your own PR without approval when the repo requires review.
