---
name: dashboard-patterns
description: Build dashboard screens from shared patterns so they fit together — page anatomy (app shell, page header, filter bar, content, pagination), data tables (TanStack Table: sorting, filtering, pagination, column visibility, row and bulk actions), charts with chart tokens, stat cards, forms with react-hook-form + zod, filters and sorting in the URL, server data with TanStack Query, and loading/empty/error states. Use when building an admin panel, dashboard, list/detail screen, table, chart or form; when the user says "build a dashboard", "add a table", "add filters", "add a chart", "this page needs a form".
---

# Dashboard patterns

## Steps
1. **Page anatomy first** — every screen uses the same skeleton ([references/layout.md](references/layout.md)): `AppShell` → `PageHeader` (title, description, one primary action) → `FilterBar` → content → pagination.
2. **Pick the pattern** for the content:
   | Content | Pattern | Guide |
   |---|---|---|
   | List of records | `DataTable` (TanStack Table) with URL state | [references/tables.md](references/tables.md) |
   | Trends / comparisons | `ChartCard` (shadcn charts) with `--chart-N` | [references/charts.md](references/charts.md) |
   | Key numbers | `StatCard` grid (value, delta, period) | layout.md |
   | Create / edit | form in a Sheet or page, react-hook-form + zod | [references/forms.md](references/forms.md) |
3. **Data** — TanStack Query: one hook per resource (`useOrders(filters)`), query keys from a factory, `placeholderData: keepPreviousData` for paging, optimistic updates for quick toggles with rollback on error.
4. **States** — loading skeleton matching the layout, `EmptyState` with next action, `ErrorState` with retry; never a blank area.
5. **URL state** — filters, sort, page, selected tab live in the URL so views can be shared and survive refresh.

## Hard rules
- Same pattern, same component: don't build a second table or stat card style.
- Numbers right-aligned with `tabular-nums`; money via one formatter with explicit currency.
- Destructive actions confirm with `ConfirmDialog` naming the thing being deleted; bulk actions show the count.
- Tables over ~200 rows paginate server-side or virtualise.
