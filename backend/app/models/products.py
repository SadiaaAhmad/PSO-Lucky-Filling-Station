from sqlalchemy import Column, Integer, String, Numeric, DateTime, func
from sqlalchemy.orm import relationship
from backend.app.database.base import Base

class Product(Base):
    __tablename__ = "products"

    id = Column(Integer, primary_key=True, index=True)
    code = Column(String(20), unique=True, nullable=False, index=True) # HSD, PMG, MOBIL
    name = Column(String(100), nullable=False)                         # High Speed Diesel, etc.
    unit = Column(String(20), nullable=False, default="Liters")       # Liters, Cans
    default_margin_rate = Column(Numeric(10, 4), nullable=False, default=6.5000) # PKR / Liter
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    tanks = relationship("Tank", back_populates="product")
    dispensing_units = relationship("DispensingUnit", back_populates="product")
