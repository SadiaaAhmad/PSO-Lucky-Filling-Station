from sqlalchemy import Column, Integer, String, Numeric, DateTime, Text
from sqlalchemy.sql import func
from decimal import Decimal
from backend.app.database.base import Base

class StationConfig(Base):
    __tablename__ = 'station_configs'
    id = Column(Integer, primary_key=True)
    station_name = Column(String(100), default='PSO Lucky Filling Station')
    station_id = Column(String(50), default='PSO-LFS-001')
    address = Column(Text, default='')
    license_no = Column(String(50), default='')
    contact_phone = Column(String(20), default='')
    hsd_current_rate = Column(Numeric(10,4), default=Decimal('293.0000'))
    pmg_current_rate = Column(Numeric(10,4), default=Decimal('280.5000'))
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
