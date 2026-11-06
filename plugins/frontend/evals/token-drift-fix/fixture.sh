#!/usr/bin/env bash
set -euo pipefail
mkdir -p src/components/ui src/components/app src/features/orders src/lib src/app
cat > package.json <<'J'
{"name":"studio-web","dependencies":{"react":"^19","@tanstack/react-query":"^5","@tanstack/react-table":"^8","class-variance-authority":"^0.7","tailwind-merge":"^3","clsx":"^2","lucide-react":"^0.5","nuqs":"^2","sonner":"^2"}}
J
echo '{"style":"new-york","rsc":false,"tailwind":{"css":"src/app/globals.css","baseColor":"neutral","cssVariables":true},"aliases":{"components":"@/components","ui":"@/components/ui","utils":"@/lib/utils"}}' > components.json
cat > src/app/globals.css <<'C'
@import "tailwindcss";

:root {
  --radius: 0.625rem;
  --background: oklch(1 0 0);
  --foreground: oklch(0.145 0 0);
  --primary: oklch(0.205 0 0);
  --primary-foreground: oklch(0.985 0 0);
  --muted: oklch(0.97 0 0);
  --muted-foreground: oklch(0.556 0 0);
  --destructive: oklch(0.577 0.245 27.325);
  --border: oklch(0.922 0 0);
}
.dark {
  --background: oklch(0.145 0 0);
  --foreground: oklch(0.985 0 0);
  --primary: oklch(0.922 0 0);
  --primary-foreground: oklch(0.205 0 0);
  --muted: oklch(0.269 0 0);
  --muted-foreground: oklch(0.708 0 0);
  --destructive: oklch(0.704 0.191 22.216);
  --border: oklch(1 0 0 / 10%);
}
@theme inline {
  --color-background: var(--background);
  --color-foreground: var(--foreground);
  --color-primary: var(--primary);
  --color-primary-foreground: var(--primary-foreground);
  --color-muted: var(--muted);
  --color-muted-foreground: var(--muted-foreground);
  --color-destructive: var(--destructive);
  --color-border: var(--border);
}
C
printf 'import { clsx, type ClassValue } from "clsx";\nimport { twMerge } from "tailwind-merge";\nexport function cn(...inputs: ClassValue[]) { return twMerge(clsx(inputs)); }\n' > src/lib/utils.ts
printf 'export { Button } from "./button-impl";\n' > src/components/ui/button.tsx
printf 'export { Table, TableHeader, TableBody, TableRow, TableHead, TableCell } from "./table-impl";\n' > src/components/ui/table.tsx
printf 'export { Badge } from "./badge-impl";\n' > src/components/ui/badge.tsx
printf 'export { Skeleton } from "./skeleton-impl";\n' > src/components/ui/skeleton.tsx
printf 'export { Input } from "./input-impl";\n' > src/components/ui/input.tsx
printf 'export { Card, CardHeader, CardTitle, CardContent } from "./card-impl";\n' > src/components/ui/card.tsx
cat > src/features/orders/OrderStatusBadge.tsx <<'T'
export function OrderStatusBadge({ status }: { status: "paid" | "pending" | "failed" | "refunded" }) {
  if (status === "paid") return <span className="rounded-full bg-green-100 px-[10px] py-[3px] text-[11px] text-green-800">Paid</span>;
  if (status === "pending") return <span className="rounded-full bg-amber-100 px-[10px] py-[3px] text-[11px] text-amber-800">Pending</span>;
  if (status === "failed") return <span className="rounded-full bg-red-600 px-[10px] py-[3px] text-[11px] text-white">Failed</span>;
  return <span style={{ background: "#e5e7eb", color: "#374151", padding: "3px 10px", borderRadius: 9999, fontSize: 11 }}>Refunded</span>;
}
T
