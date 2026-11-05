# Testing by stack

## Laravel (Pest/PHPUnit)
```php
it('refunds in full when cancelled 2 hours before class', function () {
    $this->travelTo(now());
    $booking = Booking::factory()->for($member = Member::factory()->create())
        ->forClassStartingIn(minutes: 121)->create();
    Payments::fake();

    $this->actingAs($member)->postJson("/bookings/{$booking->id}/cancel")
        ->assertOk()->assertJsonPath('data.status', 'cancelled');

    Payments::assertRefunded($booking->payment_id, $booking->amount_cents);
});

it('forbids cancelling another member\'s booking', function () { /* assertForbidden() */ });
```
`RefreshDatabase` · factories with states · `Http::fake()`, `Queue::fake()`, `Mail::fake()`, `Agent::fake()->preventStrayPrompts()` · arch tests: `arch()->expect('App\Billing')->not->toUse('App\Identity\Models')`.

## FastAPI (pytest)
```python
async def test_refunds_in_full_before_cutoff(client, member, booking_factory, payments_fake, frozen_now):
    booking = await booking_factory(member=member, starts_in_minutes=121)
    r = await client.post(f"/bookings/{booking.id}/cancel", headers=member.auth)
    assert r.status_code == 200 and r.json()["status"] == "cancelled"
    assert payments_fake.refunds == [(booking.payment_id, booking.amount_cents)]
```
`httpx.AsyncClient(transport=ASGITransport(app))` · `app.dependency_overrides` · transactional test DB fixture · `respx` / `pytest-httpx` · `freezegun`/`time-machine` · `pydantic_ai.models.ALLOW_MODEL_REQUESTS = False` + `TestModel`.

## TypeScript / React (Vitest + Testing Library)
```tsx
it('shows the refund amount after cancelling', async () => {
  server.use(http.post('/api/bookings/1/cancel', () => HttpResponse.json({ status: 'cancelled', refund: 1200 })));
  render(<BookingCard booking={booking} />);
  await userEvent.click(screen.getByRole('button', { name: /cancel booking/i }));
  expect(await screen.findByText(/refund of ₦12\.00/i)).toBeInTheDocument();
});
```
MSW for network · `vi.useFakeTimers()` for time · query by role/label/text · Playwright for E2E with seeded data.
