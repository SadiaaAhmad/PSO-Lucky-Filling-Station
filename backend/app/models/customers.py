from sqlalchemy import Column, Integer, String, Numeric, ForeignKey, DateTime, UniqueConstraint, func
from sqlalchemy.orm import relationship
from backend.app.database.base import Base

class Customer(Base):
    __tablename__ = "customers"

    id = Column(Integer, primary_key=True, index=True)
    account_no = Column(String(30), unique=True, nullable=False, index=True)
    name = Column(String(100), nullable=False)
    phone = Column(String(20), nullable=True)
    credit_limit = Column(Numeric(12, 2), default=0.00)
    opening_balance = Column(Numeric(12, 2), default=0.00) # (+) Receivable, (-) Payable
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    vehicles = relationship("CustomerVehicle", back_populates="customer", cascade="all, delete-orphan")
    credit_transactions = relationship("CreditTransaction", back_populates="customer")

class CustomerVehicle(Base):
    __tablename__ = "customer_vehicles"

    id = Column(Integer, primary_key=True, index=True)
    customer_id = Column(Integer, ForeignKey("customers.id", ondelete="CASCADE"), nullable=False)
    vehicle_no = Column(String(50), nullable=False, index=True)
    driver_name = Column(String(100), nullable=True)
    notes = Column(String(255), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    customer = relationship("Customer", back_populates="vehicles")
    credit_transactions = relationship("CreditTransaction", back_populates="vehicle")

    __table_args__ = (
        UniqueConstraint('customer_id', 'vehicle_no', name='unique_customer_vehicle'),
    )
