# Page anatomy and states

```tsx
<AppShell>                                  {/* sidebar nav + top bar (user, theme, search) */}
  <PageHeader title="Bookings" description="All bookings across studios"
              actions={<Button>New booking</Button>} />
  <FilterBar>…search, status select, date range, reset…</FilterBar>
  <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">{/* StatCards */}</div>
  <DataTable … />                            {/* or ChartCard / detail */}
</AppShell>
```

## Spacing
Page `p-4 md:p-6` · sections `space-y-6` · inside cards `gap-4` · header to content `mb-6`.

## StatCard
Label (`text-sm text-muted-foreground`) · value (`text-2xl font-semibold tabular-nums`) · delta with direction icon and colour token (`text-success` / `text-destructive`) · period ("vs last 30 days"). Same height in a row; skeleton while loading.

## States
| State | Do | Don't |
|---|---|---|
| Loading | skeletons shaped like the content (rows, cards) | full-page spinner, layout jump |
| Empty (no data yet) | icon, "No bookings yet", why, primary action | blank table with headers only |
| Empty (filters) | "No results for these filters" + reset filters | same message as no data |
| Error | message, retry button, request ID for support | toast-only, raw stack/JSON |
| Partial (one widget fails) | error boundary per card | whole page crashes |

## Responsive
Sidebar collapses to a sheet on mobile; tables either scroll horizontally with a sticky first column or switch to cards below `md`.
