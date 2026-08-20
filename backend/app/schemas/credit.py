from datetime import datetime
from decimal import Decimal
from typing import Optional
from pydantic import Field
from backend.app.schemas.common import BaseSchema

class CreditSaleCreate(BaseSchema):
    daily_log_id: int = Field(..., gt=0)
    customer_id: int = Field(..., gt=0)
    amount: Decimal = Field(..., gt=Decimal("0.00"))
    vehicle_id: Optional[int] = Field(None, gt=0)
    product_id: Optional[int] = Field(None, gt=0)
    liters: Decimal = Field(Decimal("0.00"), ge=Decimal("0.00"))
    rate_per_ltr: Decimal = Field(Decimal("0.0000"), ge=Decimal("0.0000"))
    reference: Optional[str] = Field(None, max_length=100)

class CreditRecoveryCreate(BaseSchema):
    daily_log_id: int = Field(..., gt=0)
    customer_id: int = Field(..., gt=0)
    amount: Decimal = Field(..., gt=Decimal("0.00"))
    payment_account_code: str = Field("1010", pattern="^(1010|1020)$") # 1010 Cash, 1020 Bank
    reference: Optional[str] = Field(None, max_length=100)

class CreditTransactionResponse(BaseSchema):
    id: int
    daily_log_id: int
    customer_id: int
    vehicle_id: Optional[int] = None
    product_id: Optional[int] = None
    transaction_type: str
    liters: Decimal
    rate_per_ltr: Decimal
    amount: Decimal
    reference: Optional[str] = None
    created_at: datetime
