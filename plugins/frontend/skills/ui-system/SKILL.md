---
name: ui-system
description: Entry point for frontend UI in shadcn + Tailwind apps and dashboards — set up a token-based UI system (colour, spacing, type, radius, motion), the component layers (ui primitives → app components → features), the shared patterns every screen uses, and record them in docs/ui/UI.md. Use when starting a frontend, when the user asks "how do I keep the UI consistent", "design system", "theme", "dark mode", "our dashboard looks inconsistent", "do these components fit together", or before building new screens. Routes to shadcn-tailwind, dashboard-patterns, ui-consistency, component-testing and frontend-performance.
---

# UI system (orchestrator)

Consistency doesn't come from careful screens; it comes from **few decisions, reused everywhere**: tokens, a small set of app components, and shared states. This skill makes those decisions once and writes them down.

```
frontend/skills/
├── ui-system/            ← you are here: tokens, layers, UI.md, routing
├── shadcn-tailwind/      theme setup, token rules, cva variants, cn(), what never to write
├── dashboard-patterns/   tables, charts, filters, forms, data states, layout
├── ui-consistency/       review a screen or PR for drift; fix it
├── component-testing/    stories per state + screenshot + a11y + interaction tests
└── frontend-performance/ Web Vitals, bundle budgets, code-splitting, data loading
```

**Output:** `docs/ui/UI.md` (from [templates/UI.md](templates/UI.md)).

## Steps
1. **Scan** — `bash "${CLAUDE_PLUGIN_ROOT}/scripts/ui-scan.sh" [web-dir]`: theme/tokens, component layers, raw colours, arbitrary values, inline styles, and which testing/data tools exist.
2. **Tokens** — [references/tokens.md](references/tokens.md): semantic colours (shadcn CSS variables), spacing rhythm, type scale, radius, shadows, motion, z-index. Brand colours become tokens, never literals.
3. **Layers** — [references/layers.md](references/layers.md): `components/ui` (shadcn primitives) → `components/app` (your composites: PageHeader, DataTable, StatCard, EmptyState…) → `features/*`. Features compose app components; they rarely touch primitives directly.
4. **Shared patterns** — page layout, states (loading/empty/error), formats (numbers, money, dates), feedback (toasts vs inline) → `dashboard-patterns`.
5. **Guardrails** — the token hook flags raw colours/arbitrary values as code is written; `component-testing` adds stories + screenshots so drift is visible in PRs.
6. **Write UI.md** and add to CLAUDE.md/AGENTS.md: `UI: docs/ui/UI.md — use tokens and app components; no raw colours or arbitrary values.`

House defaults: [references/defaults.md](references/defaults.md).

## Hard rules
- Feature code uses **semantic tokens** (`bg-primary`, `text-muted-foreground`, `border-border`) — never palette colours (`bg-blue-500`), hex, or arbitrary values (`p-[13px]`).
- A pattern used on 2+ screens becomes an app component in `components/app/`, with a story.
- Every data view has loading, empty and error states — designed, not afterthoughts.
- Accessibility is part of the component, not a later pass (labels, focus, contrast, keyboard).

## Hand-off (project loop)
Skills share work through files, not memory. When this skill's output is written, log it and let the loop pick the next step:
`bash <product plugin>/scripts/loop.sh log foundation/design "UI.md"` then `loop.sh next` (skill `product:project-loop`). If an input file this skill needs is missing, name it and the skill that writes it instead of guessing.
