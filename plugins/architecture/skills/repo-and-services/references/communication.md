# Communication between parts

| Need | Use | Must have |
|---|---|---|
| Caller needs the answer now | Sync call (in-process; HTTP/gRPC across services) | Timeout, retry with backoff + jitter only if idempotent |
| Caller just needs it done | Queue a job | Idempotent handler, retry limit, dead-letter queue |
| Many parts react to one fact | Publish an event | Outbox pattern when it must match a DB commit |
| Long multi-step process across services | Saga / workflow engine (Temporal, Step Functions, Laravel job chains for in-process) | Compensating actions per step |
| Run on a schedule | Scheduler | Lock so only one instance runs (`onOneServer`, advisory lock) |

## Rules
- No synchronous chain deeper than 2 hops across services.
- Every job and event handler is idempotent: running twice equals running once.
- Events are named in past tense for facts (`InvoicePaid`), commands in imperative (`SendInvoice`).
- Record each queue/topic, its producer, consumers, and retry policy in ARCHITECTURE.md §11.
