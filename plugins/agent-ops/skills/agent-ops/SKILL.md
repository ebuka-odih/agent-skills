---
name: agent-ops
description: How agent work is logged, goal-tracked and verified in every project. Use at the start of any multi-step task, when the user asks "what did the agent do", "show the log", "is it actually done", "why does it say done when it isn't", or before claiming a task is complete. Explains the .agent-log/ folder written by this plugin's hooks and routes to goal-contract, verify-done and session-report.
---

# Agent ops (orchestrator)

Closes the gap between **what the agent says is done** and **what the goal was**. Three parts:

```
agent-ops/skills/
├── agent-ops/        ← you are here: the system and the rules
├── goal-contract/    START of a task: write the goal + checkable acceptance criteria
├── verify-done/      END of a task: prove each criterion with evidence before saying "done"
└── session-report/   AFTER: read the log, compare claims vs actions
```

## What the hooks record automatically (no action needed)

Every event goes to `.agent-log/sessions/<YYYY-MM-DD>_<session-id>.jsonl` in the project, one JSON object per line:

| Event | Recorded |
|---|---|
| `session_start` | time, cwd, git branch + commit |
| `prompt` | the user's request, verbatim |
| `tool` | tool name, input summary, success/failure, output excerpt (secrets redacted, ≤ 2 KB) |
| `subagent_stop` | a sub-agent finished |
| `stop` | the agent's final message (its **claim**) + goal status at that moment |
| `gate_block` | the done-gate refused to let the agent stop, and why |

## The loop you must follow on any task with more than one step

1. **Before working:** load `goal-contract`. Write `.agent-log/GOAL.md`.
2. **While working:** tick nothing in GOAL.md by hand without evidence.
3. **Before saying done:** load `verify-done`. Every criterion gets PASS / FAIL / BLOCKED with evidence.
4. **Hooks enforce this loop:**
   - `goal-nudge` (every prompt) reminds you of step 1, or lists the open criteria of the active goal.
   - `done-gate` (Stop) blocks ending the turn once when either: GOAL.md is `active` with unticked criteria, **or** you edited project files this turn without writing/touching a goal. Verify, mark criteria `BLOCKED: <reason>`, or write the missing goal — then tell the user.

Skip steps 1 and 3 only for single-command answers and pure questions.

## Hard rules
- "Done" means every criterion in GOAL.md is PASS with evidence the user can re-check. Anything else is "partly done" — say which parts.
- Evidence is a command + its result, a file:line, or a log entry. "I implemented it" is not evidence.
- Never delete or edit `.agent-log/sessions/*.jsonl`.
- If what you did differs from what the user asked, say so first in your final message.

## Hand-off (project loop)
Skills share work through files, not memory. When this skill's output is written, log it and let the loop pick the next step:
`bash <product plugin>/scripts/loop.sh log build "goal verified"` then `loop.sh next` (skill `product:project-loop`). If an input file this skill needs is missing, name it and the skill that writes it instead of guessing.
