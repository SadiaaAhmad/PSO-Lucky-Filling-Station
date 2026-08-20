from decimal import Decimal
from typing import Optional
from sqlalchemy.orm import Session
from backend.app.models.daily_logs import DailyLog
from backend.app.models.card_transactions import CardTransaction
from backend.app.models.journal import JournalEntry
from backend.app.accounting.engine import AccountingEngine

import logging
logger = logging.getLogger(__name__)

class FinanceService:
    @staticmethod
    def record_expense(
        db: Session,
        daily_log_id: int,
        expense_account_code: str,
        amount: Decimal,
        description: str,
        payment_account_code: str = "1010" # 1010 Cash, 1020 Bank
    ) -> JournalEntry:
        """
        Record a station operating expense (Salaries 5020, Freight 5030, Pump Operating Expense 5040, etc.).
        Debit Expense Account, Credit Cash/Bank.
        """
        daily_log = db.query(DailyLog).filter(DailyLog.id == daily_log_id).first()
        if not daily_log:
            raise ValueError(f"Daily log {daily_log_id} not found.")

        if amount <= Decimal("0.00"):
            raise ValueError("Expense amount must be greater than zero.")

        if not expense_account_code.startswith("5"):
            raise ValueError(f"Account code '{expense_account_code}' is not an expense account (5000 series).")

        engine = AccountingEngine(db)
        journal = engine.create_balanced_journal(
            entry_date=daily_log.log_date,
            daily_log_id=daily_log_id,
            description=description,
            reference=f"EXP-{daily_log_id}",
            line_specs=[
                {"account_code": expense_account_code, "debit": amount, "credit": Decimal("0.00")},
                {"account_code": payment_account_code, "debit": Decimal("0.00"), "credit": amount},
            ]
        )

        db.commit()
        return journal

    @staticmethod
    def record_card_sale(
        db: Session,
        daily_log_id: int,
        card_type: str, # BANK_CARD, BPSO_CARD
        liters: Decimal,
        amount: Decimal,
        bank_charges: Decimal = Decimal("0.00")
    ) -> CardTransaction:
        """
        Record POS Bank Card or BPSO Fleet Card sales:
        Debit Bank (1020), Debit Service Charges (5060), Credit Fuel Sales Margin Revenue (4010).
        """
        daily_log = db.query(DailyLog).filter(DailyLog.id == daily_log_id).first()
        if not daily_log:
            raise ValueError(f"Daily log {daily_log_id} not found.")

        if amount <= Decimal("0.00"):
            raise ValueError("Card sale amount must be greater than zero.")

        if card_type not in ["BANK_CARD", "BPSO_CARD"]:
            raise ValueError("Card type must be 'BANK_CARD' or 'BPSO_CARD'.")

        net_bank_amount = amount - bank_charges

        card_tx = CardTransaction(
            daily_log_id=daily_log_id,
            card_type=card_type,
            liters=liters,
            amount=amount,
            bank_charges=bank_charges
        )
        db.add(card_tx)
        db.flush()

        # Post Balanced Journal Entry
        engine = AccountingEngine(db)
        line_specs = [
            {"account_code": "1020", "debit": net_bank_amount, "credit": Decimal("0.00")},
            {"account_code": "4010", "debit": Decimal("0.00"), "credit": amount},
        ]
        if bank_charges > Decimal("0.00"):
            line_specs.append({"account_code": "5060", "debit": bank_charges, "credit": Decimal("0.00")})

        engine.create_balanced_journal(
            entry_date=daily_log.log_date,
            daily_log_id=daily_log_id,
            description=f"{card_type} Fuel Sale ({liters} L)",
            reference=f"CARD-SALE-{card_tx.id}",
            line_specs=line_specs
        )

        db.commit()
        db.refresh(card_tx)
        return card_tx

    @staticmethod
    def record_owner_draw(
        db: Session,
        daily_log_id: int,
        amount: Decimal,
        description: str = "Owner Drawings / Home Expense"
    ) -> JournalEntry:
        """
        Record proprietor personal withdrawal:
        Debit Owner Drawings (3020), Credit Cash in Hand (1010).
        """
        daily_log = db.query(DailyLog).filter(DailyLog.id == daily_log_id).first()
        if not daily_log:
            raise ValueError(f"Daily log {daily_log_id} not found.")

        if amount <= Decimal("0.00"):
            raise ValueError("Draw amount must be greater than zero.")

        engine = AccountingEngine(db)
        journal = engine.create_balanced_journal(
            entry_date=daily_log.log_date,
            daily_log_id=daily_log_id,
            description=description,
            reference=f"DRAW-{daily_log_id}",
            line_specs=[
                {"account_code": "3020", "debit": amount, "credit": Decimal("0.00")},
                {"account_code": "1010", "debit": Decimal("0.00"), "credit": amount},
            ]
        )

        db.commit()
        return journal


    @staticmethod
    def list_expenses(db: Session, daily_log_id: int):
        import logging
        from backend.app.models.journal import JournalEntry
        from backend.app.models.daily_logs import DailyLog
        logger = logging.getLogger(__name__)
        logger.info(f"[DATA] List expenses {daily_log_id}")
        
        daily_log = db.query(DailyLog).filter(DailyLog.id == daily_log_id).first()
        if daily_log:
            entries = db.query(JournalEntry).filter(
                ((JournalEntry.daily_log_id == daily_log_id) | (JournalEntry.entry_date == daily_log.log_date)),
                JournalEntry.is_reversed == False
            ).all()
        else:
            entries = db.query(JournalEntry).filter(JournalEntry.daily_log_id == daily_log_id, JournalEntry.is_reversed == False).all()

        res = []
        for j in entries:
            if 'expense' in str(j.description).lower() or any(str(l.account.account_code).startswith('5') for l in j.lines if l.account):
                for l in j.lines:
                    if l.debit > 0 and l.account and str(l.account.account_code).startswith('5'):
                        res.append({
                            "id": j.id, "daily_log_id": j.daily_log_id, "account_code": l.account.account_code,
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

