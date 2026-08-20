from decimal import Decimal
from typing import Optional
from pydantic import Field
from backend.app.schemas.common import BaseSchema

class DailyTankStockCreate(BaseSchema):
    daily_log_id: int = Field(..., gt=0)
    tank_id: int = Field(..., gt=0)
    product_id: int = Field(..., gt=0)
    opening_dip_liters: Decimal = Field(..., ge=Decimal("0.00"))
    stock_in_purchase_liters: Decimal = Field(Decimal("0.00"), ge=Decimal("0.00"))
    testing_loss_liters: Decimal = Field(Decimal("0.00"), ge=Decimal("0.00"))
    net_sales_liters: Decimal = Field(Decimal("0.00"), ge=Decimal("0.00"))
    actual_dip_liters: Decimal = Field(..., ge=Decimal("0.00"))
    purchase_rate: Decimal = Field(..., gt=Decimal("0.0000"))

class DailyTankStockResponse(BaseSchema):
    id: int
    daily_log_id: int
    tank_id: int
    product_id: int
    opening_dip_liters: Decimal
    stock_in_purchase_liters: Decimal
    testing_loss_liters: Decimal
    net_sales_liters: Decimal
    expected_closing_liters: Decimal
    actual_dip_liters: Decimal
    stock_gain_loss_liters: Decimal
    purchase_rate: Decimal
    stock_gain_loss_value_pkr: Decimal
