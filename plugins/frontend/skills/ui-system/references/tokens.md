# Design tokens

Tokens are named decisions. Components use names (`primary`, `space-4`), not values (`#2563eb`, `17px`). Change the value once → every screen follows, including dark mode.

## Colour — semantic, via shadcn CSS variables
| Token | Use for |
|---|---|
| `background` / `foreground` | page surface and body text |
| `card`, `popover` (+ `-foreground`) | raised surfaces |
| `primary` (+ `-foreground`) | the one main action per view, active states |
| `secondary` | secondary actions |
| `muted` / `muted-foreground` | subtle surfaces, helper text, table headers |
| `accent` | hover/selected backgrounds |
| `destructive` | delete, errors |
| `border`, `input`, `ring` | lines, field borders, focus rings |
| `chart-1` … `chart-5` | data series — never reuse brand/primary for series |
| `sidebar-*` | app shell navigation |

Add status colours the shadcn way (`--success`, `--warning`, `--info` in `:root` and `.dark`, mapped in `@theme inline`) — see shadcn-tailwind. Every colour has a `-foreground` pair that meets contrast (4.5:1 text, 3:1 large text/UI).

## Spacing rhythm (Tailwind scale, 4 px base)
| Between | Use |
|---|---|
| icon ↔ label | `gap-2` |
| fields in a form, items in a card | `gap-4` / `space-y-4` |
| cards/sections on a page | `gap-6` |
| page padding | `p-4 md:p-6` |
Pick these once; don't improvise `gap-5`/`gap-7` per screen.

## Type scale
Page title `text-2xl font-semibold tracking-tight` · section `text-lg font-semibold` · body `text-sm` · helper `text-xs text-muted-foreground` · numbers in tables/stats `tabular-nums`.

## Other tokens
- **Radius**: from `--radius` (shadcn derives sm…4xl). Don't mix `rounded-md` and `rounded-xl` for the same kind of element.
- **Shadow**: `shadow-xs` for inputs/cards, `shadow-lg` for popovers/dialogs only.
- **Icons**: one library (lucide), sizes `size-4` inline, `size-5` in buttons with text only when needed, `size-8+` in empty states.
- **Motion**: 150–200 ms ease-out for hovers/popovers; respect `motion-reduce:`.
- **Z-index**: use component defaults (dialog, popover, toast); no ad hoc `z-[999]`.
