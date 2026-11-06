# UI consistency checklist

## Tokens
- [ ] No palette colours (`bg-blue-600`), hex/rgb/oklch literals or `style={{ color }}` in feature code
- [ ] No arbitrary values (`p-[13px]`, `text-[15px]`) except documented exceptions
- [ ] Status meaning uses status tokens (`success`, `warning`, `destructive`), same everywhere
- [ ] Every token defined for light and dark

## Spacing and type
- [ ] Page padding, section gaps and card gaps follow the rhythm (e.g. p-4 md:p-6 / gap-6 / gap-4)
- [ ] One heading style per level; body `text-sm`; helper text `text-muted-foreground`
- [ ] Numbers `tabular-nums`, right-aligned in tables

## Components
- [ ] Same thing, same component (one table, one stat card, one empty state)
- [ ] Buttons: one primary per view; consistent order in dialogs (cancel, then confirm); destructive uses `variant="destructive"`
- [ ] Same radius and shadow for the same kind of element; icons one library, consistent sizes
- [ ] No near-duplicate components (`UserCard`, `MemberCard`, `ProfileCard` doing the same job)

## States
- [ ] Loading skeletons, empty state with next action, error state with retry — on every data view
- [ ] Disabled/pending states on submit buttons

## Formats
- [ ] Money, numbers, dates, relative time via shared formatters; currency explicit

## Accessibility
- [ ] Inputs have labels; icon-only buttons have `aria-label`
- [ ] Visible focus ring (`ring` token); keyboard reachable; dialogs trap and return focus
- [ ] Contrast ≥ 4.5:1 for text in both themes; colour isn't the only signal
