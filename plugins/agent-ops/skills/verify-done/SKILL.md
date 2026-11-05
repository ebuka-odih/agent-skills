---
name: verify-done
description: Prove a task is finished before saying so. Checks every acceptance criterion in .agent-log/GOAL.md with fresh evidence, records PASS / FAIL / BLOCKED, and writes the honest final status. Use before any "done", "finished", "complete", "fixed", "works now" claim, when the done-gate hook blocks stopping, or when the user asks "is it really done", "did you test it", "verify".
---

# Verify done

Your memory of doing the work is not evidence. Re-check now.

## Steps
1. Read `.agent-log/GOAL.md`. No file → run the `goal-contract` skill first, using the user's original request.
2. For **each** criterion, run its check fresh — even if you ran it earlier. Follow [references/evidence.md](references/evidence.md) for what counts.
3. Record the verdict:
   - **PASS** → tick it: `- [x] C1 …` and add an Evidence line.
   - **FAIL** → leave unticked. Fix it and re-check, or report it.
   - **BLOCKED** → leave unticked, append ` — BLOCKED: <reason, what the user must do>`.
   - **manual** checks → mark `- [~]` and tell the user exactly what to look at.
4. Compare against the user's verbatim request at the top of GOAL.md. If any part of the request isn't covered by a criterion, add it and check it.
5. Run the claim audit in [references/claim-audit.md](references/claim-audit.md) on the final message you are about to send.
6. Set `status:` in GOAL.md:
   - `done` — every criterion `[x]`
   - `partial` — any `[ ]`, `[~]` or BLOCKED remain
7. Move the file to `.agent-log/goals/<YYYY-MM-DD>-<slug>.md` when status is `done` or `partial`.
8. If GOAL.md has `task:` and the project has `docs/plan/PLAN.md`: set that task to `[x]` (done), `[!] — <reason>` (blocked) or leave `[~]` (partial), and append a Progress log line pointing at the goal file. Requirement and milestone updates follow the `next-task` skill, step 4.

## Final message format
```
Done: C1, C2 (evidence in .agent-log/goals/<file>)
Not done: C3 — FAIL: <why>  |  C4 — needs you: <what to look at>
```
Lead with what is **not** done if anything is. Never write "done" when status is `partial`.

## Hard rules
- No PASS without evidence produced in this verification run.
- A test you wrote that passes proves little alone — also run the existing suite.
- Never weaken a criterion to make it pass. Changing it needs a "Changes" entry and the user told.
