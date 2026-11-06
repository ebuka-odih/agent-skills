---
updated: YYYY-MM-DD
---

# <Project> — UI system

> Read before building or changing screens. Use tokens and app components; no raw colours, hex or arbitrary values in feature code.

## Stack
shadcn/ui (style: <…>, base colour: <…>) · Tailwind v<4> · icons: lucide · forms: react-hook-form + zod · data: TanStack Query · tables: TanStack Table · charts: Recharts (shadcn charts)

## Tokens (styles/globals.css)
| Group | Tokens | Notes |
|---|---|---|
| Colour | background, foreground, card, popover, primary, secondary, muted, accent, destructive, border, input, ring | semantic only |
| Status | success, warning, info (+ foregrounds) | added via @theme inline |
| Charts | chart-1…5 | series order: <…> |
| Spacing | gap-2 / gap-4 / gap-6, page p-4 md:p-6 | |
| Type | title / section / body / helper | tabular-nums for numbers |
| Radius | --radius = <…> | |

## Component layers
`components/ui` (primitives) → `components/app` (composites) → `features/*`. App components: <list>.

## Page anatomy
```
AppShell → PageHeader (title · description · primary action) → FilterBar → content (cards / DataTable / charts) → pagination
```

## States
| State | Component | Rule |
|---|---|---|
| Loading | skeletons matching layout | no spinners for whole pages |
| Empty | EmptyState (icon, title, hint, action) | explain + next step |
| Error | ErrorState (message, retry, request ID) | inline, not toast-only |
| Success | toast (sonner) | for completed actions |

## Formats
Money: <NGN/USD rules> · numbers: <…> · dates: <…> · relative time: <…>

## Testing
Stories: <path> · visual: <tool> · a11y: axe · interaction: Testing Library · E2E: <journeys>

## Performance budgets
LCP < 2.5 s · INP < 200 ms · CLS < 0.1 · JS per route < <…> KB gzip

## Decisions and exceptions
| Date | Decision / exception | Why |
|---|---|---|
