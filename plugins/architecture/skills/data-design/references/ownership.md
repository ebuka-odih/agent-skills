# Ownership and identifiers

## Ownership
- Every table belongs to exactly one module. Record it: `invoices, invoice_lines → billing`.
- Other modules read through the owner's interface, or through a read model the owner publishes.
- Cross-module foreign keys are allowed inside a monolith only toward a module you already depend on.
- In services: no shared database. Each service owns its schema and nobody else connects to it.

## Identifiers
| Use | Default |
|---|---|
| Primary keys | UUIDv7 (time-ordered, index-friendly) or bigint identity if the stack expects it |
| Public / URL identifiers | UUIDv7 or prefixed IDs (`inv_01H…`). Never expose sequential integers |
| External references (Stripe, etc.) | Store in their own column; never reuse as your key |

## Money, time, and text
- Money: integer minor units + currency code. Never floats.
- Time: store UTC (`timestamptz`), convert at the edge.
- Text: UTF-8 everywhere; collation chosen deliberately.
