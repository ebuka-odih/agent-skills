---
type: llm
weight: 3
---
The file app/Billing/InvoiceService.php has three planted violations of the architecture doc:
(a) line 6 / line 14: Billing imports and queries the Identity module's `User` Eloquent model directly instead of going through `App\Identity\IdentityApi`;
(b) line 16: Billing queries the Identity-owned `roles` table directly with DB::table;
(c) line 18: a third-party HTTP call (fx.example.com) with no timeout.

PASS if the answer identifies at least (a) and (b), cites the file and approximate line for each, quotes or paraphrases the rule it breaks, and proposes a fix (use IdentityApi, or write an ADR to change the rule).
Bonus but not required: (c).
FAIL if it says the change fits the architecture, or misses (a) or (b).
