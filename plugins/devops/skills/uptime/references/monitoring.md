# External monitoring and alerts

| Monitor | Target | Interval | Alert when |
|---|---|---|---|
| Home | `https://www.site/` → 200, contains a known string | 1 min | 2 consecutive failures from 2 regions |
| One deep page per template | category/place/product URL → 200, contains h1 text | 5 min | 2 failures |
| Readiness | `/readyz` → 200 | 1 min | 2 failures |
| Sitemap | `/sitemap.xml` → 200, `<urlset`/`<sitemapindex` | 15 min | 1 failure |
| TLS | certificate expiry | daily | < 14 days |
| Background work | queue oldest job age, dead-letter count, last scheduler run (heartbeat URL pinged by the scheduler) | 5 min | heartbeat missing 2× interval |

- Tools: UptimeRobot / Better Stack / Checkly / Pingdom / Grafana synthetic monitoring — any that alerts by phone/Slack/WhatsApp, not only email.
- Heartbeats ("dead man's switch") catch jobs and crons that silently stop — the outage no HTTP check sees.
- Keep an outage log (start, end, cause, what users/crawlers saw); after a long one run the Search Console recovery steps.
- Public status page only if customers depend on uptime; otherwise the alert channel is enough.
