# agent-ops

Makes agent work auditable and stops "done" claims that don't match the goal.

| Part | Kind | Does |
|---|---|---|
| `log-event.sh` | hook (SessionStart, UserPromptSubmit, PostToolUse, SubagentStop, Stop, SessionEnd) | Appends one JSON line per event to `.agent-log/sessions/<date>_<session>.jsonl` |
| `goal-nudge.sh` | hook (UserPromptSubmit) | Injects "write GOAL.md first, verify before done" into the agent's context, or lists the active goal's open criteria |
| `done-gate.sh` | hook (Stop) | Blocks ending the turn once if GOAL.md is `active` with unticked criteria, or if files were edited this turn with no goal contract |
| `agent-ops` | skill (orchestrator) | Explains the system and the work loop |
| `goal-contract` | skill | Writes GOAL.md: verbatim request + checkable acceptance criteria |
| `verify-done` | skill | Re-checks every criterion with fresh evidence; honest final status |
| `session-report` | skill + `report.sh` | Summarises a session log and flags claim-vs-action gaps |

Requires `jq` (preinstalled on macOS). Disable the gate for one session with `AGENT_OPS_GATE=off`.

Tests: `bash tests/run.sh` (hook scripts) and `claude plugin eval . --allow-tools Write Edit Bash` (skills).
