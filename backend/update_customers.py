import os

# 1. Update customers.py
customers_api = '''
@router.get("/", response_model=List[CustomerResponse])
def list_customers(db: Session = Depends(get_db)):
    import logging
    logger = logging.getLogger(__name__)
    logger.info("[API] GET /customers/ - Listing all customers")
    return CustomerService.get_all_customers(db)

@router.get("/{id}", response_model=CustomerResponse)
def get_customer(id: int, db: Session = Depends(get_db)):
    import logging
    logger = logging.getLogger(__name__)
    logger.info(f"[API] GET /customers/{id} - Getting customer details")
    try:
        return CustomerService.get_customer(db, id)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))

from backend.app.schemas.credit import CreditTransactionResponse

@router.get("/{id}/ledger", response_model=List[CreditTransactionResponse])
def get_customer_ledger(id: int, skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    import logging
    logger = logging.getLogger(__name__)
    logger.info(f"[API] GET /customers/{id}/ledger - Getting customer ledger")
    return CustomerService.get_customer_ledger(db, id, skip, limit)
'''

with open('app/api/v1/customers.py', 'a') as f:
    f.write(customers_api)

# 2. Update customer_service.py
customers_service = '''
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
'''

with open('app/services/customer_service.py', 'a') as f:
    f.write(customers_service)
