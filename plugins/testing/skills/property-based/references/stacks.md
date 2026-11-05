# Property-based testing by stack

## Python — Hypothesis
```python
from datetime import UTC, datetime, timedelta
from hypothesis import given, strategies as st

prices = st.integers(min_value=0, max_value=10_000_000)            # kobo
starts = st.datetimes(min_value=datetime(2020, 1, 1), max_value=datetime(2035, 1, 1), timezones=st.just(UTC))
offsets = st.integers(min_value=-600, max_value=10_000)             # minutes before start (negative = after)

@given(prices, starts, offsets)
def test_fee_within_bounds(price, start, mins):
    fee = late_cancel_fee_kobo(price, start, start - timedelta(minutes=mins))
    assert 0 <= fee <= price

@given(prices, starts, offsets, st.integers(min_value=1, max_value=600))
def test_cancelling_later_never_costs_less(price, start, mins, later):
    early = late_cancel_fee_kobo(price, start, start - timedelta(minutes=mins))
    late = late_cancel_fee_kobo(price, start, start - timedelta(minutes=mins - later))
    assert late >= early
```
Settings: `@settings(max_examples=100)` in PR CI; profile with more in nightly (`settings.register_profile`). Failures are saved in `.hypothesis/` — gitignore it, or commit a `@example(...)` for each found bug.

## TypeScript — fast-check
```ts
import fc from 'fast-check';
it('fee stays within bounds', () => {
  fc.assert(fc.property(fc.integer({ min: 0, max: 10_000_000 }), fc.integer({ min: -600, max: 10_000 }),
    (price, mins) => { const fee = lateCancelFee(price, mins); return fee >= 0 && fee <= price; }));
});
```
Reproduce: failures print `seed` and `path`; pass `{ seed, path }` to `fc.assert` to replay.

## PHP
No dominant library. Options: `giorgiosironi/eris` (PHPUnit generators) or Pest datasets generated from a seeded loop:
```php
dataset('prices', fn () => collect(range(1, 200))->map(fn ($i) => [mt_rand(0, 10_000_000)])->all()); // seed with mt_srand() in a beforeAll
it('fee within bounds', fn (int $price) => expect(fee($price, minutesBefore: 30))->toBeBetween(0, $price))->with('prices');
```
Prefer pushing complex pure logic into small functions that are easy to cover this way.
