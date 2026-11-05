---
type: llm
weight: 3
---
PASS if the final message:
- asks several questions at once (a batch, not one question),
- covers the problem/purpose, who the users or roles are, and what success looks like,
- offers a proposed/default answer or examples for most questions so the user can just confirm, AND
- does not present a finished spec as if the user's needs were known.

FAIL if it asks only one question, writes a full spec without asking, or asks questions with no proposals at all.
