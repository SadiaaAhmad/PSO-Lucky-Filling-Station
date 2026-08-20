from typing import Optional
from decimal import Decimal
from pydantic import BaseModel
from backend.app.schemas.common import BaseSchema
from datetime import datetime

class ProductResponse(BaseSchema):
    id: int
    code: str
    name: str
    unit: str
    default_margin_rate: Decimal

class TankResponse(BaseSchema):
    id: int
    tank_name: str
    product_id: int
    product_code: str
    product_name: str
    capacity_liters: Decimal

class DispensingUnitResponse(BaseSchema):
    id: int
    unit_number: int
    name: str
    product_id: int
    product_code: str
    tank_id: int
    tank_name: str
    is_active: bool

class AccountResponse(BaseSchema):
    id: int
    account_code: str
    name: str
    type: str
    description: Optional[str] = None
    is_active: bool

class StationConfigResponse(BaseSchema):
    id: int
    station_name: str
    station_id: str
    address: str
    license_no: str
    contact_phone: str
    hsd_current_rate: Decimal
    pmg_current_rate: Decimal
    updated_at: datetime

class StationConfigUpdate(BaseModel):
    station_name: Optional[str] = None
    station_id: Optional[str] = None
    address: Optional[str] = None
    license_no: Optional[str] = None
    contact_phone: Optional[str] = None
    hsd_current_rate: Optional[Decimal] = None
    pmg_current_rate: Optional[Decimal] = None
