---
name: shadcn-tailwind
description: Set up and use shadcn/ui with Tailwind correctly — CSS-variable theming in globals.css (:root and .dark, @theme inline), adding brand and status tokens, cn() and tailwind-merge, cva variants for app components, extending primitives without forking them, and the classes feature code must never use (palette colours, hex, arbitrary values, inline styles). Use when installing shadcn, adding a colour or variant, customising a component, theming or dark mode, when the user says "add a warning colour", "make a new button variant", "customise this shadcn component", or when the token hook flags a raw colour.
---

# shadcn + Tailwind

## Steps
1. **Check the setup** — `components.json` has `tailwind.cssVariables: true`; `globals.css` defines tokens in `:root` and `.dark` and maps them in `@theme inline` (Tailwind v4). Details: [references/theming.md](references/theming.md).
2. **New colour?** Add it as a token (`--warning` + `--warning-foreground` in both modes, mapped as `--color-warning`) — never as `bg-amber-500` in a component.
3. **New look for a component?** Add a **variant** with cva in the app component (or the primitive, deliberately), not a one-off `className` — [references/variants.md](references/variants.md).
4. **Compose classes** with `cn()` so overrides merge predictably (`tailwind-merge` resolves `px-2` vs `px-4`).
5. **Updating primitives** — `npx shadcn@latest add <component>` into `components/ui`; diff before overwriting local changes; keep local edits small and noted in UI.md.

## What feature code never contains (the token hook flags these)
| Don't | Do |
|---|---|
| `bg-blue-600`, `text-gray-500`, `border-zinc-200` | `bg-primary`, `text-muted-foreground`, `border-border` |
| `#1d4ed8`, `rgb(…)`, `oklch(…)` in TSX | a token in `globals.css` |
| `p-[13px]`, `w-[372px]`, `text-[15px]` | scale values (`p-3`, `w-96`, `text-sm`) or a token |
| `style={{ color: … }}` | classes / tokens (CSS variables only for truly dynamic values like chart widths) |
| `className` overrides fighting a variant | a new cva variant |

Exceptions (charts, third-party embeds, one-off marketing art) go in UI.md "Decisions and exceptions".

## Hard rules
- Tokens live in one CSS file. Components never define colours.
- Every new token is defined for light **and** dark and meets contrast with its foreground.
- Don't fork a primitive to change its colour — change the token or add a variant.
