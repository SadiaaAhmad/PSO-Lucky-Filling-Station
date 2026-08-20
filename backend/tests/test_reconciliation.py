from decimal import Decimal
import pytest
from sqlalchemy.orm import Session

from backend.app.database.session import SessionLocal, engine
from backend.app.database.base import Base
from backend.app.models import Account, JournalEntry, JournalLine, DailyTankStock
from backend.app.accounting.engine import AccountingEngine, UnbalancedJournalError
from backend.seed.seed_july_2026 import run_seed

@pytest.fixture(scope="module")
def db_session():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    run_seed()
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def test_chart_of_accounts_completeness(db_session: Session):
    """Verify missing accounts 4050 and 5060 exist in Chart of Accounts."""
    acc_4050 = db_session.query(Account).filter(Account.account_code == "4050").first()
    acc_5060 = db_session.query(Account).filter(Account.account_code == "5060").first()

    assert acc_4050 is not None
    assert acc_4050.name == "Holding Commission Share Revenue"
    assert acc_4050.type == "REVENUE"

    assert acc_5060 is not None
    assert acc_5060.name == "Card Service Charges Expense"
    assert acc_5060.type == "EXPENSE"

def test_journal_entries_balancing_invariant(db_session: Session):
    """Verify every single journal entry in the database has SUM(debits) == SUM(credits)."""
    entries = db_session.query(JournalEntry).all()
    assert len(entries) > 0, "No journal entries found in database!"

    for entry in entries:
        lines = db_session.query(JournalLine).filter(JournalLine.journal_entry_id == entry.id).all()
        total_debit = sum(line.debit for line in lines)
        total_credit = sum(line.credit for line in lines)
        assert round(total_debit, 2) == round(total_credit, 2), f"Journal entry #{entry.id} '{entry.description}' is unbalanced! Debit: {total_debit}, Credit: {total_credit}"

def test_unbalanced_journal_entry_raises_error(db_session: Session):
    """Verify the AccountingEngine raises UnbalancedJournalError when debits != credits."""
    engine_inst = AccountingEngine(db_session)
    with pytest.raises(UnbalancedJournalError):
        engine_inst.create_balanced_journal(
            entry_date="2026-07-31",
            description="Test Unbalanced Entry",
            line_specs=[
                {"account_code": "1010", "debit": Decimal("1000.00"), "credit": Decimal("0.00")},
                {"account_code": "4010", "debit": Decimal("0.00"), "credit": Decimal("800.00")},
            ]
        )

def test_fuel_stock_expected_closing_formula(db_session: Session):
    """Verify Expected Closing Stock formula: Opening Dip + Purchases - Net Sales - Testing Loss."""
    stocks = db_session.query(DailyTankStock).all()
    assert len(stocks) > 0

    for s in stocks:
        calculated_expected = s.opening_dip_liters + s.stock_in_purchase_liters - s.net_sales_liters - s.testing_loss_liters
        assert s.expected_closing_liters == calculated_expected

def test_july_2026_golden_reconciliation(db_session: Session):
    """
    Verify July 2026 P&L figures generated from database general ledger entries:
    - Total Income:   1,879,732.81 PKR
    - Total Expenses:   287,961.66 PKR
    - Net Profit:     1,591,771.15 PKR
    """
    revenue_accounts = db_session.query(Account).filter(Account.type == "REVENUE").all()
    rev_ids = [a.id for a in revenue_accounts]
    
    total_income_lines = db_session.query(JournalLine).filter(JournalLine.account_id.in_(rev_ids)).all()
    total_income = sum(line.credit - line.debit for line in total_income_lines)

    expense_accounts = db_session.query(Account).filter(Account.type == "EXPENSE").all()
    exp_ids = [a.id for a in expense_accounts]

    total_expense_lines = db_session.query(JournalLine).filter(JournalLine.account_id.in_(exp_ids)).all()
    total_expenses = sum(line.debit - line.credit for line in total_expense_lines)

    net_profit = total_income - total_expenses

    print(f"\n--- RECONCILIATION RESULTS ---")
    print(f"Database Total Income:   {total_income:,.2f} PKR (Target: 1,879,732.81 PKR)")
    print(f"Database Total Expenses: {total_expenses:,.2f} PKR (Target: 287,961.66 PKR)")
    print(f"Database Net Profit:     {net_profit:,.2f} PKR (Target: 1,591,771.15 PKR)")

    assert Decimal(str(total_income)).quantize(Decimal("0.01")) == Decimal("1879732.81")
    assert Decimal(str(total_expenses)).quantize(Decimal("0.01")) == Decimal("287961.66")
    assert Decimal(str(net_profit)).quantize(Decimal("0.01")) == Decimal("1591771.15")
