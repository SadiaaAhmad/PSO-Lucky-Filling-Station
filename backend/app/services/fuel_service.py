from decimal import Decimal
from typing import List, Optional
from sqlalchemy.orm import Session
from backend.app.models.daily_logs import DailyLog
from backend.app.models.dispensing_units import DispensingUnit
from backend.app.models.nozzle_readings import NozzleReading
from backend.app.models.fuel_purchases import FuelPurchase
from backend.app.models.products import Product
from backend.app.accounting.engine import AccountingEngine

import logging
logger = logging.getLogger(__name__)

class FuelService:
    @staticmethod
    def record_nozzle_readings(db: Session, daily_log_id: int, readings_data: List[dict]) -> List[NozzleReading]:
        """
        Record nozzle meter readings for a daily log.
        Validates closing_reading >= opening_reading.
        """
        daily_log = db.query(DailyLog).filter(DailyLog.id == daily_log_id).first()
        if not daily_log:
            raise ValueError(f"Daily log {daily_log_id} not found.")

        created_readings = []
        for item in readings_data:
            unit_id = item["unit_id"]
            opening = Decimal(str(item["opening_reading"]))
            closing = Decimal(str(item["closing_reading"]))

            if closing < opening:
                raise ValueError(f"Closing reading ({closing}) cannot be less than opening reading ({opening}) for unit {unit_id}.")

            unit = db.query(DispensingUnit).filter(DispensingUnit.id == unit_id).first()
            if not unit:
                raise ValueError(f"Dispensing unit {unit_id} not found.")

            # Replace or add reading
            existing = db.query(NozzleReading).filter(
                NozzleReading.daily_log_id == daily_log_id,
                NozzleReading.unit_id == unit_id
            ).first()

            if existing:
                existing.opening_reading = opening
                existing.closing_reading = closing
                created_readings.append(existing)
            else:
                nr = NozzleReading(
                    daily_log_id=daily_log_id,
                    unit_id=unit_id,
                    opening_reading=opening,
                    closing_reading=closing
                )
                db.add(nr)
                created_readings.append(nr)

        db.commit()
        for r in created_readings:
            db.refresh(r)
        return created_readings

    @staticmethod
    def record_fuel_purchase(
        db: Session,
        daily_log_id: int,
        product_id: int,
        tank_id: int,
        purchase_liters: Decimal,
        purchase_rate: Decimal,
        sale_rate: Decimal,
        rate_diff_per_ltr: Decimal = Decimal("0.0000"),
        invoice_no: Optional[str] = None
    ) -> FuelPurchase:
        """
        Record a fuel lorry delivery (Stock In) and post double-entry journal entries:
        Debit Inventory (1310/1320), Credit Accounts Payable (2010).
        If rate difference exists, post Rate Diff Profit (Credit Stock Gain Income 4030).
        """
        daily_log = db.query(DailyLog).filter(DailyLog.id == daily_log_id).first()
        if not daily_log:
            raise ValueError(f"Daily log {daily_log_id} not found.")

        product = db.query(Product).filter(Product.id == product_id).first()
        if not product:
            raise ValueError(f"Product {product_id} not found.")

        if purchase_liters <= Decimal("0.00"):
            raise ValueError("Purchase liters must be greater than zero.")

        purchase = FuelPurchase(
            daily_log_id=daily_log_id,
            product_id=product_id,
            tank_id=tank_id,
            invoice_no=invoice_no,
            purchase_liters=purchase_liters,
            purchase_rate=purchase_rate,
            sale_rate=sale_rate,
            rate_diff_per_ltr=rate_diff_per_ltr
        )
        db.add(purchase)
        db.flush()

        # Post Inventory Purchase Journal Entry
        inv_account = "1310" if product.code == "HSD" else "1320"
        total_cost = (purchase_liters * purchase_rate).quantize(Decimal("0.01"))

        engine = AccountingEngine(db)
        engine.create_balanced_journal(
            entry_date=daily_log.log_date,
            daily_log_id=daily_log_id,
            description=f"Fuel Delivery {product.code} Invoice #{invoice_no or 'N/A'}",
            reference=f"PURCHASE-{purchase.id}",
            line_specs=[
                {"account_code": inv_account, "debit": total_cost, "credit": Decimal("0.00")},
                {"account_code": "2010", "debit": Decimal("0.00"), "credit": total_cost},
            ]
        )

        # Post Rate Difference Gain if rate_diff > 0
        rate_diff_amount = (purchase_liters * rate_diff_per_ltr).quantize(Decimal("0.01"))
        if rate_diff_amount > Decimal("0.00"):
            engine.create_balanced_journal(
                entry_date=daily_log.log_date,
                daily_log_id=daily_log_id,
                description=f"Rate Difference Gain for {product.code} Invoice #{invoice_no or 'N/A'}",
                reference=f"RATE-DIFF-{purchase.id}",
                line_specs=[
                    {"account_code": inv_account, "debit": rate_diff_amount, "credit": Decimal("0.00")},
                    {"account_code": "4030", "debit": Decimal("0.00"), "credit": rate_diff_amount},
                ]
            )

        db.commit()
        db.refresh(purchase)
        return purchase


    @staticmethod
    def list_nozzle_readings(db: Session, daily_log_id: int):
        import logging
        from backend.app.models.nozzle_readings import NozzleReading
        logger = logging.getLogger(__name__)
        logger.info(f"[DATA] List nozzle readings for {daily_log_id}")
        return db.query(NozzleReading).filter(NozzleReading.daily_log_id == daily_log_id, NozzleReading.is_reversed == False).all()

    @staticmethod
    def list_purchases(db: Session, daily_log_id: int):
        import logging
        from backend.app.models.fuel_purchases import FuelPurchase
        logger = logging.getLogger(__name__)
        logger.info(f"[DATA] List purchases for {daily_log_id}")
        return db.query(FuelPurchase).filter(FuelPurchase.daily_log_id == daily_log_id, FuelPurchase.is_reversed == False).all()

    @staticmethod
    def reverse_nozzle_reading(db: Session, reading_id: int, reason: str):
        import logging
        from datetime import datetime
        from backend.app.models.nozzle_readings import NozzleReading
        logger = logging.getLogger(__name__)
        logger.info(f"[AUDIT] Reverse nozzle reading {reading_id}")
        reading = db.query(NozzleReading).filter(NozzleReading.id == reading_id).first()
        if not reading: raise ValueError("Not found")
        reading.is_reversed = True
        reading.reversed_at = datetime.utcnow()
        reading.reversal_reason = reason
        db.commit()
        return {"msg": "Reversed"}

    @staticmethod
    def restore_nozzle_reading(db: Session, reading_id: int):
        from backend.app.models.nozzle_readings import NozzleReading
        reading = db.query(NozzleReading).filter(NozzleReading.id == reading_id).first()
        if not reading: raise ValueError("Not found")
        reading.is_reversed = False
        reading.reversed_at = None
        reading.reversal_reason = None
        db.commit()
        return {"msg": "Restored"}

    @staticmethod
    def reverse_purchase(db: Session, purchase_id: int, reason: str):
        import logging
        from datetime import datetime
        from backend.app.models.fuel_purchases import FuelPurchase
        logger = logging.getLogger(__name__)
        logger.info(f"[AUDIT] Reverse fuel purchase {purchase_id}")
        purchase = db.query(FuelPurchase).filter(FuelPurchase.id == purchase_id).first()
        if not purchase: raise ValueError("Not found")
        purchase.is_reversed = True
        purchase.reversed_at = datetime.utcnow()
        purchase.reversal_reason = reason
        db.commit()
        return {"msg": "Reversed"}

    @staticmethod
    def restore_purchase(db: Session, purchase_id: int):
        from backend.app.models.fuel_purchases import FuelPurchase
        purchase = db.query(FuelPurchase).filter(FuelPurchase.id == purchase_id).first()
        if not purchase: raise ValueError("Not found")
        purchase.is_reversed = False
        purchase.reversed_at = None
        purchase.reversal_reason = None
        db.commit()
        return {"msg": "Restored"}

