from sqlalchemy import Column, Integer, Numeric, ForeignKey, CheckConstraint, Boolean, DateTime, String
from sqlalchemy.orm import relationship, column_property
from backend.app.database.base import Base

class NozzleReading(Base):
    __tablename__ = "nozzle_readings"

    id = Column(Integer, primary_key=True, index=True)
    daily_log_id = Column(Integer, ForeignKey("daily_logs.id", ondelete="CASCADE"), nullable=False)
    unit_id = Column(Integer, ForeignKey("dispensing_units.id"), nullable=False)
    opening_reading = Column(Numeric(12, 2), nullable=False)
    closing_reading = Column(Numeric(12, 2), nullable=False)
    is_reversed = Column(Boolean, server_default='false', default=False)
    reversed_at = Column(DateTime(timezone=True), nullable=True)
    reversal_reason = Column(String(255), nullable=True)

    daily_log = relationship("DailyLog", back_populates="nozzle_readings")
    unit = relationship("DispensingUnit", back_populates="nozzle_readings")

    @property
    def gross_sale_liters(self):
        return self.closing_reading - self.opening_reading

    __table_args__ = (
        CheckConstraint('closing_reading >= opening_reading', name='chk_nozzle_reading'),
    )
