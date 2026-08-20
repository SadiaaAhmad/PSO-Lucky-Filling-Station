from sqlalchemy import Column, Integer, String, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from backend.app.database.base import Base

class DispensingUnit(Base):
    __tablename__ = "dispensing_units"

    id = Column(Integer, primary_key=True, index=True)
    unit_number = Column(Integer, unique=True, nullable=False, index=True) # 1..6
    name = Column(String(50), nullable=False)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    tank_id = Column(Integer, ForeignKey("tanks.id"), nullable=False)
    is_active = Column(Boolean, default=True)

    product = relationship("Product", back_populates="dispensing_units")
    tank = relationship("Tank", back_populates="dispensing_units")
    nozzle_readings = relationship("NozzleReading", back_populates="unit")
