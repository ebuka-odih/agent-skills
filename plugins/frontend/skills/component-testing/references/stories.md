# Stories per state

```tsx
// components/app/data-table.stories.tsx
const meta = { component: BookingsTable, parameters: { layout: "padded" } } satisfies Meta<typeof BookingsTable>;
export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = { args: { rows: bookings } };
export const Loading: Story = { args: { rows: [], isLoading: true } };
export const Empty: Story = { args: { rows: [] } };
export const EmptyFiltered: Story = { args: { rows: [], hasFilters: true } };
export const Error: Story = { args: { error: new Error("Network error") } };
export const LongContent: Story = { args: { rows: bookingsWithLongNames } };
export const Dark: Story = { ...Default, globals: { theme: "dark" } };
```

## Checklist per app component
default · loading · empty · error · disabled/pending · long text / overflow · many items · mobile width · dark theme · RTL if the app supports it.

## Setup notes
- Load `globals.css` in the story preview so tokens apply; toggle the `.dark` class via a theme decorator.
- Share MSW handlers between stories and tests (`msw-storybook-addon`).
- Add `@storybook/addon-a11y` so axe runs on every story.
