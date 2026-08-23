from sqlalchemy.orm import Session
from sqlalchemy import select
from backend.app.models.products import Product
from backend.app.models.tanks import Tank
from backend.app.models.dispensing_units import DispensingUnit
from backend.app.models.accounts import Account
from backend.app.models.station_config import StationConfig
from backend.app.schemas.master import (
    ProductResponse,
    TankResponse,
    DispensingUnitResponse,
    AccountResponse,
    StationConfigResponse,
    StationConfigUpdate
)
from backend.app.core.logging_config import get_logger

logger = get_logger(__name__, prefix="DATA")

import logging
logger = logging.getLogger(__name__)

class MasterService:
    @staticmethod
    def get_products(db: Session):
        logger.info("Fetching products from database")
        return db.execute(select(Product).order_by(Product.code)).scalars().all()

    @staticmethod
    def get_tanks(db: Session):
        logger.info("Fetching tanks from database")
        tanks = db.execute(select(Tank)).scalars().all()
        # For simplicity in joining, return raw objects and let Pydantic handle or construct dicts
        result = []
        for tank in tanks:
            result.append({
                "id": tank.id,
                "tank_name": tank.tank_name,
                "product_id": tank.product_id,
                "product_code": tank.product.code,
                "product_name": tank.product.name,
                "capacity_liters": tank.capacity_liters
            })
        return result

    @staticmethod
    def get_dispensing_units(db: Session):
        logger.info("Fetching dispensing units from database")
        from sqlalchemy.orm import joinedload
        units = db.query(DispensingUnit).options(
            joinedload(DispensingUnit.product),
            joinedload(DispensingUnit.tank)
        ).order_by(DispensingUnit.unit_number).all()
        result = []
        for unit in units:
            result.append({
                "id": unit.id,
                "unit_number": unit.unit_number,
                "name": unit.name,
                "product_id": unit.product_id,
                "product_code": unit.product.code if unit.product else "N/A",
                "tank_id": unit.tank_id,
                "tank_name": unit.tank.tank_name if unit.tank else "N/A",
                "is_active": unit.is_active
            })
        return result

    @staticmethod
    def get_accounts(db: Session):
        logger.info("Fetching accounts from database")
        return db.execute(select(Account).where(Account.is_active == True).order_by(Account.account_code)).scalars().all()

    @staticmethod
    def create_account(db: Session, data):
        logger.info(f"Creating account code: {data.account_code}")
        existing = db.query(Account).filter(Account.account_code == data.account_code).first()
        if existing:
            if not existing.is_active:
                existing.is_active = True
                existing.name = data.name
                existing.type = data.type
                existing.description = data.description
                db.commit()
                db.refresh(existing)
                return existing
            raise ValueError(f"Account with code '{data.account_code}' already exists.")
        
        acc = Account(
            account_code=data.account_code,
            name=data.name,
            type=data.type,
            description=data.description,
            is_active=True
        )
        db.add(acc)
        db.commit()
        db.refresh(acc)
        return acc

    @staticmethod
    def delete_account(db: Session, account_id: int):
        logger.info(f"Deleting (deactivating) account ID: {account_id}")
        acc = db.query(Account).filter(Account.id == account_id).first()
        if not acc:
            raise ValueError(f"Account with ID {account_id} not found.")
        acc.is_active = False
        db.commit()
        return True

    @staticmethod
    def get_station_config(db: Session):
        logger.info("Fetching station config from database")
        config = db.execute(select(StationConfig).limit(1)).scalar_one_or_none()
        if not config:
            config = StationConfig()
            db.add(config)
            db.commit()
            db.refresh(config)
        return config

    @staticmethod
    def update_station_config(db: Session, data: StationConfigUpdate):
        logger.info("Updating station config in database")
        config = MasterService.get_station_config(db)
        update_data = data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(config, key, value)
        db.commit()
        db.refresh(config)
        return config
