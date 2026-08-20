from decimal import Decimal
from typing import Optional
from pydantic import Field
from backend.app.schemas.common import BaseSchema

class ExpenseCreate(BaseSchema):
    daily_log_id: int = Field(..., gt=0)
    expense_account_code: str = Field(..., pattern="^5\\d{3}$") # Must be 5000 series
    amount: Decimal = Field(..., gt=Decimal("0.00"))
    description: str = Field(..., min_length=2, max_length=255)
    payment_account_code: str = Field("1010", pattern="^(1010|1020)$")

class CardTransactionCreate(BaseSchema):
    daily_log_id: int = Field(..., gt=0)
    card_type: str = Field(..., pattern="^(BANK_CARD|BPSO_CARD)$")
    liters: Decimal = Field(Decimal("0.00"), ge=Decimal("0.00"))
    amount: Decimal = Field(..., gt=Decimal("0.00"))
    bank_charges: Decimal = Field(Decimal("0.00"), ge=Decimal("0.00"))

class CardTransactionResponse(BaseSchema):
    id: int
    daily_log_id: int
    card_type: str
    liters: Decimal
    amount: Decimal
    bank_charges: Decimal

class OwnerDrawCreate(BaseSchema):
    daily_log_id: int = Field(..., gt=0)
    amount: Decimal = Field(..., gt=Decimal("0.00"))
    description: Optional[str] = Field("Owner Drawings / Home Expense", max_length=255)


class ExpenseResponse(BaseSchema):
    id: int
    daily_log_id: Optional[int]
    account_code: str
    account_name: str
    amount: Decimal
    description: str
    payment_method: str
    created_at: datetime
    is_reversed: bool = False

