---
type: llm
weight: 4
focus: { source: file, path: docs/seo/SEO.md }
---
Inputs: queries with positions (pharmacy in wuse abuja 7.8; 24 hour pharmacy abuja 12.4; hospitals in ikeja 4.2; best restaurants in lekki 18.9; brand 1.0; "how to register a business in nigeria" 41) and pages where a Wuse pharmacies listing and a single place page (medplus-wuse) both get impressions.

PASS only if the plan:
1. maps query clusters to ONE target URL each, with intent (local/commercial/informational);
2. prioritises striking-distance queries (positions ~4–20) such as pharmacy in wuse, 24 hour pharmacy abuja, best restaurants in lekki, with concrete actions (title/h1/intro, internal links, content);
3. notes the possible cannibalization between the Wuse pharmacies listing and the medplus-wuse place page (or otherwise picks the listing as the target for the generic query);
4. handles "24 hour pharmacy abuja" sensibly (e.g. an indexable 24-hour pharmacies page or section instead of a noindexed filter parameter);
5. deprioritises the off-topic informational query ("how to register a business") rather than creating a page for it.
FAIL otherwise.
