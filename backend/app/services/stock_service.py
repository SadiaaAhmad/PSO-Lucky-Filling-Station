from decimal import Decimal
from typing import Optional
from sqlalchemy.orm import Session
from backend.app.models.daily_logs import DailyLog
from backend.app.models.tanks import Tank
from backend.app.models.products import Product
from backend.app.models.daily_tank_stocks import DailyTankStock
from backend.app.accounting.engine import AccountingEngine

import logging
logger = logging.getLogger(__name__)

class StockService:
    @staticmethod
    def record_daily_tank_stock(
        db: Session,
        daily_log_id: int,
        tank_id: int,
        product_id: int,
        opening_dip_liters: Decimal,
        stock_in_purchase_liters: Decimal,
        testing_loss_liters: Decimal,
        net_sales_liters: Decimal,
        actual_dip_liters: Decimal,
        purchase_rate: Decimal
    ) -> DailyTankStock:
        """
        Record daily UST physical dip and compute expected closing stock:
        Expected Closing = Opening Dip + Stock In - Net Sales - Testing Loss
        Stock Gain/Loss = Actual Dip - Expected Closing
        Posts balanced double-entry journal entries for stock gain/loss.
        """
        daily_log = db.query(DailyLog).filter(DailyLog.id == daily_log_id).first()
        if not daily_log:
            raise ValueError(f"Daily log {daily_log_id} not found.")

        tank = db.query(Tank).filter(Tank.id == tank_id).first()
        if not tank:
            raise ValueError(f"Tank {tank_id} not found.")

        product = db.query(Product).filter(Product.id == product_id).first()
        if not product:
            raise ValueError(f"Product {product_id} not found.")

        existing = db.query(DailyTankStock).filter(
            DailyTankStock.daily_log_id == daily_log_id,
            DailyTankStock.tank_id == tank_id
        ).first()

        if existing:
            stock = existing
            stock.opening_dip_liters = opening_dip_liters
            stock.stock_in_purchase_liters = stock_in_purchase_liters
            stock.testing_loss_liters = testing_loss_liters
            stock.net_sales_liters = net_sales_liters
            stock.actual_dip_liters = actual_dip_liters
            stock.purchase_rate = purchase_rate
        else:
            stock = DailyTankStock(
                daily_log_id=daily_log_id,
                tank_id=tank_id,
                product_id=product_id,
                opening_dip_liters=opening_dip_liters,
                stock_in_purchase_liters=stock_in_purchase_liters,
                testing_loss_liters=testing_loss_liters,
                net_sales_liters=net_sales_liters,
                actual_dip_liters=actual_dip_liters,
                purchase_rate=purchase_rate
            )
            db.add(stock)

        db.flush()

        # Compute stock gain/loss value
        gain_loss_liters = stock.stock_gain_loss_liters
        gain_loss_val = (gain_loss_liters * purchase_rate).quantize(Decimal("0.01"))
        inv_account = "1310" if product.code == "HSD" else "1320"

        engine = AccountingEngine(db)

        if gain_loss_val > Decimal("0.00"):
            # Stock Gain: Debit Inventory, Credit Stock Gain Income (4030)
            engine.create_balanced_journal(
                entry_date=daily_log.log_date,
                daily_log_id=daily_log_id,
                description=f"Physical Stock Gain ({gain_loss_liters} L) for {tank.tank_name}",
                reference=f"STOCK-GAIN-{tank_id}",
                line_specs=[
                    {"account_code": inv_account, "debit": gain_loss_val, "credit": Decimal("0.00")},
                    {"account_code": "4030", "debit": Decimal("0.00"), "credit": gain_loss_val},
                ]
            )
        elif gain_loss_val < Decimal("0.00"):
            # Stock Loss: Debit Stock Loss Expense (5010), Credit Inventory
            abs_val = abs(gain_loss_val)
            engine.create_balanced_journal(
                entry_date=daily_log.log_date,
                daily_log_id=daily_log_id,
                description=f"Physical Stock Loss ({abs(gain_loss_liters)} L) for {tank.tank_name}",
                reference=f"STOCK-LOSS-{tank_id}",
                line_specs=[
                    {"account_code": "5010", "debit": abs_val, "credit": Decimal("0.00")},
                    {"account_code": inv_account, "debit": Decimal("0.00"), "credit": abs_val},
                ]
            )

        db.commit()
        db.refresh(stock)
        return stock


    @staticmethod
    def list_tank_stocks(db: Session, daily_log_id: int):
        import logging
        from backend.app.models.daily_tank_stocks import DailyTankStock
        logger = logging.getLogger(__name__)
        logger.info(f"[DATA] List tank stocks for log {daily_log_id}")
        return db.query(DailyTankStock).filter(DailyTankStock.daily_log_id == daily_log_id, DailyTankStock.is_reversed == False).all()

    @staticmethod
    def get_latest_tank_stocks(db: Session):
        import logging
        from backend.app.models.tanks import Tank
        from backend.app.models.daily_tank_stocks import DailyTankStock
        logger = logging.getLogger(__name__)
        logger.info("[DATA] Get latest tank stocks")
        tanks = db.query(Tank).all()
        res = []
        for t in tanks:
            latest = db.query(DailyTankStock).filter(DailyTankStock.tank_id == t.id, DailyTankStock.is_reversed == False).order_by(DailyTankStock.id.desc()).first()
            if latest:
                stock_val = (latest.actual_dip_liters * latest.purchase_rate).quantize(Decimal("0.01"))
                res.append({
                    "tank_id": t.id,
                    "tank_name": t.tank_name,
                    "product_code": t.product.code if t.product else "N/A",
                    "capacity_liters": str(t.capacity_liters),
                    "actual_dip_liters": str(latest.actual_dip_liters),
                    "purchase_rate": str(latest.purchase_rate),
                    "stock_value_pkr": str(stock_val),
                    "log_date": str(latest.daily_log.log_date) if latest.daily_log else ""
                })
            else:
                res.append({
                    "tank_id": t.id,
                    "tank_name": t.tank_name,
                    "product_code": t.product.code if t.product else "N/A",
                    "capacity_liters": str(t.capacity_liters),
                    "actual_dip_liters": "0.00",
                    "purchase_rate": "0.00",
                    "stock_value_pkr": "0.00",
                    "log_date": ""
                })
        return res

    @staticmethod
    def reverse_tank_stock(db: Session, stock_id: int, reason: str):
        import logging
        from datetime import datetime
        from backend.app.models.daily_tank_stocks import DailyTankStock
        logger = logging.getLogger(__name__)
        logger.info(f"[AUDIT] Reversing tank stock {stock_id}")
        stock = db.query(DailyTankStock).filter(DailyTankStock.id == stock_id).first()
        if not stock: raise ValueError("Not found")
        stock.is_reversed = True
        stock.reversed_at = datetime.utcnow()
        stock.reversal_reason = reason
        db.commit()
        return {"msg": "Reversed"}

