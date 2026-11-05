# feat(bookings): let members cancel a booking

## Why
T7 · Cancel booking endpoint + refund (covers R7)
- **R7** (must) A member can cancel a booking up to 2 hours before class start and gets a full refund.
  accept: cancel at T-2h01m → booking cancelled, refund issued; cancel at T-1h59m → refused with message.

## What changed
- New `POST /bookings/{id}/cancel` endpoint
- Refund issued through the payments service

## Evidence
All tests pass. Works on my machine.

## Not done
Nothing.
