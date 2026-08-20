from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from backend.app.database.session import get_db
from backend.app.schemas.fuel import (
    NozzleReadingCreate, NozzleReadingResponse,
    FuelPurchaseCreate, FuelPurchaseResponse
)
from backend.app.services.fuel_service import FuelService

router = APIRouter(prefix="/fuel", tags=["Fuel Operations"])

@router.post("/nozzle-readings", response_model=List[NozzleReadingResponse], status_code=status.HTTP_201_CREATED)
def record_nozzle_readings(payload: NozzleReadingCreate, db: Session = Depends(get_db)):
    """Record meter readings for dispensing nozzles."""
    try:
        readings_data = [item.model_dump() for item in payload.readings]
        return FuelService.record_nozzle_readings(db, daily_log_id=payload.daily_log_id, readings_data=readings_data)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

@router.post("/purchases", response_model=FuelPurchaseResponse, status_code=status.HTTP_201_CREATED)
def record_fuel_purchase(payload: FuelPurchaseCreate, db: Session = Depends(get_db)):
    """Record a fuel lorry stock delivery (Stock In)."""
    try:
        return FuelService.record_fuel_purchase(
            db,
            daily_log_id=payload.daily_log_id,
            product_id=payload.product_id,
            tank_id=payload.tank_id,
            purchase_liters=payload.purchase_liters,
            purchase_rate=payload.purchase_rate,
            sale_rate=payload.sale_rate,
            rate_diff_per_ltr=payload.rate_diff_per_ltr,
            invoice_no=payload.invoice_no
        )
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


from backend.app.schemas.common import ReversalRequest
@router.get("/nozzle-readings")
def list_nozzle_readings(daily_log_id: int, db: Session = Depends(get_db)):
    import logging
    logger = logging.getLogger(__name__)
    logger.info(f"[API] GET /fuel/nozzle-readings")
    return FuelService.list_nozzle_readings(db, daily_log_id)

@router.get("/purchases")
def list_purchases(daily_log_id: int, db: Session = Depends(get_db)):
    import logging
    logger = logging.getLogger(__name__)
    logger.info(f"[API] GET /fuel/purchases")
    return FuelService.list_purchases(db, daily_log_id)

@router.post("/nozzle-readings/{reading_id}/reverse")
def reverse_nozzle_reading(reading_id: int, payload: ReversalRequest, db: Session = Depends(get_db)):
    import logging
    logger = logging.getLogger(__name__)
    logger.info(f"[API] POST /fuel/nozzle-readings/reverse")
    return FuelService.reverse_nozzle_reading(db, reading_id, payload.reason)

@router.post("/nozzle-readings/{reading_id}/restore")
def restore_nozzle_reading(reading_id: int, db: Session = Depends(get_db)):
    return FuelService.restore_nozzle_reading(db, reading_id)

@router.post("/purchases/{purchase_id}/reverse")
def reverse_purchase(purchase_id: int, payload: ReversalRequest, db: Session = Depends(get_db)):
    import logging
    logger = logging.getLogger(__name__)
    logger.info(f"[API] POST /fuel/purchases/reverse")
    return FuelService.reverse_purchase(db, purchase_id, payload.reason)

@router.post("/purchases/{purchase_id}/restore")
def restore_purchase(purchase_id: int, db: Session = Depends(get_db)):
    return FuelService.restore_purchase(db, purchase_id)
