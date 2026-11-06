# Theming (shadcn + Tailwind v4)

Source: https://ui.shadcn.com/docs/theming (checked 2026-11-06).

## globals.css shape
```css
@import "tailwindcss";

:root {
  --radius: 0.625rem;
  --background: oklch(1 0 0);
  --foreground: oklch(0.145 0 0);
  --primary: oklch(0.205 0 0);
  --primary-foreground: oklch(0.985 0 0);
  /* card, popover, secondary, muted, accent, destructive, border, input, ring, chart-1..5, sidebar-* */
}
.dark {
  --background: oklch(0.145 0 0);
  --foreground: oklch(0.985 0 0);
  --primary: oklch(0.922 0 0);
  --primary-foreground: oklch(0.205 0 0);
}
@theme inline {
  --color-background: var(--background);
  --color-foreground: var(--foreground);
  --color-primary: var(--primary);
  --color-primary-foreground: var(--primary-foreground);
  --radius-lg: var(--radius);
}
```

## Adding a status / brand colour
```css
:root { --warning: oklch(0.84 0.16 84); --warning-foreground: oklch(0.28 0.07 46); }
.dark { --warning: oklch(0.41 0.11 46); --warning-foreground: oklch(0.99 0.02 95); }
@theme inline {
  --color-warning: var(--warning);
  --color-warning-foreground: var(--warning-foreground);
}
```
→ `bg-warning text-warning-foreground`. Same for `success`, `info`, a brand accent.

## components.json essentials
`style` · `rsc` · `tailwind.css` (path to globals.css) · `tailwind.baseColor` · `tailwind.cssVariables: true` (CSS-variable theming; switching later means reinstalling components) · `aliases` (`@/components`, `@/components/ui`, `@/lib/utils`).

## Dark mode
Class strategy (`.dark` on `<html>`), e.g. `next-themes` with `attribute="class"`. Test every app component story in both themes.

## Contrast check
Pairs (`primary`/`primary-foreground`, `muted`/`muted-foreground`, status pairs) ≥ 4.5:1 for body text, ≥ 3:1 for large text and UI borders. Check both themes when changing tokens.
