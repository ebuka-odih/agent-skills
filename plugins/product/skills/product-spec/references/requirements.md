# Writing requirements

## Format
```markdown
- **R7** (must) A member can cancel a booking up to 2 hours before class start and gets a full refund.
  accept: cancel at T-2h01m → booking cancelled, refund issued; cancel at T-1h59m → refused with message.
  journey: J2 · status: open
```

## Good vs bad
| Bad | Why | Good |
|---|---|---|
| The system should be user-friendly | Not checkable | A first-time member can book a class in ≤ 3 screens |
| Use Stripe for payments | Design choice | Members pay by card; payment confirmed before the booking is final |
| Handle errors | Vague | If payment fails, the seat is released within 5 minutes and the member is told why |
| Booking, cancelling, waitlist | Three things | Split into R7, R8, R9 |

## Priorities (MoSCoW)
- **must** — release fails without it
- **should** — important, release can ship without it
- **could** — nice to have
- **won't (this release)** — goes under Non-goals instead

## Non-functional requirements
Same format, prefixed `NFR`: `- **NFR2** (must) Booking page p95 load < 2 s on 4G. accept: Lighthouse/WebPageTest run on staging.`

## Status values
`open` → `in-progress` → `met` (all covering tasks done + accept check passed) · `dropped` (with reason) · `changed` (see change log)
