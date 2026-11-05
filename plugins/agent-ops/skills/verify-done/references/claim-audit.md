# Claim audit — check your final message before sending

Read your draft final message. For every sentence that claims something happened, find its proof.

| Claim words | Must point to |
|---|---|
| "done", "complete", "finished" | GOAL.md `status: done` |
| "fixed", "works", "resolved" | A PASS evidence line for that behavior |
| "tested", "tests pass" | The test command run after the last edit |
| "updated X", "added Y" | The file path, and it exists in the diff |
| "no errors", "clean" | The command that would show errors, run last |

## Rewrite rules
- Claim with no proof → delete it, or change to "not verified: …".
- Partial work → lead with what's missing.
- Did something the user didn't ask for → say so.
- Skipped something the user asked for → say so, first.

## Session log cross-check
The session log `.agent-log/sessions/*.jsonl` (today, this session) lists every tool call. If you claim you ran a command, it must appear there as `"event":"tool"` with `"ok":true`. To see the failures:
```bash
jq -c 'select(.event=="tool" and .ok==false) | {ts,tool,summary}' .agent-log/sessions/<file>.jsonl
```
