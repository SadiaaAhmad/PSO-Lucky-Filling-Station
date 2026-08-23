from decimal import Decimal
from typing import List, Optional, Dict
from sqlalchemy.orm import Session
from backend.app.models.customers import Customer, CustomerVehicle
from backend.app.models.credit_transactions import CreditTransaction

import logging
logger = logging.getLogger(__name__)

class CustomerService:
    @staticmethod
    def create_customer(
        db: Session,
        account_no: str,
        name: str,
        phone: Optional[str] = None,
        credit_limit: Decimal = Decimal("0.00"),
        opening_balance: Decimal = Decimal("0.00")
    ) -> Customer:
        """Create a new customer credit account."""
        existing = db.query(Customer).filter(Customer.account_no == account_no).first()
        if existing:
            raise ValueError(f"Customer with account number '{account_no}' already exists.")

        customer = Customer(
            account_no=account_no,
            name=name,
            phone=phone,
            credit_limit=credit_limit,
            opening_balance=opening_balance
        )
        db.add(customer)
        db.commit()
        db.refresh(customer)
        return customer

    @staticmethod
    def add_customer_vehicle(
        db: Session,
        customer_id: int,
        vehicle_no: str,
        driver_name: Optional[str] = None,
        notes: Optional[str] = None
    ) -> CustomerVehicle:
        """Add a vehicle to a customer's account (1:N)."""
        customer = db.query(Customer).filter(Customer.id == customer_id).first()
        if not customer:
            raise ValueError(f"Customer {customer_id} not found.")

        existing = db.query(CustomerVehicle).filter(
            CustomerVehicle.customer_id == customer_id,
            CustomerVehicle.vehicle_no == vehicle_no
        ).first()

        if existing:
            raise ValueError(f"Vehicle '{vehicle_no}' already exists for customer {customer_id}.")

        vehicle = CustomerVehicle(
            customer_id=customer_id,
            vehicle_no=vehicle_no,
            driver_name=driver_name,
            notes=notes
        )
        db.add(vehicle)
        db.commit()
        db.refresh(vehicle)
        return vehicle

    @staticmethod
    def get_customer_balance(db: Session, customer_id: int) -> Dict:
        """
        Dynamically calculate auditable customer balance:
        Current Balance = Opening Balance + Total Credit Sales - Total Recoveries
        """
        customer = db.query(Customer).filter(Customer.id == customer_id).first()
        if not customer:
            raise ValueError(f"Customer {customer_id} not found.")

        sales = db.query(CreditTransaction).filter(
            CreditTransaction.customer_id == customer_id,
            CreditTransaction.transaction_type == "CREDIT_SALE"
        ).all()
        total_sales = sum((s.amount for s in sales), Decimal("0.00"))

        recoveries = db.query(CreditTransaction).filter(
            CreditTransaction.customer_id == customer_id,
            CreditTransaction.transaction_type == "CREDIT_RECOVERY"
        ).all()
        total_recoveries = sum((r.amount for r in recoveries), Decimal("0.00"))

        current_balance = customer.opening_balance + total_sales - total_recoveries

        return {
            "customer_id": customer.id,
            "account_no": customer.account_no,
            "name": customer.name,
            "opening_balance": customer.opening_balance,
            "total_credit_sales": total_sales,
            "total_recoveries": total_recoveries,
            "current_balance": current_balance,
            "credit_limit": customer.credit_limit,
            "available_credit": customer.credit_limit - current_balance if customer.credit_limit > 0 else Decimal("0.00")
        }

    @staticmethod
    def get_all_customers(db: Session):
        import logging
        logger = logging.getLogger(__name__)
        logger.info("[DATA] Fetching all customers")
        from sqlalchemy.orm import joinedload
        return db.query(Customer).options(joinedload(Customer.vehicles)).all()

    @staticmethod
    def get_customer(db: Session, customer_id: int):
        import logging
        logger = logging.getLogger(__name__)
        logger.info(f"[DATA] Fetching customer {customer_id}")
        from sqlalchemy.orm import joinedload
        customer = db.query(Customer).options(joinedload(Customer.vehicles)).filter(Customer.id == customer_id).first()
        if not customer:
            raise ValueError(f"Customer {customer_id} not found.")
        return customer

    @staticmethod
    def get_customer_ledger(db: Session, customer_id: int, skip: int = 0, limit: int = 100):
        import logging
        logger = logging.getLogger(__name__)
        logger.info(f"[DATA] Fetching ledger for customer {customer_id}")
        return db.query(CreditTransaction).filter(
            CreditTransaction.customer_id == customer_id,
            CreditTransaction.is_reversed == False
        ).order_by(CreditTransaction.created_at.desc()).offset(skip).limit(limit).all()

    @staticmethod
    def delete_customer(db: Session, customer_id: int):
        customer = db.query(Customer).filter(Customer.id == customer_id).first()
        if not customer:
            raise ValueError(f"Customer {customer_id} not found.")
        db.delete(customer)
        db.commit()
        return True
