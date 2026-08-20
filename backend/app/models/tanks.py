from sqlalchemy import Column, Integer, String, Numeric, ForeignKey, DateTime, func
from sqlalchemy.orm import relationship
from backend.app.database.base import Base

class Tank(Base):
    __tablename__ = "tanks"

    id = Column(Integer, primary_key=True, index=True)
    tank_name = Column(String(50), nullable=False)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    capacity_liters = Column(Numeric(12, 2), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    product = relationship("Product", back_populates="tanks")
    dispensing_units = relationship("DispensingUnit", back_populates="tank")
    daily_stocks = relationship("DailyTankStock", back_populates="tank")
