from sqlalchemy import Column, Integer, String, Numeric, ForeignKey, Date, DateTime, CheckConstraint, func, Boolean
from sqlalchemy.orm import relationship
from backend.app.database.base import Base

class JournalEntry(Base):
    __tablename__ = "journal_entries"

    id = Column(Integer, primary_key=True, index=True)
    entry_date = Column(Date, nullable=False, index=True)
    daily_log_id = Column(Integer, ForeignKey("daily_logs.id", ondelete="SET NULL"), nullable=True)
    reference = Column(String(100), nullable=True)
    description = Column(String(255), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    is_reversed = Column(Boolean, server_default='false', default=False)
    reversed_at = Column(DateTime(timezone=True), nullable=True)
    reversal_reason = Column(String(255), nullable=True)

    daily_log = relationship("DailyLog", back_populates="journal_entries")
    lines = relationship("JournalLine", back_populates="journal_entry", cascade="all, delete-orphan")

class JournalLine(Base):
    __tablename__ = "journal_lines"

    id = Column(Integer, primary_key=True, index=True)
    journal_entry_id = Column(Integer, ForeignKey("journal_entries.id", ondelete="CASCADE"), nullable=False)
    account_id = Column(Integer, ForeignKey("accounts.id"), nullable=False)
    debit = Column(Numeric(12, 2), nullable=False, default=0.00)
    credit = Column(Numeric(12, 2), nullable=False, default=0.00)
    customer_id = Column(Integer, ForeignKey("customers.id"), nullable=True)
    vehicle_id = Column(Integer, ForeignKey("customer_vehicles.id"), nullable=True)
    description = Column(String(255), nullable=True)

    journal_entry = relationship("JournalEntry", back_populates="lines")
    account = relationship("Account", back_populates="journal_lines")
    customer = relationship("Customer")
    vehicle = relationship("CustomerVehicle")

    __table_args__ = (
        CheckConstraint('debit >= 0 AND credit >= 0 AND (debit > 0 OR credit > 0)', name='chk_journal_line_debit_credit'),
    )
