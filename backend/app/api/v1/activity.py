from typing import List
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from backend.app.database.session import get_db
from backend.app.schemas.activity import ActivityItem
from backend.app.services.activity_service import ActivityService
from backend.app.core.logging_config import get_logger

router = APIRouter(prefix="/activity", tags=["Activity"])
logger = get_logger(__name__, prefix="API")

@router.get("/recent", response_model=List[ActivityItem])
def get_recent_activity(skip: int = Query(0, ge=0), limit: int = Query(20, ge=1, le=100), db: Session = Depends(get_db)):
    logger.info(f"GET /activity/recent called with skip={skip}, limit={limit}")
    return ActivityService.get_recent_activity(db, skip=skip, limit=limit)
