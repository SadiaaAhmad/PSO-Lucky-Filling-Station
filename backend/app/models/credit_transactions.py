from sqlalchemy import Column, Integer, String, Numeric, ForeignKey, DateTime, func, Boolean
from sqlalchemy.orm import relationship
from backend.app.database.base import Base

class CreditTransaction(Base):
    __tablename__ = "credit_transactions"

    id = Column(Integer, primary_key=True, index=True)
    daily_log_id = Column(Integer, ForeignKey("daily_logs.id", ondelete="CASCADE"), nullable=False)
    customer_id = Column(Integer, ForeignKey("customers.id"), nullable=False)
    vehicle_id = Column(Integer, ForeignKey("customer_vehicles.id"), nullable=True)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=True)
    transaction_type = Column(String(20), nullable=False) # CREDIT_SALE, CREDIT_RECOVERY
    liters = Column(Numeric(12, 2), default=0.00)
    rate_per_ltr = Column(Numeric(10, 4), default=0.0000)
    amount = Column(Numeric(12, 2), nullable=False)
    reference = Column(String(100), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    is_reversed = Column(Boolean, server_default='false', default=False)
    reversed_at = Column(DateTime(timezone=True), nullable=True)
    reversal_reason = Column(String(255), nullable=True)

    daily_log = relationship("DailyLog", back_populates="credit_transactions")
    customer = relationship("Customer", back_populates="credit_transactions")
    vehicle = relationship("CustomerVehicle", back_populates="credit_transactions")
    product = relationship("Product")
