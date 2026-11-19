# Plan status rules

## Task line grammar (parsed by scripts — keep it exact)
```
- [<mark>] T<n> · <title> · covers: <R1,R3|NFR2|setup> · depends: <T2,T5|-> · size: <S|M>[ — <note>]
```
Marks: ` ` todo · `~` in progress · `x` done · `!` blocked · `-` dropped

## Milestone heading grammar
```
## M<n> — <name> · status: <planned|active|done|released>
goal: <one sentence>
demo: <check>
released: v0.3.0 · 2026-11-19        ← written by `plan.sh released`, never by hand
```
Exactly one milestone is `active`. When all its tasks are `x`/`-` and the demo passes, set it `done` and the next one `active`. When the build ships, `plan.sh released M<n> v<version>` sets `released`.

## Edit with plan.sh
`plan.sh add | mark | released | log` (product plugin `scripts/`) writes this grammar exactly; prefer it to hand edits.

## A task is "ready" when
- it is `[ ]`, in the active milestone, and
- every task in `depends:` is `[x]`.

## Progress log
Append one line to `## Progress log` at the bottom whenever a task changes state or a version ships (`plan.sh log`, `plan.sh released`):
```
- 2026-11-05 · T7 [x] · goal .agent-log/goals/2026-11-05-t7-cancel-booking.md · R7 accept check passed
```
This is what lets the next session pick up exactly where the last one stopped.
