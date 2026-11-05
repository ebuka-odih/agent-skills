# What counts as evidence

| Criterion type | Evidence | Example Evidence line |
|---|---|---|
| Command must succeed | The command, its exit code, the key output line | `C1: PASS — php artisan test --filter=Login → exit 0, "Tests: 6 passed"` |
| File must contain X | path:line and the quoted line | `C3: PASS — README.md:14 "pnpm i"` |
| Behavior in a running app | Request + response (curl), or screenshot path | `C2: PASS — curl -s localhost:8000/health → 200 {"ok":true}` |
| Something must NOT happen | The search or test that would find it, and its empty result | `C5: PASS — grep -rn "dd(" app/ → no matches` |
| Manual | Exactly what the user must open and look for | `C4: NEEDS USER — open /settings, expect "Dark mode" toggle` |

## Not evidence
- "I added / implemented / updated …"
- A command run before the last code change
- A passing test that doesn't exercise the criterion
- Output you summarised but didn't run in this session
- Type-check or build success used as proof of behavior
