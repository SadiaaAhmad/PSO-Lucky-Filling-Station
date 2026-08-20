from datetime import datetime
from decimal import Decimal
from typing import Optional, List
from pydantic import Field
from backend.app.schemas.common import BaseSchema

class CustomerVehicleCreate(BaseSchema):
    vehicle_no: str = Field(..., min_length=2, max_length=50)
    driver_name: Optional[str] = Field(None, max_length=100)
    notes: Optional[str] = Field(None, max_length=255)

class CustomerVehicleResponse(BaseSchema):
    id: int
    customer_id: int
    vehicle_no: str
    driver_name: Optional[str] = None
    notes: Optional[str] = None
    created_at: datetime

class CustomerCreate(BaseSchema):
    account_no: str = Field(..., min_length=3, max_length=30)
    name: str = Field(..., min_length=2, max_length=100)
    phone: Optional[str] = Field(None, max_length=20)
    credit_limit: Decimal = Field(Decimal("0.00"), ge=Decimal("0.00"))
    opening_balance: Decimal = Field(Decimal("0.00"))

class CustomerResponse(BaseSchema):
    id: int
    account_no: str
    name: str
    phone: Optional[str] = None
    credit_limit: Decimal
    opening_balance: Decimal
    created_at: datetime
    vehicles: List[CustomerVehicleResponse] = []

class CustomerBalanceResponse(BaseSchema):
    customer_id: int
    account_no: str
    name: str
    opening_balance: Decimal
    total_credit_sales: Decimal
    total_recoveries: Decimal
    current_balance: Decimal
    credit_limit: Decimal
    available_credit: Decimal
