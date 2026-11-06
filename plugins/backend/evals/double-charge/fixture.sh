#!/usr/bin/env bash
set -euo pipefail
mkdir -p app tests
cat > app/wallet.py <<'P'
from sqlalchemy import Column, Integer, String, create_engine, select
from sqlalchemy.orm import declarative_base, Session

Base = declarative_base()

class Wallet(Base):
    __tablename__ = "wallets"
    id = Column(Integer, primary_key=True)
    balance = Column(Integer, nullable=False, default=0)

class Charge(Base):
    __tablename__ = "charges"
    id = Column(Integer, primary_key=True)
    wallet_id = Column(Integer, nullable=False)
    amount = Column(Integer, nullable=False)
    reference = Column(String, nullable=False)

def buy_credits(db: Session, wallet_id: int, amount: int, reference: str) -> Charge:
    """Called by POST /credits/buy with the client's request reference."""
    already = db.scalar(select(Charge).where(Charge.reference == reference))
    if already:
        return already
    wallet = db.get(Wallet, wallet_id)
    if wallet.balance < amount:
        raise ValueError("insufficient funds")
    wallet.balance -= amount
    charge = Charge(wallet_id=wallet_id, amount=amount, reference=reference)
    db.add(charge)
    db.commit()
    return charge
P
printf 'sqlalchemy\npytest\n' > requirements.txt
