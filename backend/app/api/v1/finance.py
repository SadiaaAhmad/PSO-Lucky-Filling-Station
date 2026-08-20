from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from backend.app.database.session import get_db
from backend.app.schemas.finance import ExpenseCreate, CardTransactionCreate, CardTransactionResponse, OwnerDrawCreate
from backend.app.services.finance_service import FinanceService

router = APIRouter(prefix="/finance", tags=["Finance & Cash Management"])

@router.post("/expense", status_code=status.HTTP_201_CREATED)
def record_expense(payload: ExpenseCreate, db: Session = Depends(get_db)):
    """Record an operating expense and post double-entry journal entry."""
    try:
        journal = FinanceService.record_expense(
            db,
            daily_log_id=payload.daily_log_id,
            expense_account_code=payload.expense_account_code,
            amount=payload.amount,
            description=payload.description,
            payment_account_code=payload.payment_account_code
        )
        return {"status": "success", "journal_id": journal.id, "entry_date": str(journal.entry_date)}
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

@router.post("/card-sale", response_model=CardTransactionResponse, status_code=status.HTTP_201_CREATED)
def record_card_sale(payload: CardTransactionCreate, db: Session = Depends(get_db)):
    """Record POS Bank Card or BPSO Fleet Card sales."""
    try:
        return FinanceService.record_card_sale(
            db,
            daily_log_id=payload.daily_log_id,
            card_type=payload.card_type,
            liters=payload.liters,
            amount=payload.amount,
            bank_charges=payload.bank_charges
        )
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

@router.post("/owner-draw", status_code=status.HTTP_201_CREATED)
def record_owner_draw(payload: OwnerDrawCreate, db: Session = Depends(get_db)):
    """Record proprietor personal withdrawal (Home Expense / Draw)."""
    try:
        journal = FinanceService.record_owner_draw(
            db,
            daily_log_id=payload.daily_log_id,
            amount=payload.amount,
            description=payload.description
        )
        return {"status": "success", "journal_id": journal.id, "entry_date": str(journal.entry_date)}
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


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

