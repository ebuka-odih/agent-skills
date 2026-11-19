---
name: next-task
description: Work a long project one task at a time from docs/plan/PLAN.md — pick the next ready task (or turn the user's chat request into plan tasks first), turn it into a GOAL.md linked to the task and its requirements, build it, verify it, then update PLAN.md, the progress log and the release so the next session can resume. Use when the user says "what's next", "continue", "keep going", "next task", "work on T7", "resume", "can you add X", "also fix Y", sends several requests in one message, or starts a session in a project with a PLAN.md.
---

# Next task

## 0. A request from chat → tasks first
Most work arrives as messages ("can you add X, also fix Y"). Before building, put it in the plan:
| Request | Do |
|---|---|
| small fix or tweak (fast path: ≤ 3 files, behaviour already stated) | no task; fix + test, then `plan.sh log "fix: <what>"` |
| one feature or bigger fix | `plan.sh add "<observable outcome>" --covers R<n>` → work that task |
| several things in one message | one `plan.sh add` per outcome, in the user's order → work them one at a time, one goal each; report the queue |
| nothing in SPEC covers it | add the requirement first (`product-spec` change mode, one line + change-log row), then `--covers` it |
| it contradicts a non-goal or reshapes a milestone | ask 🧑 before adding |
`plan.sh` lives in `${CLAUDE_PLUGIN_ROOT}/scripts/`; it keeps the task grammar exact and picks the next free ID.

## 1. Find where we are
```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/trace.sh" docs/spec/SPEC.md docs/plan/PLAN.md
```
- A task already `[~]` → resume it (read its GOAL.md / last progress-log line first).
- The user named a task → use it, if its `depends:` are done; otherwise say which blockers remain.
- Otherwise → the first **ready** task in the active milestone (see `../project-plan/references/status.md`).
- No ready task → report blockers and stop.

## 2. Open the goal
1. Mark the task in progress: `plan.sh mark T7 "~"`.
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
2. All PASS → `plan.sh mark T7 x`. Some BLOCKED → `plan.sh mark T7 "!" "<reason>"`. Partly done → stays `[~]`, note what's left.
3. `plan.sh log "T7 [x] · goal <file> · R7 accept check passed"`.
4. If every task covering a requirement is `[x]` and its accept check passed → set that requirement `status: met` in SPEC.md.
5. If the milestone's tasks are all done → run its `demo:` check; pass → milestone `done`, next one `active`.
6. Release due? (`release:` in PLAN.md: `per-feature` after a feat task, `per-milestone` when a milestone is done) → run the `versioning` skill now, ending with the user's copy verified.

## 5. Report
```
T7 done (R7 met). Milestone M2: 4/7 tasks. v0.6.0 released, verified installed. Next ready: T8 · Waitlist join.
```
Then stop, unless the user said "keep going" — then loop to step 1. Stop the loop on any BLOCKED task.

## Hard rules
- One task per goal. Never mix two tasks in one GOAL.md.
- Never tick a task without a closed goal file as evidence.
- Work outside the plan → add it as a task first (`plan.sh add`, with `covers:`), then do it. Shipped work that isn't in PLAN.md is invisible to the next session.
- Never leave a task `[!]` after its blocker is gone (e.g. "needs the product name" after the rename shipped).

## Hand-off (project loop)
Skills share work through files, not memory. When this skill's output is written, log it and let the loop pick the next step:
`bash <product plugin>/scripts/loop.sh log build "T<n> done"` then `loop.sh next` (skill `product:project-loop`). If an input file this skill needs is missing, name it and the skill that writes it instead of guessing.
