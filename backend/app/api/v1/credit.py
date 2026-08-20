from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from backend.app.database.session import get_db
from backend.app.schemas.credit import CreditSaleCreate, CreditRecoveryCreate, CreditTransactionResponse
from backend.app.services.credit_service import CreditService

router = APIRouter(prefix="/credit", tags=["Credit Ledger (Udhaar Khata)"])

@router.post("/sale", response_model=CreditTransactionResponse, status_code=status.HTTP_201_CREATED)
def record_credit_sale(payload: CreditSaleCreate, db: Session = Depends(get_db)):
    """Record a credit fuel sale to a customer account."""
    try:
        return CreditService.record_credit_sale(
            db,
            daily_log_id=payload.daily_log_id,
            customer_id=payload.customer_id,
            amount=payload.amount,
            vehicle_id=payload.vehicle_id,
            product_id=payload.product_id,
            liters=payload.liters,
            rate_per_ltr=payload.rate_per_ltr,
            reference=payload.reference
        )
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

@router.post("/recovery", response_model=CreditTransactionResponse, status_code=status.HTTP_201_CREATED)
def record_credit_recovery(payload: CreditRecoveryCreate, db: Session = Depends(get_db)):
    """Record a debt recovery payment from a customer."""
    try:
        return CreditService.record_credit_recovery(
            db,
            daily_log_id=payload.daily_log_id,
            customer_id=payload.customer_id,
            amount=payload.amount,
            payment_account_code=payload.payment_account_code,
            reference=payload.reference
        )
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


from backend.app.schemas.common import ReversalRequest
@router.post("/transactions/{transaction_id}/reverse")
def reverse_credit_transaction(transaction_id: int, payload: ReversalRequest, db: Session = Depends(get_db)):
    import logging
    logger = logging.getLogger(__name__)
    logger.info("[API] POST /credit/transactions/reverse")
    return CreditService.reverse_credit_transaction(db, transaction_id, payload.reason)

@router.post("/transactions/{transaction_id}/restore")
def restore_credit_transaction(transaction_id: int, db: Session = Depends(get_db)):
    return CreditService.restore_credit_transaction(db, transaction_id)
