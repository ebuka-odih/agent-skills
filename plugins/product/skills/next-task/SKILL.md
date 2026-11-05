---
name: next-task
description: Work a long project one task at a time from docs/plan/PLAN.md — pick the next ready task, turn it into a GOAL.md linked to the task and its requirements, build it, verify it, then update PLAN.md and the progress log so the next session can resume. Use when the user says "what's next", "continue", "keep going", "next task", "work on T7", "resume", or starts a session in a project with a PLAN.md.
---

# Next task

## 1. Find where we are
```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/trace.sh" docs/spec/SPEC.md docs/plan/PLAN.md
```
- A task already `[~]` → resume it (read its GOAL.md / last progress-log line first).
- The user named a task → use it, if its `depends:` are done; otherwise say which blockers remain.
- Otherwise → the first **ready** task in the active milestone (see `../project-plan/references/status.md`).
- No ready task → report blockers and stop.

## 2. Open the goal
1. Mark the task `[~]` in PLAN.md.
2. Write `.agent-log/GOAL.md` — via the `goal-contract` skill if agent-ops is installed, otherwise directly in this shape:
   ```markdown
   ---
   status: active
   task: T7
   covers: R7
   ---
   # Goal
   > "<the user's request, verbatim>"
   ## Acceptance criteria
   - [ ] C1: <task outcome> · check: `<command>`
   - [ ] C2: <R7 accept line from SPEC.md> · check: <test or manual step>
   ## Evidence
   ```
3. Acceptance criteria = the task's outcome **plus** the `accept:` line of each covered requirement that this task completes, copied from SPEC.md.
4. Read the module rules in ARCHITECTURE.md for the area you'll touch.

## 3. Build
Small steps, tests with the code. If the task turns out bigger than its size → stop, split it in PLAN.md (new IDs, log under Plan changes), and finish only the first part.

## 4. Verify and close
1. Load `verify-done` if agent-ops is installed; otherwise re-run every criterion's check now and write one Evidence line each (command → result). No fresh evidence → not PASS.
2. All PASS → task `[x]`. Some BLOCKED → task `[!] — <reason>`. Partly done → stays `[~]`, note what's left.
3. Append to PLAN.md `## Progress log`: date · task · mark · goal file · requirement checks.
4. If every task covering a requirement is `[x]` and its accept check passed → set that requirement `status: met` in SPEC.md.
5. If the milestone's tasks are all done → run its `demo:` check; pass → milestone `done`, next one `active`.

## 5. Report
```
T7 done (R7 met). Milestone M2: 4/7 tasks. Next ready: T8 · Waitlist join.
```
Then stop, unless the user said "keep going" — then loop to step 1. Stop the loop on any BLOCKED task.

## Hard rules
- One task per goal. Never mix two tasks in one GOAL.md.
- Never tick a task without a closed goal file as evidence.
- Work outside the plan → add it as a task first (with `covers:`), then do it.
