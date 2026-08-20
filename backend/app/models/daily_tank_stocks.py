from sqlalchemy import Column, Integer, Numeric, ForeignKey, UniqueConstraint, Boolean, DateTime, String
from sqlalchemy.orm import relationship
from backend.app.database.base import Base

class DailyTankStock(Base):
    __tablename__ = "daily_tank_stocks"

    id = Column(Integer, primary_key=True, index=True)
    daily_log_id = Column(Integer, ForeignKey("daily_logs.id", ondelete="CASCADE"), nullable=False)
    tank_id = Column(Integer, ForeignKey("tanks.id"), nullable=False)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    opening_dip_liters = Column(Numeric(12, 2), nullable=False)
    stock_in_purchase_liters = Column(Numeric(12, 2), nullable=False, default=0.00)
    testing_loss_liters = Column(Numeric(12, 2), nullable=False, default=0.00)
    net_sales_liters = Column(Numeric(12, 2), nullable=False, default=0.00)
    actual_dip_liters = Column(Numeric(12, 2), nullable=False)
    purchase_rate = Column(Numeric(10, 4), nullable=False)
    rate_difference = Column(Numeric(10, 4), nullable=False, default=0.00)
    closing_meter_liters = Column(Numeric(12, 2), nullable=True)
    lube_oil_sale_pkr = Column(Numeric(14, 2), nullable=True, default=0.00)
    is_reversed = Column(Boolean, server_default='false', default=False)
    reversed_at = Column(DateTime(timezone=True), nullable=True)
    reversal_reason = Column(String(255), nullable=True)

    daily_log = relationship("DailyLog", back_populates="daily_tank_stocks")
    tank = relationship("Tank", back_populates="daily_stocks")
    product = relationship("Product")

    @property
    def expected_closing_liters(self):
        if self.closing_meter_liters is not None and self.closing_meter_liters > 0:
            return self.closing_meter_liters
        return self.opening_dip_liters + self.stock_in_purchase_liters - self.net_sales_liters - self.testing_loss_liters

    @property
    def stock_gain_loss_liters(self):
        return self.actual_dip_liters - self.expected_closing_liters

    @property
    def sale_rate(self):
        return self.purchase_rate + (self.rate_difference or 0)

    @property
    def total_sales_pkr(self):
        # Use gross sales (net + testing loss) to match Excel formula (gross × purchase_rate)
        gross_sales = self.net_sales_liters + (self.testing_loss_liters or 0)
        return gross_sales * self.purchase_rate

    @property
    def rate_diff_pkr(self):
        return self.actual_dip_liters * (self.rate_difference or 0)

    @property
    def stock_gain_loss_value_pkr(self):
        return self.stock_gain_loss_liters * self.purchase_rate

    __table_args__ = (
        UniqueConstraint('daily_log_id', 'tank_id', name='unique_daily_tank_stock'),
    )
