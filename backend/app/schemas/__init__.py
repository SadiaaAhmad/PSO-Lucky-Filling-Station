from backend.app.schemas.common import BaseSchema, MessageResponse, PaginatedResponse
from backend.app.schemas.daily_log import DailyLogCreate, DailyLogUpdate, DailyLogResponse
from backend.app.schemas.fuel import (
    NozzleReadingItem, NozzleReadingCreate, NozzleReadingResponse,
    FuelPurchaseCreate, FuelPurchaseResponse
)
from backend.app.schemas.stock import DailyTankStockCreate, DailyTankStockResponse
from backend.app.schemas.customer import (
    CustomerCreate, CustomerResponse,
    CustomerVehicleCreate, CustomerVehicleResponse,
    CustomerBalanceResponse
)
from backend.app.schemas.credit import CreditSaleCreate, CreditRecoveryCreate, CreditTransactionResponse
from backend.app.schemas.finance import (
    ExpenseCreate, CardTransactionCreate, CardTransactionResponse, OwnerDrawCreate
)
from backend.app.schemas.reports import MonthlyPnLResponse, DailySummaryResponse

__all__ = [
    "BaseSchema",
    "MessageResponse",
    "PaginatedResponse",
    "DailyLogCreate",
    "DailyLogUpdate",
    "DailyLogResponse",
    "NozzleReadingItem",
    "NozzleReadingCreate",
    "NozzleReadingResponse",
    "FuelPurchaseCreate",
    "FuelPurchaseResponse",
    "DailyTankStockCreate",
    "DailyTankStockResponse",
    "CustomerCreate",
    "CustomerResponse",
    "CustomerVehicleCreate",
    "CustomerVehicleResponse",
    "CustomerBalanceResponse",
    "CreditSaleCreate",
    "CreditRecoveryCreate",
    "CreditTransactionResponse",
    "ExpenseCreate",
    "CardTransactionCreate",
    "CardTransactionResponse",
    "OwnerDrawCreate",
    "MonthlyPnLResponse",
    "DailySummaryResponse",
]
