# Naming conventions by stack

| Thing | PHP / Laravel | Python | TypeScript / React |
|---|---|---|---|
| Files | `PascalCase.php` (one class) | `snake_case.py` | components `PascalCase.tsx`, others `kebab-case.ts` or `camelCase.ts` (follow repo) |
| Classes / types | `PascalCase` | `PascalCase` | `PascalCase` |
| Functions / methods | `camelCase` | `snake_case` | `camelCase` |
| Variables | `$camelCase` | `snake_case` | `camelCase` |
| Constants | `UPPER_SNAKE` / enum cases `PascalCase` | `UPPER_SNAKE` | `UPPER_SNAKE` or `camelCase` const (follow repo) |
| DB tables / columns | `snake_case` plural tables | `snake_case` | — |
| Routes / URLs | `kebab-case`, plural nouns | same | same |
| Tests | `CancelBookingTest.php`, `it('refunds in full…')` | `test_cancel_booking.py`, `def test_refunds_in_full_before_cutoff()` | `cancel-booking.test.ts`, `it('refunds in full…')` |
| React hooks | — | — | `useThing` |
| Events | `BookingCancelled` | `BookingCancelled` | `bookingCancelled` |

## Good vs bad
| Bad | Better | Why |
|---|---|---|
| `processData()` | `importMenuFromPdf()` | Says what and from where |
| `$flag` | `$isRefundable` | Boolean reads as a question |
| `handle2`, `newFoo` | `cancelLateBooking` | Describes the difference |
| `UserManager` | `MemberSubscriptions` | Domain word, single responsibility |
| `temp`, `x`, `res` (beyond 3 lines) | `pendingRefund`, `response` | Scope-length rule: longer life → longer name |

Abbreviations only when universal in the domain (`id`, `url`, `api`, `vat`).
