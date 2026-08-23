from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from backend.app.database.session import get_db
from backend.app.schemas.master import (
    ProductResponse,
    TankResponse,
    DispensingUnitResponse,
    AccountResponse,
    StationConfigResponse,
    StationConfigUpdate
)
from backend.app.services.master_service import MasterService
from backend.app.core.logging_config import get_logger

router = APIRouter(prefix="/master", tags=["Master"])
logger = get_logger(__name__, prefix="API")

@router.get("/products", response_model=List[ProductResponse])
def get_products(db: Session = Depends(get_db)):
    logger.info("GET /master/products called")
    return MasterService.get_products(db)

@router.get("/tanks", response_model=List[TankResponse])
def get_tanks(db: Session = Depends(get_db)):
    logger.info("GET /master/tanks called")
    return MasterService.get_tanks(db)

@router.get("/dispensing-units", response_model=List[DispensingUnitResponse])
def get_dispensing_units(db: Session = Depends(get_db)):
    logger.info("GET /master/dispensing-units called")
    return MasterService.get_dispensing_units(db)

from fastapi import HTTPException, status
from backend.app.schemas.master import AccountCreate
from backend.app.core.cache import api_cache

@router.get("/accounts", response_model=List[AccountResponse])
def get_accounts(db: Session = Depends(get_db)):
    logger.info("GET /master/accounts called")
    cache_key = "master_accounts"
    cached = api_cache.get(cache_key)
    if cached is not None:
        return cached
    res = MasterService.get_accounts(db)
    api_cache.set(cache_key, res, ttl_seconds=120)
    return res

@router.post("/accounts", response_model=AccountResponse, status_code=status.HTTP_201_CREATED)
def create_account(data: AccountCreate, db: Session = Depends(get_db)):
    """Create a new Chart of Accounts entry."""
    logger.info("POST /master/accounts called")
    try:
        res = MasterService.create_account(db, data)
        api_cache.clear()
        return res
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

@router.delete("/accounts/{account_id}")
@router.post("/accounts/{account_id}/delete")
def delete_account(account_id: int, db: Session = Depends(get_db)):
    """Delete (deactivate) an account from the Chart of Accounts."""
    logger.info(f"DELETE /master/accounts/{account_id} called")
    try:
        MasterService.delete_account(db, account_id)
        api_cache.clear()
        return {"detail": f"Account {account_id} deleted successfully."}
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

@router.get("/station-config", response_model=StationConfigResponse)
def get_station_config(db: Session = Depends(get_db)):
    logger.info("GET /master/station-config called")
    return MasterService.get_station_config(db)

@router.put("/station-config", response_model=StationConfigResponse)
def update_station_config(data: StationConfigUpdate, db: Session = Depends(get_db)):
    logger.info("PUT /master/station-config called")
    return MasterService.update_station_config(db, data)
