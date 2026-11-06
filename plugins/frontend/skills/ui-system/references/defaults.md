# Frontend house defaults

| Topic | Default |
|---|---|
| UI kit | shadcn/ui (copied source) + Tailwind v4, CSS-variable theming (`tailwind.cssVariables: true`) |
| Class merging | `cn()` = `clsx` + `tailwind-merge` |
| Variants | `class-variance-authority` (cva) |
| Icons | lucide-react |
| Forms | react-hook-form + zod (`zodResolver`), schemas shared with the API where possible |
| Server data | TanStack Query; query keys in one module per feature |
| Tables | TanStack Table via shadcn `DataTable` pattern |
| Charts | shadcn charts (Recharts) with `--chart-N` tokens |
| URL state | filters, sort, pagination, tabs in the URL (nuqs or router search params) |
| Toasts | sonner, for confirmations; errors that need action stay inline |
| Dates/numbers | `Intl.NumberFormat` / `Intl.DateTimeFormat` via `lib/format.ts`; currency explicit (e.g. NGN, USD) |
| Dark mode | `next-themes` or class strategy; every token defined in `.dark` |
| Stories | Storybook (or Ladle) for every app component state |
| Visual tests | Playwright `toHaveScreenshot` (or Chromatic) on stories |
| A11y | axe in stories and pages; `eslint-plugin-jsx-a11y` |
| Perf budgets | LCP < 2.5 s, INP < 200 ms, CLS < 0.1; initial JS < 200 KB gzip per route |
