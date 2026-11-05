# API style per boundary

| Boundary | Default | Choose otherwise when |
|---|---|---|
| Own web frontend ↔ own backend (same repo) | Framework-native (Inertia, server actions, tRPC) or REST | Many clients with very different data needs → GraphQL |
| Mobile app ↔ backend | REST + OpenAPI | Highly nested, client-driven screens → GraphQL |
| Public / partner API | REST + OpenAPI | — REST is what partners expect |
| Service ↔ service (internal, high volume) | gRPC + proto | Simple, low volume → REST is fine |
| Real-time to clients | WebSockets / SSE (Reverb, Pusher, Ably) | One-way updates only → SSE |

Rule: pick the fewest styles that cover the boundaries. Two is normal; three needs a reason.
