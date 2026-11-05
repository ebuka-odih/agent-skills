---
name: goal-contract
description: Turn the user's request into a written goal with checkable acceptance criteria before starting work, saved to .agent-log/GOAL.md. Use at the start of any task that edits files or takes more than one step, when the user says "here's what I want", "build X", "fix Y", or when the goal is vague and "done" would be a matter of opinion.
---

# Goal contract

Write down what "done" means **before** doing the work, in terms a command or a reader can check.

## Steps
1. If `.agent-log/GOAL.md` exists with `status: active` and a different goal: move it to `.agent-log/goals/<YYYY-MM-DD>-<slug>.md` with `status: abandoned` or `superseded`, and tell the user.
2. Copy [templates/GOAL.md](templates/GOAL.md) to `.agent-log/GOAL.md`.
3. **Goal:** the user's words, quoted. Then one line restating it in your words.
4. **Acceptance criteria:** 2–7 lines. Each one:
   - starts with an ID (`C1`, `C2`…)
   - describes an observable outcome, not an activity ("`GET /health` returns 200", not "add health route")
   - names its **check**: a command, a file to inspect, or `manual: <what the user looks at>`
5. **Out of scope:** what you will not do, so it can't be mistaken for a miss.
6. If a criterion is a guess about what the user wants, show the criteria to the user and ask before starting. Otherwise start.

## Good vs bad criteria
| Bad (unverifiable) | Good (checkable) |
|---|---|
| Auth works | C1: `php artisan test --filter=LoginTest` passes · check: that command |
| Code is clean | C2: `npm run lint` exits 0 · check: that command |
| Docs updated | C3: README "Install" section lists `pnpm i` · check: README.md |
| UI looks right | C4: manual: user opens /settings and sees the new toggle |

## Hard rules
- Every criterion has a check. No check → rewrite it or drop it.
- The user's original words stay in the file verbatim. Never paraphrase them away.
- Changing the criteria mid-task requires telling the user what changed and why; log it under "Changes" in GOAL.md.
