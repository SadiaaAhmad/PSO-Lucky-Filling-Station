from sqlalchemy import Column, Integer, String, Numeric, ForeignKey, Boolean, DateTime
from sqlalchemy.orm import relationship
from backend.app.database.base import Base

class CardTransaction(Base):
    __tablename__ = "card_transactions"

    id = Column(Integer, primary_key=True, index=True)
    daily_log_id = Column(Integer, ForeignKey("daily_logs.id", ondelete="CASCADE"), nullable=False)
    card_type = Column(String(20), nullable=False) # BANK_CARD, BPSO_CARD
    liters = Column(Numeric(12, 2), default=0.00)
    amount = Column(Numeric(12, 2), nullable=False)
    bank_charges = Column(Numeric(12, 2), default=0.00)
    is_reversed = Column(Boolean, server_default='false', default=False)
    reversed_at = Column(DateTime(timezone=True), nullable=True)
    reversal_reason = Column(String(255), nullable=True)

    daily_log = relationship("DailyLog", back_populates="card_transactions")
