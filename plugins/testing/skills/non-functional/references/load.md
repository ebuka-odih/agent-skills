# Load testing with k6

```js
// load/search.js — NFR2: search p95 < 300 ms at 50 rps
import http from 'k6/http';
import { check } from 'k6';

export const options = {
  scenarios: { steady: { executor: 'constant-arrival-rate', rate: 50, timeUnit: '1s', duration: '5m', preAllocatedVUs: 50 } },
  thresholds: {
    http_req_duration: ['p(95)<300'],
    http_req_failed: ['rate<0.01'],
  },
};

export default function () {
  const r = http.get(`${__ENV.BASE_URL}/api/search?q=jollof&city=lagos`, { headers: { Authorization: `Bearer ${__ENV.TOKEN}` } });
  check(r, { '200': (res) => res.status === 200 });
}
```
```bash
k6 run -e BASE_URL=https://staging.example.com -e TOKEN=$STAGING_TEST_TOKEN load/search.js
```

## Test types
| Type | Shape | When |
|---|---|---|
| Smoke | 1–5 VUs, 1 min | nightly, after deploys to staging |
| Load | expected peak, 10–30 min | pre-release, after perf-sensitive changes |
| Stress | ramp past peak until errors | before big launches |
| Soak | normal load, hours | memory leaks, connection pools |

Seed staging with production-like volume (anonymised). Stub external providers. Compare against the previous run, not just the threshold.
