# Common dashboard performance fixes

| Symptom | Cause | Fix |
|---|---|---|
| Page shows spinners in sequence | request waterfall (component A loads, then B fetches) | fetch in parallel at the route (loader or `useQueries`), prefetch on hover/intent with `queryClient.prefetchQuery` |
| Same data refetched on every visit | `staleTime: 0` everywhere | set `staleTime` per resource (e.g. 30–60 s for lists) |
| Large initial JS | charts/editor/date libs imported eagerly | `React.lazy` / dynamic import per route or widget; `import { Calendar } from "lucide-react"` not `* as Icons` |
| Typing in a filter lags | every keystroke refetches and re-renders the table | debounce search input (250–300 ms), `keepPreviousData`, memoised columns |
| Table with 5,000 rows freezes | rendering every row | server pagination, or `@tanstack/react-virtual` |
| Layout jumps when data loads | skeleton smaller than content | skeletons with fixed heights matching rows/cards |
| Slow first paint | blocking fonts, huge images | `font-display: swap`, preload one font, responsive images with width/height |
| Whole page re-renders on small state change | state lifted too high / context with changing value | colocate state, split contexts, derive values instead of storing them |

## CI size check (size-limit)
```json
// package.json
"size-limit": [{ "path": "dist/assets/index-*.js", "limit": "200 KB" }]
```
`npx size-limit` in the web CI job; failing limit fails the PR.
