# Review comments

Prefix every comment with a label so the author knows what must change.

| Label | Means | Blocks merge |
|---|---|---|
| **blocking:** | Bug, security issue, broken rule, missing test for new behavior | yes |
| **suggestion:** | Better approach; author decides | no |
| **question:** | You don't understand something; may become blocking | no (until answered) |
| **nit:** | Style/naming preference | no |
| **praise:** | Something done well — say it when true | no |

## Shape of a blocking comment
```
blocking: `BookingController.php:42` — cancel() doesn't check the booking belongs to the user,
so any member can cancel anyone's booking (IDOR). Add `$this->authorize('cancel', $booking)`
and a test that a second member gets 403.
```

## Tone
- About the code, not the person: "this query runs per row" not "you wrote an N+1".
- Ask when unsure: "question: is this called from the queue too? If so it needs the tenant set."
- One comment per issue; group repeats ("same in 3 places: a.ts:10, b.ts:22, c.ts:7").
