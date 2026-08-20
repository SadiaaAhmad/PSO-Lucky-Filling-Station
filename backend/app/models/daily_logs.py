from sqlalchemy import Column, Integer, Date, String, Text, DateTime, func
from sqlalchemy.orm import relationship
from backend.app.database.base import Base

class DailyLog(Base):
    __tablename__ = "daily_logs"

    id = Column(Integer, primary_key=True, index=True)
    log_date = Column(Date, unique=True, nullable=False, index=True)
    status = Column(String(20), nullable=False, default="DRAFT") # DRAFT, CLOSED
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    nozzle_readings = relationship("NozzleReading", back_populates="daily_log", cascade="all, delete-orphan")
    fuel_purchases = relationship("FuelPurchase", back_populates="daily_log", cascade="all, delete-orphan")
    daily_tank_stocks = relationship("DailyTankStock", back_populates="daily_log", cascade="all, delete-orphan")
    credit_transactions = relationship("CreditTransaction", back_populates="daily_log", cascade="all, delete-orphan")
    card_transactions = relationship("CardTransaction", back_populates="daily_log", cascade="all, delete-orphan")
    journal_entries = relationship("JournalEntry", back_populates="daily_log")
