from sqlalchemy import Column, Integer, String, Numeric, ForeignKey, Boolean, DateTime
from sqlalchemy.orm import relationship
from backend.app.database.base import Base

class FuelPurchase(Base):
    __tablename__ = "fuel_purchases"

    id = Column(Integer, primary_key=True, index=True)
    daily_log_id = Column(Integer, ForeignKey("daily_logs.id", ondelete="CASCADE"), nullable=False)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    tank_id = Column(Integer, ForeignKey("tanks.id"), nullable=False)
    invoice_no = Column(String(50), nullable=True)
    purchase_liters = Column(Numeric(12, 2), nullable=False)
    purchase_rate = Column(Numeric(10, 4), nullable=False)
    sale_rate = Column(Numeric(10, 4), nullable=False)
    rate_diff_per_ltr = Column(Numeric(10, 4), default=0.0000)
    is_reversed = Column(Boolean, server_default='false', default=False)
    reversed_at = Column(DateTime(timezone=True), nullable=True)
    reversal_reason = Column(String(255), nullable=True)

    daily_log = relationship("DailyLog", back_populates="fuel_purchases")
    product = relationship("Product")
    tank = relationship("Tank")

    @property
    def rate_diff_amount(self):
        return self.purchase_liters * self.rate_diff_per_ltr
