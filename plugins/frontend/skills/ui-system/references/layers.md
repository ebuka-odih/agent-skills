# Component layers

```
src/
├── components/
│   ├── ui/          shadcn primitives (Button, Input, Dialog, Table…) — generated, edited rarely and deliberately
│   └── app/         your composites built from ui/: PageHeader, DataTable, StatCard, EmptyState,
│                    ErrorState, FilterBar, ConfirmDialog, MoneyCell, StatusBadge, FormField…
├── features/<feature>/   screens and feature-specific components; compose app/ components
├── lib/              cn(), formatters (money, numbers, dates), api client, query keys
└── styles/globals.css    tokens (:root, .dark, @theme inline)
```

## Rules
| Rule | Why |
|---|---|
| Features import from `components/app` first, `components/ui` second | One place to change a pattern |
| A UI pattern used in 2+ features moves to `components/app` | Stops copy-paste drift |
| `components/ui` changes go in their own PR with a story/screenshot diff | They affect every screen |
| App components expose **variants** (cva) and slots, not `className` soup | Fixed set of looks |
| No business logic or data fetching in `components/ui` or `components/app` | Reusable, testable |
| Shared across several products → move `ui` + `app` into a package (`packages/ui`) | One design system, many apps |

## Starter set of app components for dashboards
`AppShell` (sidebar + header) · `PageHeader` (title, description, actions) · `FilterBar` · `DataTable` · `StatCard` · `ChartCard` · `EmptyState` · `ErrorState` · `LoadingState`/skeletons · `ConfirmDialog` · `FormField` · `StatusBadge` · `MoneyCell`/`DateCell`.
