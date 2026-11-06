# Variants with cva

```tsx
// components/app/status-badge.tsx
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

const statusBadge = cva(
  "inline-flex items-center gap-1 rounded-md px-2 py-0.5 text-xs font-medium",
  {
    variants: {
      status: {
        active:   "bg-success/15 text-success",
        pending:  "bg-warning/15 text-warning-foreground",
        failed:   "bg-destructive/15 text-destructive",
        archived: "bg-muted text-muted-foreground",
      },
    },
    defaultVariants: { status: "active" },
  },
);

export function StatusBadge({ status, className, ...props }:
  React.ComponentProps<"span"> & VariantProps<typeof statusBadge>) {
  return <span className={cn(statusBadge({ status }), className)} {...props} />;
}
```

## Rules
- A look used twice → a variant, not a copied class string.
- Variants are named by **meaning** (`status: failed`, `size: sm`, `tone: subtle`), not by appearance (`red`, `big`).
- Keep `className` for layout from the parent (margins, grid placement), not for colour/size overrides.
- Map domain values to variants in one place (`statusToVariant(order.status)`), not per screen.
