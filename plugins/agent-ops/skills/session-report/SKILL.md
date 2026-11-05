---
name: session-report
description: Read the .agent-log session logs and report what agents actually did — prompts, tool calls, files changed, failures, gate blocks — and where the final claims differ from the goal. Use when the user asks "what did the agent do", "show me the log", "audit this session", "why did it say done", "summarize yesterday's work", or after a long or unattended run.
---

# Session report

## Steps
1. Find logs: `ls -t .agent-log/sessions/`. Pick by date or session ID the user names; default = most recent.
2. Generate the summary:
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/report.sh" .agent-log/sessions/<file>.jsonl
   ```
   If `CLAUDE_PLUGIN_ROOT` is unset, find `report.sh` under `~/.claude/plugins/` (`find ~/.claude/plugins -name report.sh -path '*agent-ops*'`).
3. Read the matching goal file (`.agent-log/goals/` by date, or `.agent-log/GOAL.md`).
4. Compare and report, in this order:
   1. **Goal** — the user's verbatim request
   2. **Gaps** — criteria not PASS; claims in `stop` events with no matching tool evidence; requested items with no criterion
   3. **Failures** — tool calls with `ok:false`, and whether a later call fixed them
   4. **Gate blocks** — times the done-gate stopped the agent, and how it resolved
   5. **Activity** — counts by tool, files written/edited, commands run

## Gap tests
| Gap | How to spot it |
|---|---|
| Claimed tests pass, no test run after last edit | last `Edit`/`Write` ts > last test-command ts |
| Claimed "done", goal partial | `stop` event `goal_status` ≠ `done` |
| File claimed changed, never touched | path in claim, not in any `Edit`/`Write` event |
| Error ignored | `ok:false` with no later successful call of the same command |

Keep the report under 40 lines. Link the log file path so the user can open it.
