---
description: Adds CafeOrCoffeeShop/LocalBusiness JSON-LD from real page data — address, geo, hours, price range — without inventing ratings.
tags: [seo]
runs: 1
max_turns: 25
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---
Add structured data to the cafe page in resources/views/cafes/show.blade.php so it can get rich results on Google. Use the data the page already has.
