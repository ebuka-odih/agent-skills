---
type: llm
weight: 4
focus: { source: file, path: docs/prototypes/directory-hours.md }
---
SPEC has an unresolved risk K1: does the partner API return parseable opening hours for most listings? (The API docs say hours are optional free text.)

PASS only if this prototype card:
1. states the question (hours present and parseable?) as K1's prototype;
2. has a measurable SUCCESS criterion and a measurable KILL criterion (e.g. % of sampled listings with parseable hours) written before any result;
3. has a timebox and says what is faked/stubbed;
4. picks a data/tech spike shape (sample real listings, parse, count) rather than building the production import;
5. says where the prototype lives (a proto/ branch or prototypes/ folder, not main) and what happens with each verdict (keep/change/kill → SPEC change log / ADR / plan).
FAIL otherwise.
