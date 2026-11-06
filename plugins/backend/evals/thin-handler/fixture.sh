#!/usr/bin/env bash
set -euo pipefail
mkdir -p app/routes app/models
cat > app/routes/bookings.py <<'P'
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.db import get_session
from app.models.booking import Booking

router = APIRouter()

@router.post("/bookings")
async def create_booking(slot: datetime, name: str, db: AsyncSession = Depends(get_session)):
    taken = await db.scalar(select(Booking).where(Booking.slot == slot))
    if taken:
        raise HTTPException(409, "slot taken")
    b = Booking(slot=slot, name=name)
    db.add(b)
    await db.commit()
    return {"id": b.id}
P
cat > app/models/booking.py <<'P'
from sqlalchemy import Column, DateTime, Integer, String
from app.db import Base
class Booking(Base):
    __tablename__ = "bookings"
    id = Column(Integer, primary_key=True)
    slot = Column(DateTime(timezone=True), nullable=False)
    name = Column(String, nullable=False)
    status = Column(String, nullable=False, default="active")
P
printf 'from sqlalchemy.orm import declarative_base\nBase = declarative_base()\nasync def get_session():\n    yield None\n' > app/db.py
