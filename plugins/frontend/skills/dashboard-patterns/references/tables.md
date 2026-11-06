# Data tables (TanStack Table + shadcn Table)

## Features, in the order to add them
1. Columns with typed accessors; cells via app components (`MoneyCell`, `DateCell`, `StatusBadge`)
2. Sorting (server-side when paginated server-side)
3. Pagination — server-side for large data; page size options 10/25/50
4. Filtering — `FilterBar` above the table, not inside header cells, for consistency
5. Column visibility (persist per user if useful)
6. Row actions — `DropdownMenu` in the last column (`…`), destructive items last and red
7. Selection + bulk actions — sticky bar showing "3 selected", actions, clear
8. Virtualisation (`@tanstack/react-virtual`) when rendering > ~200 rows client-side

## URL state
```ts
// ?q=yoga&status=active&sort=-created_at&page=2
const [filters, setFilters] = useQueryStates({ q: parseAsString, status: parseAsString,
  sort: parseAsString.withDefault('-created_at'), page: parseAsInteger.withDefault(1) }); // nuqs
const { data, isPending } = useBookings(filters);
```
Changing a filter resets `page` to 1.

## Rules
- Header labels short; numbers right-aligned; dates in one format; long text truncated with tooltip.
- Row click opens detail only if there's no other primary row action; keyboard reachable.
- Empty and error states render inside the table area, keeping the header and filters visible.
