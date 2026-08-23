from datetime import date
from typing import List, Optional
from sqlalchemy.orm import Session
from backend.app.models.daily_logs import DailyLog

import logging
logger = logging.getLogger(__name__)

class DailyLogService:
    @staticmethod
    def create_daily_log(db: Session, log_date: date, notes: Optional[str] = None) -> DailyLog:
        """Create a new daily operational log header."""
        existing = db.query(DailyLog).filter(DailyLog.log_date == log_date).first()
        if existing:
            raise ValueError(f"Daily log for date {log_date} already exists.")
        
        daily_log = DailyLog(log_date=log_date, status="DRAFT", notes=notes)
        db.add(daily_log)
        db.commit()
        db.refresh(daily_log)
        return daily_log

    @staticmethod
    def get_or_create_daily_log_by_date(db: Session, log_date: date, notes: Optional[str] = None) -> DailyLog:
        """Fetch daily log by date, or automatically create one if none exists."""
        log = db.query(DailyLog).filter(DailyLog.log_date == log_date).first()
        if not log:
            log = DailyLog(log_date=log_date, status="OPEN", notes=notes or f"Daily Operations for {log_date}")
            db.add(log)
            db.commit()
            db.refresh(log)
        return log

    @staticmethod
    def get_daily_log_by_date(db: Session, log_date: date) -> Optional[DailyLog]:
        """Fetch daily log by date."""
        return db.query(DailyLog).filter(DailyLog.log_date == log_date).first()

    @staticmethod
    def get_daily_log_by_id(db: Session, log_id: int) -> Optional[DailyLog]:
        """Fetch daily log by ID."""
        return db.query(DailyLog).filter(DailyLog.id == log_id).first()

    @staticmethod
    def close_daily_log(db: Session, log_id: int) -> DailyLog:
        """Mark daily log status as CLOSED."""
        daily_log = db.query(DailyLog).filter(DailyLog.id == log_id).first()
        if not daily_log:
            raise ValueError(f"Daily log with ID {log_id} not found.")
        
        daily_log.status = "CLOSED"
        db.commit()
        db.refresh(daily_log)
        return daily_log

    @staticmethod
    def delete_daily_log(db: Session, log_id: int) -> bool:
        """Delete daily log and all associated cascading records."""
        daily_log = db.query(DailyLog).filter(DailyLog.id == log_id).first()
        if not daily_log:
            raise ValueError(f"Daily log with ID {log_id} not found.")
        
        from backend.app.models.journal import JournalEntry
        db.query(JournalEntry).filter(JournalEntry.daily_log_id == log_id).delete()
        
        db.delete(daily_log)
        db.commit()
        return True

    @staticmethod
    def get_daily_logs(db: Session, skip: int = 0, limit: int = 100):
        """List daily logs with embedded summary data for 100% fast, instant rendering."""
        from decimal import Decimal
        from sqlalchemy.orm import joinedload
        from backend.app.models.daily_logs import DailyLog
        from backend.app.models.nozzle_readings import NozzleReading
        from backend.app.models.daily_tank_stocks import DailyTankStock
        from backend.app.models.credit_transactions import CreditTransaction
        from backend.app.models.card_transactions import CardTransaction
        from backend.app.models.journal import JournalEntry, JournalLine

        logs = db.query(DailyLog).order_by(DailyLog.log_date.desc()).offset(skip).limit(limit).all()
        log_ids = [l.id for l in logs]

        if not log_ids:
            return []

        nozzle_map = {}
        for nr in db.query(NozzleReading).filter(NozzleReading.daily_log_id.in_(log_ids), NozzleReading.is_reversed == False).all():
            nozzle_map[nr.daily_log_id] = nozzle_map.get(nr.daily_log_id, Decimal("0.00")) + (nr.gross_sale_liters or Decimal("0.00"))

        card_map = {}
        for ct in db.query(CardTransaction).filter(CardTransaction.daily_log_id.in_(log_ids), CardTransaction.is_reversed == False).all():
            card_map[ct.daily_log_id] = card_map.get(ct.daily_log_id, Decimal("0.00")) + (ct.amount or Decimal("0.00"))

        credit_sale_map = {}
        credit_recov_map = {}
        for cr in db.query(CreditTransaction).filter(CreditTransaction.daily_log_id.in_(log_ids), CreditTransaction.is_reversed == False).all():
            if cr.transaction_type == 'CREDIT_SALE':
                credit_sale_map[cr.daily_log_id] = credit_sale_map.get(cr.daily_log_id, Decimal("0.00")) + (cr.amount or Decimal("0.00"))
            elif cr.transaction_type == 'CREDIT_RECOVERY':
                credit_recov_map[cr.daily_log_id] = credit_recov_map.get(cr.daily_log_id, Decimal("0.00")) + (cr.amount or Decimal("0.00"))

        expense_map = {}
        j_lines = (
            db.query(JournalLine)
            .join(JournalEntry)
            .options(joinedload(JournalLine.account))
            .filter(
                JournalEntry.daily_log_id.in_(log_ids),
                JournalEntry.is_reversed == False
            )
            .all()
        )
        for jl in j_lines:
            if jl.debit > 0 and jl.account and str(jl.account.account_code).startswith('5'):
                log_id = jl.journal_entry.daily_log_id
                expense_map[log_id] = expense_map.get(log_id, Decimal("0.00")) + jl.debit

        res = []
        for l in logs:
            summary = {
                "gross_liters_dispensed": nozzle_map.get(l.id, Decimal("0.00")),
                "card_sales_pkr": card_map.get(l.id, Decimal("0.00")),
                "credit_sales_pkr": credit_sale_map.get(l.id, Decimal("0.00")),
                "credit_recoveries_pkr": credit_recov_map.get(l.id, Decimal("0.00")),
                "expenses_pkr": expense_map.get(l.id, Decimal("0.00")),
                "actual_dip_hsd": Decimal("0.00"),
                "actual_dip_pmg": Decimal("0.00"),
            }
            res.append({
                "id": l.id,
                "log_date": l.log_date,
                "status": l.status,
                "notes": l.notes,
                "created_at": l.created_at,
                "updated_at": l.updated_at,
                "summary": summary
            })
        return res


    @staticmethod
    def get_daily_log_detail(db: Session, log_id: int):
        import logging
        from decimal import Decimal
        from backend.app.models.daily_logs import DailyLog
        from backend.app.models.nozzle_readings import NozzleReading
        from backend.app.models.daily_tank_stocks import DailyTankStock
        from backend.app.models.fuel_purchases import FuelPurchase
        from backend.app.models.credit_transactions import CreditTransaction
        from backend.app.models.card_transactions import CardTransaction
        from backend.app.models.journal import JournalEntry
        
        logger = logging.getLogger(__name__)
        logger.info(f"[DATA] Loading daily log {log_id} with all nested relationships")
        
        log = db.query(DailyLog).filter(DailyLog.id == log_id).first()
        if not log:
            raise ValueError(f"Daily log {log_id} not found")
            
        # Build product rate map for this daily log
        rate_map = {}
        for ts in db.query(DailyTankStock).filter(DailyTankStock.daily_log_id == log_id).all():
            if ts.product:
                rate_map[ts.product.code] = ts.purchase_rate

        nozzle_readings = []
        for nr in db.query(NozzleReading).filter(NozzleReading.daily_log_id == log_id, NozzleReading.is_reversed == False).all():
            product_code = nr.unit.product.code if nr.unit and nr.unit.product else "N/A"
            product_rate = rate_map.get(product_code, nr.unit.product.default_margin_rate if nr.unit and nr.unit.product else Decimal('300.00'))
            reading_sales_rs = (nr.gross_sale_liters * product_rate).quantize(Decimal('0.01'))
            
            nozzle_readings.append({
                "id": nr.id,
                "unit_id": nr.unit_id,
                "unit_name": nr.unit.name if nr.unit else f"Unit {nr.unit_id}",
                "product_code": product_code,
                "opening_reading": nr.opening_reading,
                "closing_reading": nr.closing_reading,
                "gross_sale_liters": nr.gross_sale_liters,
                "sale_rate": product_rate,
                "sale_amount_pkr": reading_sales_rs,
                "is_reversed": nr.is_reversed
            })
            
        tank_stocks = []
        fuel_sales_pkr = Decimal('0.00')
        for ts in db.query(DailyTankStock).filter(DailyTankStock.daily_log_id == log_id, DailyTankStock.is_reversed == False).all():
            sales_pkr = ts.total_sales_pkr
            fuel_sales_pkr += sales_pkr
            tank_stocks.append({
                "id": ts.id,
                "tank_id": ts.tank_id,
                "tank_name": ts.tank.tank_name if ts.tank else f"Tank {ts.tank_id}",
                "product_code": ts.product.code if ts.product else "N/A",
                "opening_dip_liters": ts.opening_dip_liters,
                "stock_in_purchase_liters": ts.stock_in_purchase_liters,
                "testing_loss_liters": ts.testing_loss_liters,
                "net_sales_liters": ts.net_sales_liters,
                "expected_closing_liters": ts.expected_closing_liters,
                "actual_dip_liters": ts.actual_dip_liters,
                "stock_gain_loss_liters": ts.stock_gain_loss_liters,
                "purchase_rate": ts.purchase_rate,
                "rate_difference": ts.rate_difference or Decimal('0.00'),
                "sale_rate": ts.sale_rate,
                "total_sales_pkr": sales_pkr,
                "rate_diff_pkr": ts.rate_diff_pkr,
                "stock_gain_loss_value_pkr": ts.stock_gain_loss_value_pkr,
                "lube_oil_sale_pkr": ts.lube_oil_sale_pkr or Decimal('0.00'),
                "is_reversed": ts.is_reversed
            })

            
        purchases = []
        for fp in db.query(FuelPurchase).filter(FuelPurchase.daily_log_id == log_id, FuelPurchase.is_reversed == False).all():
            purchases.append({
                "id": fp.id,
                "product_code": fp.product.code if fp.product else "N/A",
                "tank_name": fp.tank.tank_name if fp.tank else f"Tank {fp.tank_id}",
                "invoice_no": fp.invoice_no,
                "purchase_liters": fp.purchase_liters,
                "purchase_rate": fp.purchase_rate,
                "sale_rate": fp.sale_rate,
                "created_at": None,
                "is_reversed": fp.is_reversed
            })
            
        credit_sales = Decimal('0.00')
        credit_recov = Decimal('0.00')
        credit_tx = []
        for ct in db.query(CreditTransaction).filter(CreditTransaction.daily_log_id == log_id, CreditTransaction.is_reversed == False).all():
            credit_tx.append(ct)
            if ct.transaction_type == 'CREDIT_SALE':
                credit_sales += ct.amount
            elif ct.transaction_type == 'CREDIT_RECOVERY':
                credit_recov += ct.amount
                
        card_sales = Decimal('0.00')
        card_tx = []
        for c in db.query(CardTransaction).filter(CardTransaction.daily_log_id == log_id, CardTransaction.is_reversed == False).all():
            card_tx.append(c)
            card_sales += c.amount
            
        expenses = Decimal('0.00')
        for j in db.query(JournalEntry).filter(
            ((JournalEntry.daily_log_id == log_id) | (JournalEntry.entry_date == log.log_date)),
            JournalEntry.is_reversed == False
        ).all():
            for l in j.lines:
                if l.debit > 0 and l.account and str(l.account.account_code).startswith('5'):
                    expenses += l.debit
                        
        logger.info("[CALC] Computed Cash Movement Summary")
        net_cash = fuel_sales_pkr - credit_sales + credit_recov + card_sales - expenses
        
        cash_movement = {
            "total_fuel_sales_pkr": fuel_sales_pkr,
            "total_credit_sales_pkr": credit_sales,
            "total_credit_recoveries_pkr": credit_recov,
            "total_card_sales_pkr": card_sales,
            "total_expenses_pkr": expenses,
            "net_cash_pkr": net_cash
        }
        
        return {
            "id": log.id,
            "log_date": log.log_date,
            "status": log.status,
            "notes": log.notes,
            "created_at": log.created_at,
            "updated_at": log.updated_at,
            "nozzle_readings": nozzle_readings,
            "tank_stocks": tank_stocks,
            "fuel_purchases": purchases,
            "credit_transactions": credit_tx,
            "card_transactions": card_tx,
            "cash_movement": cash_movement
        }

