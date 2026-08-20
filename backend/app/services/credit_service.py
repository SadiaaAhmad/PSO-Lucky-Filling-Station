from decimal import Decimal
from typing import Optional
from sqlalchemy.orm import Session
from backend.app.models.daily_logs import DailyLog
from backend.app.models.customers import Customer, CustomerVehicle
from backend.app.models.credit_transactions import CreditTransaction
from backend.app.services.customer_service import CustomerService
from backend.app.accounting.engine import AccountingEngine

import logging
logger = logging.getLogger(__name__)

class CreditService:
    @staticmethod
    def record_credit_sale(
        db: Session,
        daily_log_id: int,
        customer_id: int,
        amount: Decimal,
        vehicle_id: Optional[int] = None,
        product_id: Optional[int] = None,
        liters: Decimal = Decimal("0.00"),
        rate_per_ltr: Decimal = Decimal("0.0000"),
        reference: Optional[str] = None
    ) -> CreditTransaction:
        """
        Record a credit fuel sale (Udhaar Khata) and post balanced journal entries:
        Debit Accounts Receivable (1200), Credit Fuel Sales Margin Revenue (4010).
        """
        daily_log = db.query(DailyLog).filter(DailyLog.id == daily_log_id).first()
        if not daily_log:
            raise ValueError(f"Daily log {daily_log_id} not found.")

        customer = db.query(Customer).filter(Customer.id == customer_id).first()
        if not customer:
            raise ValueError(f"Customer {customer_id} not found.")

        if amount <= Decimal("0.00"):
            raise ValueError("Credit sale amount must be greater than zero.")

        # Check credit limit if specified
        if customer.credit_limit > Decimal("0.00"):
            balance_info = CustomerService.get_customer_balance(db, customer_id)
            if balance_info["current_balance"] + amount > customer.credit_limit:
                raise ValueError(f"Credit sale of {amount} PKR exceeds available credit limit for {customer.name}.")

        if vehicle_id:
            vehicle = db.query(CustomerVehicle).filter(
                CustomerVehicle.id == vehicle_id,
                CustomerVehicle.customer_id == customer_id
            ).first()
            if not vehicle:
                raise ValueError(f"Vehicle {vehicle_id} does not belong to customer {customer_id}.")

        credit_tx = CreditTransaction(
            daily_log_id=daily_log_id,
            customer_id=customer_id,
            vehicle_id=vehicle_id,
            product_id=product_id,
            transaction_type="CREDIT_SALE",
            liters=liters,
            rate_per_ltr=rate_per_ltr,
            amount=amount,
            reference=reference
        )
        db.add(credit_tx)
        db.flush()

        # Post Double-Entry Journal Entry
        engine = AccountingEngine(db)
        engine.create_balanced_journal(
            entry_date=daily_log.log_date,
            daily_log_id=daily_log_id,
            description=f"Credit Sale to {customer.name} (Ref: {reference or 'N/A'})",
            reference=f"CREDIT-SALE-{credit_tx.id}",
            line_specs=[
                {
                    "account_code": "1200",
                    "debit": amount,
                    "credit": Decimal("0.00"),
                    "customer_id": customer_id,
                    "vehicle_id": vehicle_id
                },
                {
                    "account_code": "4010",
                    "debit": Decimal("0.00"),
                    "credit": amount
                },
            ]
        )

        db.commit()
        db.refresh(credit_tx)
        return credit_tx

    @staticmethod
    def record_credit_recovery(
        db: Session,
        daily_log_id: int,
        customer_id: int,
        amount: Decimal,
        payment_account_code: str = "1010", # 1010 Cash, 1020 Bank
        reference: Optional[str] = None
    ) -> CreditTransaction:
        """
        Record debt recovery payment from a customer and post balanced journal entries:
        Debit Cash/Bank (1010/1020), Credit Accounts Receivable (1200).
        """
        daily_log = db.query(DailyLog).filter(DailyLog.id == daily_log_id).first()
        if not daily_log:
            raise ValueError(f"Daily log {daily_log_id} not found.")

        customer = db.query(Customer).filter(Customer.id == customer_id).first()
        if not customer:
            raise ValueError(f"Customer {customer_id} not found.")

        if amount <= Decimal("0.00"):
            raise ValueError("Recovery amount must be greater than zero.")

        if payment_account_code not in ["1010", "1020"]:
            raise ValueError("Payment account must be Cash (1010) or Bank (1020).")

        credit_tx = CreditTransaction(
            daily_log_id=daily_log_id,
            customer_id=customer_id,
            transaction_type="CREDIT_RECOVERY",
            amount=amount,
            reference=reference
        )
        db.add(credit_tx)
        db.flush()

        # Post Double-Entry Journal Entry
        engine = AccountingEngine(db)
        engine.create_balanced_journal(
            entry_date=daily_log.log_date,
            daily_log_id=daily_log_id,
            description=f"Credit Recovery from {customer.name} (Ref: {reference or 'N/A'})",
            reference=f"CREDIT-RECOVERY-{credit_tx.id}",
            line_specs=[
                {"account_code": payment_account_code, "debit": amount, "credit": Decimal("0.00")},
                {"account_code": "1200", "debit": Decimal("0.00"), "credit": amount, "customer_id": customer_id},
            ]
        )

        db.commit()
        db.refresh(credit_tx)
        return credit_tx


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

    @staticmethod
    def restore_credit_transaction(db: Session, transaction_id: int):
        from backend.app.models.credit_transactions import CreditTransaction
        tx = db.query(CreditTransaction).filter(CreditTransaction.id == transaction_id).first()
        if not tx: raise ValueError("Not found")
        tx.is_reversed = False
        tx.reversed_at = None
        tx.reversal_reason = None
        db.commit()
        return {"msg": "Restored"}

