from datetime import date
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from backend.app.database.session import get_db
from backend.app.schemas.reports import MonthlyPnLResponse, DailySummaryResponse
from backend.app.services.report_service import ReportService

from backend.app.core.cache import api_cache

router = APIRouter(prefix="/reports", tags=["Financial & Operational Reports"])

@router.get("/latest-monthly", response_model=MonthlyPnLResponse)
def get_latest_monthly_pnl(db: Session = Depends(get_db)):
    """Fetch P&L Statement for the most recent active accounting month."""
    cache_key = "latest_monthly_pnl"
    cached = api_cache.get(cache_key)
    if cached is not None:
        return cached
    res = ReportService.get_latest_monthly_profit_loss(db)
    api_cache.set(cache_key, res, ttl_seconds=60)
    return res

@router.get("/latest-daily", response_model=DailySummaryResponse)
def get_latest_daily_summary(db: Session = Depends(get_db)):
    """Fetch operational summary for the most recent active daily log."""
    return ReportService.get_latest_daily_summary(db)

@router.get("/monthly/{year}/{month}", response_model=MonthlyPnLResponse)
def generate_monthly_profit_loss(year: int, month: int, db: Session = Depends(get_db)):
    """Generate dynamic monthly Profit & Loss Statement from general ledger lines."""
    try:
        return ReportService.generate_monthly_profit_loss(db, year=year, month=month)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

@router.get("/daily/{log_date}", response_model=DailySummaryResponse)
def generate_daily_summary(log_date: date, db: Session = Depends(get_db)):
    """Generate operational and cash summary for a specific date."""
    cache_key = f"daily_summary_{log_date}"
    cached = api_cache.get(cache_key)
    if cached is not None:
        return cached
    try:
        res = ReportService.generate_daily_summary(db, log_date=log_date)
        api_cache.set(cache_key, res, ttl_seconds=60)
        return res
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
