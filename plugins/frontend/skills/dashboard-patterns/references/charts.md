# Charts (shadcn charts / Recharts)

```tsx
const chartConfig = {
  bookings: { label: "Bookings", color: "var(--chart-1)" },
  cancellations: { label: "Cancellations", color: "var(--chart-2)" },
} satisfies ChartConfig;

<ChartContainer config={chartConfig} className="min-h-[240px] w-full">
  <BarChart data={data}>
    <CartesianGrid vertical={false} />
    <XAxis dataKey="week" tickLine={false} axisLine={false} />
    <ChartTooltip content={<ChartTooltipContent />} />
    <Bar dataKey="bookings" fill="var(--color-bookings)" radius={4} />
  </BarChart>
</ChartContainer>
```
(`min-h-[…]` on the chart container is an accepted exception — charts need an explicit height.)

## Choosing the chart
| Question | Chart |
|---|---|
| Change over time | line / area |
| Compare categories | bar (horizontal if labels are long) |
| Part of whole (≤ 5 parts) | stacked bar; pie only for 2–3 parts |
| Distribution | histogram |
| One number + trend | StatCard with sparkline |

## Rules
- Series colours from `--chart-1…5` in a fixed order across the app (bookings is always chart-1).
- Label axes and units; format ticks with the shared formatters.
- Provide the numbers another way (table toggle or accessible summary) — charts alone aren't accessible.
- Loading: skeleton of the chart area; empty: "No data for this period".
