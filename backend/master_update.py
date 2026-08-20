import os
import re

# Helper function to append to a file
def append_to_file(path, content):
    with open(path, 'a', encoding='utf-8') as f:
        f.write("\n" + content + "\n")

# Helper function to replace in file
def replace_in_file(path, pattern, repl, flags=0):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    content = re.sub(pattern, repl, content, flags=flags)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

# ----------------- PART 3: DAILY LOG DETAIL -----------------

daily_log_schemas = '''
from datetime import date
from typing import Optional, List
from decimal import Decimal
from pydantic import BaseModel
from backend.app.schemas.common import BaseSchema
from backend.app.schemas.credit import CreditTransactionResponse
from backend.app.schemas.finance import CardTransactionResponse

class NozzleReadingDetail(BaseSchema):
    id: int
    unit_id: int
    unit_name: str
    product_code: str
    opening_reading: Decimal
    closing_reading: Decimal
    gross_sale_liters: Decimal
    is_reversed: bool = False

class TankStockDetail(BaseSchema):
    id: int
    tank_id: int
    tank_name: str
    product_code: str
    opening_dip_liters: Decimal
    stock_in_purchase_liters: Decimal
    testing_loss_liters: Decimal
    net_sales_liters: Decimal
    expected_closing_liters: Decimal
    actual_dip_liters: Decimal
    stock_gain_loss_liters: Decimal
    purchase_rate: Decimal
    stock_gain_loss_value_pkr: Decimal
    is_reversed: bool = False

class PurchaseDetail(BaseSchema):
    id: int
    product_code: str
    tank_name: str
    invoice_no: Optional[str]
    purchase_liters: Decimal
    purchase_rate: Decimal
    sale_rate: Decimal
    created_at: Optional[datetime] = None
    is_reversed: bool = False

class CashMovementSummary(BaseSchema):
    total_fuel_sales_pkr: Decimal = Decimal('0.00')
    total_credit_sales_pkr: Decimal = Decimal('0.00')
    total_credit_recoveries_pkr: Decimal = Decimal('0.00')
    total_card_sales_pkr: Decimal = Decimal('0.00')
    total_expenses_pkr: Decimal = Decimal('0.00')
    net_cash_pkr: Decimal = Decimal('0.00')

class DailyLogDetailResponse(BaseSchema):
    id: int
    log_date: date
    status: str
    notes: Optional[str]
    created_at: datetime
    updated_at: datetime
    nozzle_readings: List[NozzleReadingDetail]
    tank_stocks: List[TankStockDetail]
    fuel_purchases: List[PurchaseDetail]
    credit_transactions: List[CreditTransactionResponse]
    card_transactions: List[CardTransactionResponse]
    cash_movement: CashMovementSummary
'''
append_to_file('app/schemas/daily_log.py', daily_log_schemas)

daily_log_service = '''
    @staticmethod
    def get_daily_log_detail(db: Session, log_id: int):
        import logging
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
            
        nozzle_readings = []
        fuel_sales_pkr = Decimal('0.00')
        for nr in db.query(NozzleReading).filter(NozzleReading.daily_log_id == log_id, NozzleReading.is_reversed == False).all():
            nozzle_readings.append({
                "id": nr.id, "unit_id": nr.unit_id, "unit_name": nr.unit.name, "product_code": nr.unit.product.code,
                "opening_reading": nr.opening_reading, "closing_reading": nr.closing_reading,
                "gross_sale_liters": nr.gross_sale_liters, "is_reversed": nr.is_reversed
            })
            fuel_sales_pkr += nr.gross_sale_liters * nr.unit.product.current_price
            
        tank_stocks = []
        for ts in db.query(DailyTankStock).filter(DailyTankStock.daily_log_id == log_id, DailyTankStock.is_reversed == False).all():
            tank_stocks.append({
                "id": ts.id, "tank_id": ts.tank_id, "tank_name": ts.tank.name, "product_code": ts.product.code,
                "opening_dip_liters": ts.opening_dip_liters, "stock_in_purchase_liters": ts.stock_in_purchase_liters,
                "testing_loss_liters": ts.testing_loss_liters, "net_sales_liters": ts.net_sales_liters,
                "expected_closing_liters": ts.expected_closing_liters, "actual_dip_liters": ts.actual_dip_liters,
                "stock_gain_loss_liters": ts.stock_gain_loss_liters, "purchase_rate": ts.purchase_rate,
                "stock_gain_loss_value_pkr": ts.stock_gain_loss_value_pkr, "is_reversed": ts.is_reversed
            })
            
        purchases = []
        for fp in db.query(FuelPurchase).filter(FuelPurchase.daily_log_id == log_id, FuelPurchase.is_reversed == False).all():
            purchases.append({
                "id": fp.id, "product_code": fp.product.code, "tank_name": fp.tank.name, "invoice_no": fp.invoice_no,
                "purchase_liters": fp.purchase_liters, "purchase_rate": fp.purchase_rate, "sale_rate": fp.sale_rate,
                "created_at": None, "is_reversed": fp.is_reversed
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
        for j in db.query(JournalEntry).filter(JournalEntry.daily_log_id == log_id, JournalEntry.is_reversed == False).all():
            if 'expense' in str(j.description).lower():
                for l in j.lines:
                    if l.debit > 0 and str(l.account.code).startswith('5'):
                        expenses += l.debit
                        
        logger.info("[CALC] Computed Cash Movement Summary")
        net_cash = fuel_sales_pkr - credit_sales + credit_recov + card_sales - expenses
        
        cash_movement = {
            "total_fuel_sales_pkr": fuel_sales_pkr, "total_credit_sales_pkr": credit_sales,
            "total_credit_recoveries_pkr": credit_recov, "total_card_sales_pkr": card_sales,
            "total_expenses_pkr": expenses, "net_cash_pkr": net_cash
        }
        
        return {
            "id": log.id, "log_date": log.log_date, "status": log.status, "notes": log.notes,
            "created_at": log.created_at, "updated_at": log.updated_at,
            "nozzle_readings": nozzle_readings, "tank_stocks": tank_stocks, "fuel_purchases": purchases,
            "credit_transactions": credit_tx, "card_transactions": card_tx, "cash_movement": cash_movement
        }
'''
append_to_file('app/services/daily_log_service.py', daily_log_service)

daily_log_api = '''
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
'''
append_to_file('app/api/v1/daily_logs.py', daily_log_api)


# ----------------- PART 4: STOCK -----------------
stock_api = '''
from backend.app.schemas.common import ReversalRequest
@router.get("/tank-stocks")
def list_tank_stocks(daily_log_id: int, db: Session = Depends(get_db)):
    import logging
    logger = logging.getLogger(__name__)
    logger.info(f"[API] GET /stock/tank-stocks?daily_log_id={daily_log_id}")
    return StockService.list_tank_stocks(db, daily_log_id)

@router.get("/tank-stocks/latest")
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
'''
append_to_file('app/api/v1/stock.py', stock_api)

stock_service = '''
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
                res.append({
                    "tank_name": t.name, "product_code": t.product.code, "capacity": t.capacity,
                    "actual_dip": latest.actual_dip_liters, "purchase_rate": latest.purchase_rate,
                    "stock_value": latest.actual_dip_liters * latest.purchase_rate
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
'''
append_to_file('app/services/stock_service.py', stock_service)


# ----------------- PART 5: FUEL -----------------
fuel_api = '''
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

@router.post("/purchases/{purchase_id}/reverse")
def reverse_purchase(purchase_id: int, payload: ReversalRequest, db: Session = Depends(get_db)):
    import logging
    logger = logging.getLogger(__name__)
    logger.info(f"[API] POST /fuel/purchases/reverse")
    return FuelService.reverse_purchase(db, purchase_id, payload.reason)
'''
append_to_file('app/api/v1/fuel.py', fuel_api)

fuel_service = '''
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
'''
append_to_file('app/services/fuel_service.py', fuel_service)

# ----------------- PART 6: FINANCE -----------------
finance_schemas = '''
class ExpenseResponse(BaseSchema):
    id: int
    daily_log_id: Optional[int]
    account_code: str
    account_name: str
    amount: Decimal
    description: str
    payment_method: str
    created_at: datetime
    is_reversed: bool = False
'''
append_to_file('app/schemas/finance.py', finance_schemas)

finance_api = '''
from backend.app.schemas.common import ReversalRequest
@router.get("/expenses")
def list_expenses(daily_log_id: int, db: Session = Depends(get_db)):
    import logging
    logger = logging.getLogger(__name__)
    logger.info("[API] GET /finance/expenses")
    return FinanceService.list_expenses(db, daily_log_id)

@router.get("/card-sales")
def list_card_sales(daily_log_id: int, db: Session = Depends(get_db)):
    import logging
    logger = logging.getLogger(__name__)
    logger.info("[API] GET /finance/card-sales")
    return FinanceService.list_card_sales(db, daily_log_id)

@router.post("/expenses/{journal_id}/reverse")
def reverse_expense(journal_id: int, payload: ReversalRequest, db: Session = Depends(get_db)):
    import logging
    logger = logging.getLogger(__name__)
    logger.info("[API] POST /finance/expenses/reverse")
    return FinanceService.reverse_expense(db, journal_id, payload.reason)

@router.post("/card-sales/{card_id}/reverse")
def reverse_card_sale(card_id: int, payload: ReversalRequest, db: Session = Depends(get_db)):
    import logging
    logger = logging.getLogger(__name__)
    logger.info("[API] POST /finance/card-sales/reverse")
    return FinanceService.reverse_card_sale(db, card_id, payload.reason)
'''
append_to_file('app/api/v1/finance.py', finance_api)

finance_service = '''
    @staticmethod
    def list_expenses(db: Session, daily_log_id: int):
        import logging
        from backend.app.models.journal import JournalEntry
        logger = logging.getLogger(__name__)
        logger.info(f"[DATA] List expenses {daily_log_id}")
        entries = db.query(JournalEntry).filter(JournalEntry.daily_log_id == daily_log_id, JournalEntry.is_reversed == False).all()
        res = []
        for j in entries:
            if 'expense' in str(j.description).lower() or any(str(l.account.code).startswith('5') for l in j.lines):
                for l in j.lines:
                    if l.debit > 0 and str(l.account.code).startswith('5'):
                        res.append({
                            "id": j.id, "daily_log_id": j.daily_log_id, "account_code": l.account.code,
                            "account_name": l.account.name, "amount": l.debit, "description": l.description or j.description,
                            "payment_method": "Cash", "created_at": j.created_at, "is_reversed": j.is_reversed
                        })
        return res

    @staticmethod
    def list_card_sales(db: Session, daily_log_id: int):
        import logging
        from backend.app.models.card_transactions import CardTransaction
        logger = logging.getLogger(__name__)
        logger.info(f"[DATA] List card sales {daily_log_id}")
        return db.query(CardTransaction).filter(CardTransaction.daily_log_id == daily_log_id, CardTransaction.is_reversed == False).all()

    @staticmethod
    def reverse_expense(db: Session, journal_id: int, reason: str):
        import logging
        from backend.app.accounting.engine import AccountingEngine
        logger = logging.getLogger(__name__)
        logger.info(f"[AUDIT] Reverse expense {journal_id}")
        engine = AccountingEngine(db)
        return {"new_journal_id": engine.reverse_journal_entry(journal_id, reason).id}

    @staticmethod
    def reverse_card_sale(db: Session, card_id: int, reason: str):
        import logging
        from datetime import datetime
        from backend.app.models.card_transactions import CardTransaction
        logger = logging.getLogger(__name__)
        logger.info(f"[AUDIT] Reverse card sale {card_id}")
        sale = db.query(CardTransaction).filter(CardTransaction.id == card_id).first()
        if not sale: raise ValueError("Not found")
        sale.is_reversed = True
        sale.reversed_at = datetime.utcnow()
        sale.reversal_reason = reason
        db.commit()
        return {"msg": "Reversed"}
'''
append_to_file('app/services/finance_service.py', finance_service)

# ----------------- PART 7: CREDIT -----------------
credit_api = '''
from backend.app.schemas.common import ReversalRequest
@router.post("/transactions/{transaction_id}/reverse")
def reverse_credit_transaction(transaction_id: int, payload: ReversalRequest, db: Session = Depends(get_db)):
    import logging
    logger = logging.getLogger(__name__)
    logger.info("[API] POST /credit/transactions/reverse")
    return CreditService.reverse_credit_transaction(db, transaction_id, payload.reason)
'''
append_to_file('app/api/v1/credit.py', credit_api)

credit_service = '''
    @staticmethod
    def reverse_credit_transaction(db: Session, transaction_id: int, reason: str):
        import logging
        from datetime import datetime
        from backend.app.models.credit_transactions import CreditTransaction
        logger = logging.getLogger(__name__)
        logger.info(f"[AUDIT] Reverse credit tx {transaction_id}")
        tx = db.query(CreditTransaction).filter(CreditTransaction.id == transaction_id).first()
        if not tx: raise ValueError("Not found")
        tx.is_reversed = True
        tx.reversed_at = datetime.utcnow()
        tx.reversal_reason = reason
        db.commit()
        return {"msg": "Reversed"}
'''
append_to_file('app/services/credit_service.py', credit_service)

# ----------------- PART 8: ACCOUNTING ENGINE -----------------
accounting_engine = '''
    def reverse_journal_entry(self, original_entry_id: int, reason: str):
        import logging
        from datetime import datetime
        from backend.app.models.journal import JournalEntry, JournalLine
        logger = logging.getLogger(__name__)
        logger.info(f"[LEDGER] Reversing journal entry {original_entry_id}")
        
        orig = self.db.query(JournalEntry).filter(JournalEntry.id == original_entry_id).first()
        if not orig: raise ValueError("Not found")
        
        new_entry = JournalEntry(
            entry_date=datetime.utcnow().date(),
            daily_log_id=orig.daily_log_id,
            reference=f"REV-{orig.reference}" if orig.reference else "REV",
            description=f"REVERSAL: {orig.description}"
        )
        self.db.add(new_entry)
        self.db.flush()
        
        for line in orig.lines:
            new_line = JournalLine(
                journal_entry_id=new_entry.id,
                account_id=line.account_id,
                debit=line.credit,
                credit=line.debit,
                customer_id=line.customer_id,
                vehicle_id=line.vehicle_id,
                description=f"REVERSAL: {line.description}"
            )
            self.db.add(new_line)
            
        orig.is_reversed = True
        orig.reversed_at = datetime.utcnow()
        orig.reversal_reason = reason
        self.db.commit()
        self.db.refresh(new_entry)
        return new_entry
'''
append_to_file('app/accounting/engine.py', accounting_engine)


# ----------------- PART 9: ADD LOGGING TO SERVICES -----------------
import glob
for svc in glob.glob("app/services/*.py"):
    replace_in_file(svc, r'class ', "import logging\\nlogger = logging.getLogger(__name__)\\n\\nclass ")
