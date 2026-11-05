---
name: property-based
description: Write property-based tests — state invariants that must hold for all inputs (bounds, monotonicity, round-trips, idempotence, equivalence with a simple model) and let the framework generate hundreds of cases and shrink failures to the smallest example. Covers Hypothesis (Python), fast-check (TypeScript) and PHP options. Use for money/fee/tax maths, date and time-zone logic, parsers and serialisers, validation, sorting/ranking, state machines; when the user says "property testing", "fuzz this function", "edge cases I haven't thought of"; or when test-strategy routes pure logic with many inputs.
---

# Property-based testing

Example tests check the cases you thought of. Properties check the rule.

## Steps
1. **Find the properties** — [references/properties.md](references/properties.md) lists the patterns. For a fee function: result is between 0 and price; never negative; 0 at ≥ 2 h; non-decreasing as cancellation gets later; integer kobo.
2. **Write generators** for valid inputs (and separately, invalid ones that must raise). Constrain to the domain: positive prices up to a realistic max, timezone-aware datetimes, non-empty strings.
3. **Write the test** — stack examples in [references/stacks.md](references/stacks.md).
4. **Keep the example tests** for named boundaries (exactly 120 minutes). Properties complement them; they don't replace them.
5. **When it fails** — the framework shrinks to a minimal input. Turn that input into a permanent example test, then fix the code.

## Hard rules
- Properties must be true by the spec, not by the current code — don't reimplement the function inside the test.
- Deterministic in CI: fixed seed or stored failing examples (Hypothesis database / fast-check `seed`) so failures reproduce.
- Default example counts in PR CI (≈100); raise them in nightly runs.
