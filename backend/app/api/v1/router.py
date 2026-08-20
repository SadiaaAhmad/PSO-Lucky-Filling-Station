from fastapi import APIRouter
from backend.app.api.v1.daily_logs import router as daily_logs_router
from backend.app.api.v1.fuel import router as fuel_router
from backend.app.api.v1.stock import router as stock_router
from backend.app.api.v1.customers import router as customers_router
from backend.app.api.v1.credit import router as credit_router
from backend.app.api.v1.finance import router as finance_router
from backend.app.api.v1.reports import router as reports_router
from backend.app.api.v1.master import router as master_router
from backend.app.api.v1.activity import router as activity_router

api_router = APIRouter(prefix="/api/v1")

api_router.include_router(daily_logs_router)
api_router.include_router(fuel_router)
api_router.include_router(stock_router)
api_router.include_router(customers_router)
api_router.include_router(credit_router)
api_router.include_router(finance_router)
api_router.include_router(reports_router)
api_router.include_router(master_router)
api_router.include_router(activity_router)
