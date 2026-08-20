from datetime import date
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from backend.app.database.session import get_db
from backend.app.schemas.daily_log import DailyLogCreate, DailyLogResponse
from backend.app.services.daily_log_service import DailyLogService

router = APIRouter(prefix="/daily-logs", tags=["Daily Logs"])

@router.post("/", response_model=DailyLogResponse, status_code=status.HTTP_201_CREATED)
def create_daily_log(payload: DailyLogCreate, db: Session = Depends(get_db)):
    """Create a new daily operational log header."""
    try:
        return DailyLogService.create_daily_log(db, log_date=payload.log_date, notes=payload.notes)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

@router.post("/get-or-create-by-date", response_model=DailyLogResponse)
def get_or_create_daily_log_by_date(payload: DailyLogCreate, db: Session = Depends(get_db)):
    """Fetch daily log by date, or automatically create one if none exists."""
    return DailyLogService.get_or_create_daily_log_by_date(db, log_date=payload.log_date, notes=payload.notes)

@router.get("/{id}", response_model=DailyLogResponse)
def get_daily_log(id: int, db: Session = Depends(get_db)):
    """Fetch daily log by ID."""
    log = DailyLogService.get_daily_log_by_id(db, log_id=id)
    if not log:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Daily log {id} not found.")
    return log

@router.post("/{id}/close", response_model=DailyLogResponse)
def close_daily_log(id: int, db: Session = Depends(get_db)):
    """Close a daily log."""
    try:
        return DailyLogService.close_daily_log(db, log_id=id)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

@router.get("/", response_model=List[DailyLogResponse])
def list_daily_logs(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """List daily logs with pagination."""
    return DailyLogService.get_daily_logs(db, skip=skip, limit=limit)

@router.delete("/{id}")
@router.post("/{id}/delete")
def delete_daily_log(id: int, db: Session = Depends(get_db)):
    """Delete a daily log and all associated records."""
    try:
        DailyLogService.delete_daily_log(db, log_id=id)
        return {"detail": f"Daily log {id} deleted successfully."}
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


from backend.app.schemas.daily_log import DailyLogDetailResponse
@router.get("/{log_id}/detail", response_model=DailyLogDetailResponse)
def get_daily_log_detail(log_id: int, db: Session = Depends(get_db)):
    import logging
    logger = logging.getLogger(__name__)
    logger.info(f"[API] GET /daily-logs/{log_id}/detail")
    try:
        return DailyLogService.get_daily_log_detail(db, log_id)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

