# Property patterns

| Pattern | Statement | Example |
|---|---|---|
| **Bounds** | output always within a range | `0 <= fee(price, t) <= price` |
| **Type/shape** | output always has the right form | fee is an `int`; slug matches `^[a-z0-9-]+$` |
| **Monotonicity** | more input → never less output | cancelling later never lowers the fee |
| **Round-trip** | `decode(encode(x)) == x` | JSON/money formatting/parsing |
| **Idempotence** | `f(f(x)) == f(x)` | normalising phone numbers, slugify, dedupe |
| **Invariant under transformation** | reordering/case/whitespace doesn't change result | search tokenizer, set operations |
| **Oracle / model** | matches a simple slow reference | optimised ranking vs naive sort |
| **Conservation** | totals preserved | splitting a bill: parts sum to the total, no kobo lost |
| **Never crashes on valid input** | no exception for any valid value | parsers, validators |
| **Rejects invalid input** | specific error for every invalid value | naive datetimes → `ValueError` |
| **State machine** | any sequence of valid actions keeps invariants | booking: can't be both cancelled and attended |
