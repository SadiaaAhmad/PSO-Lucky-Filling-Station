from decimal import Decimal
from typing import Optional, List
from pydantic import Field, model_validator
from backend.app.schemas.common import BaseSchema

class NozzleReadingItem(BaseSchema):
    unit_id: int = Field(..., gt=0)
    opening_reading: Decimal = Field(..., ge=Decimal("0.00"))
    closing_reading: Decimal = Field(..., ge=Decimal("0.00"))

    @model_validator(mode="after")
    def check_closing_ge_opening(self):
        if self.closing_reading < self.opening_reading:
            raise ValueError(
                f"Closing reading ({self.closing_reading}) cannot be less than opening reading ({self.opening_reading}) for unit {self.unit_id}."
            )
        return self

class NozzleReadingCreate(BaseSchema):
    daily_log_id: int = Field(..., gt=0)
    readings: List[NozzleReadingItem]

class NozzleReadingResponse(BaseSchema):
    id: int
    daily_log_id: int
    unit_id: int
    opening_reading: Decimal
    closing_reading: Decimal
    gross_sale_liters: Decimal

class FuelPurchaseCreate(BaseSchema):
    daily_log_id: int = Field(..., gt=0)
    product_id: int = Field(..., gt=0)
    tank_id: int = Field(..., gt=0)
    invoice_no: Optional[str] = Field(None, max_length=50)
    purchase_liters: Decimal = Field(..., gt=Decimal("0.00"))
    purchase_rate: Decimal = Field(..., gt=Decimal("0.0000"))
    sale_rate: Decimal = Field(..., gt=Decimal("0.0000"))
    rate_diff_per_ltr: Decimal = Field(Decimal("0.0000"))

class FuelPurchaseResponse(BaseSchema):
    id: int
    daily_log_id: int
    product_id: int
    tank_id: int
    invoice_no: Optional[str] = None
    purchase_liters: Decimal
    purchase_rate: Decimal
    sale_rate: Decimal
    rate_diff_per_ltr: Decimal
    rate_diff_amount: Decimal
