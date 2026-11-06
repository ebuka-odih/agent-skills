---
name: ui-consistency
description: Review a screen, component or PR for UI drift and fix it — raw colours or arbitrary values instead of tokens, off-scale spacing, mixed radius/shadows/icon sizes, duplicated components, missing loading/empty/error states, inconsistent formats, dark-mode gaps, accessibility misses. Use when the user says "does this look consistent", "the UI feels off", "review this page", "do these components go together", "clean up the dashboard", or before merging a UI PR.
---

# UI consistency review

## Steps
1. **Scan** — `bash "${CLAUDE_PLUGIN_ROOT}/scripts/ui-scan.sh" [web-dir]` (whole app) or read the diff for a PR.
2. **Compare against UI.md** (or the ui-system defaults if there is none) using [references/checklist.md](references/checklist.md).
3. **Look at it** — run the app or the stories in both themes and at mobile width; screenshot before/after when fixing.
4. **Report** each finding as `file:line · rule · fix`, grouped: tokens · spacing/type · components · states · a11y · formats.
5. **Fix in this order**: tokens (one change fixes many screens) → shared app components → individual screens.

## Hard rules
- Fix drift at the source: a recurring one-off becomes a token or a variant, not five identical edits.
- Don't redesign during a consistency pass — match UI.md; propose design changes separately.
- Every fixed shared component gets a story/screenshot update so the change is visible in review.
