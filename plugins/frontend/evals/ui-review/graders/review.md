---
type: llm
weight: 3
---
Planted problems in CustomersPage.tsx:
(a) raw palette colours / hex instead of tokens (bg-blue-600, bg-indigo-500, text-white, border-gray-200, text-red-500, #111827);
(b) arbitrary values and inline style instead of the scale/typography tokens (p-[22px], mt-[18px], gap-[7px], style={{ fontSize… }});
(c) two primary-looking buttons with different styles/radius — should use the shadcn Button with one primary and variants;
(d) no loading, empty or error states (and fetch in useEffect without error handling; TanStack Query expected);
(e) icon-only delete button with no aria-label and no confirmation for a destructive action;
(f) money formatted by string concatenation instead of a shared Intl formatter, no tabular-nums; table not using the shadcn Table/DataTable.

PASS if the answer identifies at least FIVE of (a)–(f) with line or element references and concrete fixes (token classes, Button variants, states, aria-label + ConfirmDialog, formatter). FAIL otherwise.
