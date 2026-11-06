---
type: llm
weight: 4
focus: { source: file, path: app/wallet.py }
---
Planted: check-then-insert on `reference` (two concurrent requests both pass), and load-modify-save on `balance` (concurrent charges can both pass the balance check and go negative).

PASS only if app/wallet.py: (1) makes `reference` unique at the database level (unique constraint/index) and handles the duplicate by returning the original charge (catching the IntegrityError / ON CONFLICT), (2) changes the balance with one atomic conditional update (UPDATE … SET balance = balance - :n WHERE id = :id AND balance >= :n, checking rowcount) or locks the wallet row (SELECT … FOR UPDATE) inside the transaction, (3) keeps it in one transaction. An application-level re-check alone is NOT enough. FAIL otherwise.
