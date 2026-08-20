from datetime import date, datetime
from typing import Optional, List
from decimal import Decimal
from pydantic import BaseModel, Field
from backend.app.schemas.common import BaseSchema
from backend.app.schemas.credit import CreditTransactionResponse
from backend.app.schemas.finance import CardTransactionResponse

class DailyLogCreate(BaseSchema):
    log_date: date
    notes: Optional[str] = Field(None, max_length=500)

class DailyLogUpdate(BaseSchema):
    status: Optional[str] = Field(None, pattern="^(DRAFT|CLOSED)$")
    notes: Optional[str] = Field(None, max_length=500)

class DailyLogResponse(BaseSchema):
    id: int
    log_date: date
    status: str
    notes: Optional[str] = None
    created_at: datetime
    updated_at: datetime

class NozzleReadingDetail(BaseSchema):
    id: int
    unit_id: int
    unit_name: str
    product_code: str
    opening_reading: Decimal
    closing_reading: Decimal
    gross_sale_liters: Decimal
    is_reversed: bool = False

class TankStockDetail(BaseSchema):
    id: int
    tank_id: int
    tank_name: str
    product_code: str
    opening_dip_liters: Decimal
    stock_in_purchase_liters: Decimal
    testing_loss_liters: Decimal
    net_sales_liters: Decimal
    expected_closing_liters: Decimal
    actual_dip_liters: Decimal
    stock_gain_loss_liters: Decimal
    purchase_rate: Decimal
    rate_difference: Decimal = Decimal('0.00')
    sale_rate: Decimal = Decimal('0.00')
    total_sales_pkr: Decimal = Decimal('0.00')
    rate_diff_pkr: Decimal = Decimal('0.00')
    stock_gain_loss_value_pkr: Decimal
    lube_oil_sale_pkr: Decimal = Decimal('0.00')
    is_reversed: bool = False

class PurchaseDetail(BaseSchema):
    id: int
    product_code: str
    tank_name: str
    invoice_no: Optional[str]
    purchase_liters: Decimal
    purchase_rate: Decimal
    sale_rate: Decimal
    created_at: Optional[datetime] = None
    is_reversed: bool = False

class CashMovementSummary(BaseSchema):
    total_fuel_sales_pkr: Decimal = Decimal('0.00')
    total_credit_sales_pkr: Decimal = Decimal('0.00')
    total_credit_recoveries_pkr: Decimal = Decimal('0.00')
    total_card_sales_pkr: Decimal = Decimal('0.00')
    total_expenses_pkr: Decimal = Decimal('0.00')
    net_cash_pkr: Decimal = Decimal('0.00')

class DailyLogDetailResponse(BaseSchema):
    id: int
    log_date: date
    status: str
    notes: Optional[str]
    created_at: datetime
    updated_at: datetime
    nozzle_readings: List[NozzleReadingDetail]
    tank_stocks: List[TankStockDetail]
    fuel_purchases: List[PurchaseDetail]
    credit_transactions: List[CreditTransactionResponse]
    card_transactions: List[CardTransactionResponse]
    cash_movement: CashMovementSummary
