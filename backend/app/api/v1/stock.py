from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from backend.app.database.session import get_db
from backend.app.schemas.stock import DailyTankStockCreate, DailyTankStockResponse
from backend.app.services.stock_service import StockService

router = APIRouter(prefix="/stock", tags=["Tank Stock Operations"])

@router.post("/tank-stock", response_model=DailyTankStockResponse, status_code=status.HTTP_201_CREATED)
def record_daily_tank_stock(payload: DailyTankStockCreate, db: Session = Depends(get_db)):
    """Record physical UST tank dip measurements and compute stock gain/loss."""
    try:
        return StockService.record_daily_tank_stock(
            db,
            daily_log_id=payload.daily_log_id,
            tank_id=payload.tank_id,
            product_id=payload.product_id,
            opening_dip_liters=payload.opening_dip_liters,
            stock_in_purchase_liters=payload.stock_in_purchase_liters,
            testing_loss_liters=payload.testing_loss_liters,
            net_sales_liters=payload.net_sales_liters,
            actual_dip_liters=payload.actual_dip_liters,
            purchase_rate=payload.purchase_rate
        )
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


from backend.app.schemas.common import ReversalRequest

@router.get("/tank-stocks")
def list_tank_stocks(daily_log_id: int, db: Session = Depends(get_db)):
    import logging
    logger = logging.getLogger(__name__)
    logger.info(f"[API] GET /stock/tank-stocks?daily_log_id={daily_log_id}")
    return StockService.list_tank_stocks(db, daily_log_id)

@router.get("/tank-stocks/latest")
@router.get("/latest")
def get_latest_tank_stocks(db: Session = Depends(get_db)):
    import logging
    logger = logging.getLogger(__name__)
    logger.info("[API] GET /stock/tank-stocks/latest")
    return StockService.get_latest_tank_stocks(db)

@router.post("/tank-stocks/{stock_id}/reverse")
def reverse_tank_stock(stock_id: int, payload: ReversalRequest, db: Session = Depends(get_db)):
    import logging
    logger = logging.getLogger(__name__)
    logger.info(f"[API] POST /stock/tank-stocks/{stock_id}/reverse")
    return StockService.reverse_tank_stock(db, stock_id, payload.reason)
