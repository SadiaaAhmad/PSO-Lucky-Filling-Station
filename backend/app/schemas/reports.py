from decimal import Decimal
from typing import Dict, Any, Optional
from pydantic import Field
from backend.app.schemas.common import BaseSchema

class MonthlyPnLResponse(BaseSchema):
    year: int = Field(..., ge=2000, le=2100)
    month: int = Field(..., ge=1, le=12)
    revenue_breakdown: Dict[str, Decimal]
    total_income: Decimal
    expense_breakdown: Dict[str, Decimal]
    total_expenses: Decimal
    net_profit: Decimal

class DailySummaryResponse(BaseSchema):
    log_date: str
    status: str
    total_nozzles_recorded: int
    total_gross_liters_dispensed: Decimal
    tank_stocks_recorded: int
    total_fuel_sales_pkr: Decimal = Decimal('0.00')
    hsd_sales_liters: Decimal = Decimal('0.00')
    hsd_sales_pkr: Decimal = Decimal('0.00')
    pmg_sales_liters: Decimal = Decimal('0.00')
    pmg_sales_pkr: Decimal = Decimal('0.00')
    total_credit_sales_pkr: Decimal = Decimal('0.00')
    total_credit_recoveries_pkr: Decimal = Decimal('0.00')
    total_card_sales_pkr: Decimal = Decimal('0.00')

