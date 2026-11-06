#!/usr/bin/env bash
set -euo pipefail
mkdir -p gsc
python3 - <<'P'
import csv, datetime as d
s = d.date(2026, 8, 1)
with open('gsc/Dates.csv', 'w', newline='') as f:
    w = csv.writer(f); w.writerow(['Date', 'Clicks', 'Impressions', 'CTR', 'Position'])
    for i in range(90):
        day = s + d.timedelta(i)
        im = 4000 if day < d.date(2026, 10, 20) else 60
        cl = im // 120
        w.writerow([day.isoformat(), cl, im, f"{cl * 100 / im:.2f}%", 11.5 if im > 100 else 14])
with open('gsc/Queries.csv', 'w', newline='') as f:
    w = csv.writer(f); w.writerow(['Top queries', 'Clicks', 'Impressions', 'CTR', 'Position'])
    w.writerows([['pharmacy near me', 300, '40,000', '0.75%', 9.2], ['hospitals in ikeja', 120, '12,000', '1%', 7.1], ['brand', 200, 400, '50%', 1.0]])
P
printf '2026-10-19 deploy: move to new host behind CDN with bot protection enabled\n2026-10-25 fix search ranking\n' > DEPLOYS.md
