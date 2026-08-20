from datetime import datetime
from decimal import Decimal
from sqlalchemy.orm import Session, joinedload
from backend.app.models.credit_transactions import CreditTransaction
from backend.app.models.fuel_purchases import FuelPurchase
from backend.app.models.daily_tank_stocks import DailyTankStock
from backend.app.models.card_transactions import CardTransaction
from backend.app.models.journal import JournalEntry
from backend.app.schemas.activity import ActivityItem

import logging
logger = logging.getLogger(__name__)

def _normalize_dt(dt):
    if dt is None:
        return datetime.min
    if hasattr(dt, 'tzinfo') and dt.tzinfo is not None:
        return dt.replace(tzinfo=None)
    return dt

class ActivityService:
    @staticmethod
    def get_recent_activity(db: Session, skip: int = 0, limit: int = 20):
        fetch_max = skip + limit + 50
        logger.info(f"[AUDIT] Fetching recent activities (skip={skip}, limit={limit})")
        activities = []
        
        try:
            # 1. Credit Transactions
            credits = db.query(CreditTransaction).options(
                joinedload(CreditTransaction.customer),
                joinedload(CreditTransaction.daily_log)
            ).filter(CreditTransaction.is_reversed == False).order_by(CreditTransaction.id.desc()).limit(fetch_max).all()
            
            for c in credits:
                cust_name = c.customer.name if c.customer else f"Customer #{c.customer_id}"
                title = "Credit Sale" if c.transaction_type == "CREDIT_SALE" else "Credit Recovery"
                ts = _normalize_dt(c.created_at) if c.created_at else datetime.now()
                activities.append(ActivityItem(
                    id=len(activities) + 1,
                    activity_type="credit_transaction",
                    title=title,
                    subtitle=f"{cust_name} {f'({c.reference})' if c.reference else ''}",
                    amount=c.amount,
                    amount_sign="-" if c.transaction_type == "CREDIT_SALE" else "+",
                    timestamp=ts,
                    entity_type="credit_transaction",
                    entity_id=c.id,
                    daily_log_id=c.daily_log_id
                ))
        except Exception as e:
            logger.error(f"[ERROR] Error loading credit activities: {e}")

        try:
            # 2. Fuel Purchases
            purchases = db.query(FuelPurchase).options(
                joinedload(FuelPurchase.product),
                joinedload(FuelPurchase.tank),
                joinedload(FuelPurchase.daily_log)
            ).filter(FuelPurchase.is_reversed == False).order_by(FuelPurchase.id.desc()).limit(fetch_max).all()
            
            for p in purchases:
                prod_code = p.product.code if p.product else "Fuel"
                tank_name = p.tank.tank_name if p.tank else f"Tank #{p.tank_id}"
                tot_amount = (p.purchase_liters * p.purchase_rate).quantize(Decimal("0.01"))
                ts = _normalize_dt(datetime.combine(p.daily_log.log_date, datetime.min.time())) if p.daily_log else datetime.now()
                activities.append(ActivityItem(
                    id=len(activities) + 1,
                    activity_type="fuel_purchase",
                    title=f"Fuel Purchase ({prod_code})",
                    subtitle=f"{p.purchase_liters} L into {tank_name} {f'- Inv: {p.invoice_no}' if p.invoice_no else ''}",
                    amount=tot_amount,
                    amount_sign="-",
                    timestamp=ts,
                    entity_type="fuel_purchase",
                    entity_id=p.id,
                    daily_log_id=p.daily_log_id
                ))
        except Exception as e:
            logger.error(f"[ERROR] Error loading fuel purchase activities: {e}")

        try:
            # 3. Tank Stock Dips
            stocks = db.query(DailyTankStock).options(
                joinedload(DailyTankStock.tank),
                joinedload(DailyTankStock.product),
                joinedload(DailyTankStock.daily_log)
            ).filter(DailyTankStock.is_reversed == False).order_by(DailyTankStock.id.desc()).limit(fetch_max).all()
            
            for s in stocks:
                t_name = s.tank.tank_name if s.tank else f"Tank #{s.tank_id}"
                ts = _normalize_dt(datetime.combine(s.daily_log.log_date, datetime.min.time())) if s.daily_log else datetime.now()
                activities.append(ActivityItem(
                    id=len(activities) + 1,
                    activity_type="daily_tank_stock",
                    title="Tank Dip Measurement",
                    subtitle=f"{t_name}: {s.actual_dip_liters} L (Diff: {s.stock_gain_loss_liters} L)",
                    amount=abs(s.stock_gain_loss_value_pkr),
                    amount_sign="+" if s.stock_gain_loss_liters >= 0 else "-",
                    timestamp=ts,
                    entity_type="daily_tank_stock",
                    entity_id=s.id,
                    daily_log_id=s.daily_log_id
                ))
        except Exception as e:
            logger.error(f"[ERROR] Error loading tank dip activities: {e}")

        try:
            # 4. Card Transactions
            cards = db.query(CardTransaction).options(
                joinedload(CardTransaction.daily_log)
            ).filter(CardTransaction.is_reversed == False).order_by(CardTransaction.id.desc()).limit(fetch_max).all()
            
            for cd in cards:
                c_title = "PSO Bank Card Sale" if cd.card_type == "BANK_CARD" else "BPSO Fleet Card Sale"
                ts = _normalize_dt(datetime.combine(cd.daily_log.log_date, datetime.min.time())) if cd.daily_log else datetime.now()
                activities.append(ActivityItem(
                    id=len(activities) + 1,
                    activity_type="card_transaction",
                    title=c_title,
                    subtitle=f"{cd.liters} Liters Dispensed",
                    amount=cd.amount,
                    amount_sign="+",
                    timestamp=ts,
                    entity_type="card_transaction",
                    entity_id=cd.id,
                    daily_log_id=cd.daily_log_id
                ))
        except Exception as e:
            logger.error(f"[ERROR] Error loading card activities: {e}")

        try:
            # 5. Operating Expenses
            journals = db.query(JournalEntry).options(
                joinedload(JournalEntry.lines)
            ).filter(JournalEntry.is_reversed == False).order_by(JournalEntry.id.desc()).limit(fetch_max).all()
            
            for j in journals:
                if 'expense' in str(j.description).lower() or any(str(l.account.account_code).startswith('5') for l in j.lines if l.account):
                    exp_amt = sum((l.debit for l in j.lines if l.debit > 0 and l.account and str(l.account.account_code).startswith('5')), Decimal("0.00"))
                    if exp_amt == Decimal("0.00"):
                        exp_amt = sum((l.debit for l in j.lines if l.debit > 0), Decimal("0.00"))
                    # Always use entry_date (the actual accounting date) — not created_at (the seed run time)
                    if j.entry_date:
                        ts = _normalize_dt(datetime.combine(j.entry_date, datetime.min.time()))
                    elif j.created_at:
                        ts = _normalize_dt(j.created_at)
                    else:
                        ts = datetime.now()
                    activities.append(ActivityItem(
                        id=len(activities) + 1,
                        activity_type="journal_entry",
                        title="Station Expense",
                        subtitle=str(j.description),
                        amount=exp_amt,
                        amount_sign="-",
                        timestamp=ts,
                        entity_type="journal_entry",
                        entity_id=j.id,
                        daily_log_id=j.daily_log_id
                    ))
        except Exception as e:
            logger.error(f"[ERROR] Error loading expense activities: {e}")

        try:
            # 6. Daily Operations Logs
            from backend.app.models.daily_logs import DailyLog
            logs = db.query(DailyLog).order_by(DailyLog.id.desc()).limit(fetch_max).all()
            for l in logs:
                ts = _normalize_dt(l.created_at) if l.created_at else _normalize_dt(datetime.combine(l.log_date, datetime.min.time()))
                activities.append(ActivityItem(
                    id=len(activities) + 1,
                    activity_type="daily_log",
                    title="Daily Operations Log",
                    subtitle=f"Log for {l.log_date} ({l.status})",
                    amount=None,
                    amount_sign="",
                    timestamp=ts,
                    entity_type="daily_log",
                    entity_id=l.id,
                    daily_log_id=l.id
                ))
        except Exception as e:
            logger.error(f"[ERROR] Error loading daily log activities: {e}")

        # Sort all by normalized timestamp DESC and return slice for skip/limit
        activities.sort(key=lambda x: _normalize_dt(x.timestamp), reverse=True)
        return activities[skip : skip + limit]
