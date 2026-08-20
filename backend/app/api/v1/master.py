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

@router.get("/accounts", response_model=List[AccountResponse])
def get_accounts(db: Session = Depends(get_db)):
    logger.info("GET /master/accounts called")
    return MasterService.get_accounts(db)

@router.get("/station-config", response_model=StationConfigResponse)
def get_station_config(db: Session = Depends(get_db)):
    logger.info("GET /master/station-config called")
    return MasterService.get_station_config(db)

@router.put("/station-config", response_model=StationConfigResponse)
def update_station_config(data: StationConfigUpdate, db: Session = Depends(get_db)):
    logger.info("PUT /master/station-config called")
    return MasterService.update_station_config(db, data)
