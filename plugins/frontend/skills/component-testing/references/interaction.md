# Interaction tests (Vitest + Testing Library + user-event + MSW)

```tsx
it("filters bookings by status and resets to page 1", async () => {
  server.use(http.get("/api/bookings", ({ request }) => {
    const status = new URL(request.url).searchParams.get("status");
    return HttpResponse.json({ data: status === "cancelled" ? [cancelled] : all, total: 1 });
  }));
  const user = userEvent.setup();
  renderWithProviders(<BookingsPage />, { route: "/bookings?page=3" });

  await user.click(screen.getByRole("combobox", { name: /status/i }));
  await user.click(screen.getByRole("option", { name: /cancelled/i }));

  expect(await screen.findByRole("cell", { name: cancelled.memberName })).toBeInTheDocument();
  expect(window.location.search).toContain("page=1");
});

it("shows an error state with retry", async () => {
  server.use(http.get("/api/bookings", () => HttpResponse.json({}, { status: 500 })));
  renderWithProviders(<BookingsPage />);
  expect(await screen.findByRole("button", { name: /retry/i })).toBeInTheDocument();
});
```

## Rules
- Query priority: `getByRole` (with name) → `getByLabelText` → `getByText` → `getByTestId` last.
- `userEvent.setup()` over `fireEvent`; await `findBy*` instead of sleeps.
- `renderWithProviders` wraps QueryClient (retries off), router, theme.
- Test what the user sees and the URL/state they rely on — not hook internals or class names.
