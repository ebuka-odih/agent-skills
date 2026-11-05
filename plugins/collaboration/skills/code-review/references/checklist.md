# Review checklist

## Does it do what was asked
- [ ] Every acceptance criterion maps to code + a test
- [ ] Nothing extra the task didn't ask for (scope creep → separate PR)
- [ ] "Not done" section is honest; claims in the body have evidence

## Correctness
- [ ] Null/empty/large inputs; time zones; money as integers; off-by-one
- [ ] Errors handled at the right layer; no swallowed exceptions
- [ ] Concurrency: double submit, retries, idempotency of jobs/webhooks
- [ ] Migrations backward-compatible (expand → migrate → contract)

## Fits the architecture
- [ ] No imports across forbidden module boundaries; no reads of another module's tables
- [ ] New dependency/service/queue is in ARCHITECTURE.md or has an ADR
- [ ] AI changes: feature card exists, tier not model name, schema-validated output, eval run attached

## Safety
- [ ] New endpoints authenticated and authorised (object-level, tenant-scoped)
- [ ] Input validated; output encoded; no raw SQL with user input
- [ ] No secrets, tokens, local paths or PII in code, logs or fixtures

## Tests
- [ ] Tests fail without the change (spot-check one by reasoning or running)
- [ ] No deleted or skipped tests without a reason in the PR
- [ ] AI code: fakes in unit tests (no real model calls)

## Clarity
- [ ] Names say what things are; functions do one thing
- [ ] No dead code, debug prints, commented-out blocks
- [ ] Comments explain why, not what
