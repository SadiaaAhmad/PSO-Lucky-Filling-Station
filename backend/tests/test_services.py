from datetime import date
from decimal import Decimal
import pytest
from sqlalchemy.orm import Session

from backend.app.database.session import SessionLocal, engine
from backend.app.database.base import Base
from backend.app.services.daily_log_service import DailyLogService
from backend.app.services.fuel_service import FuelService
from backend.app.services.stock_service import StockService
from backend.app.services.customer_service import CustomerService
from backend.app.services.credit_service import CreditService
from backend.app.services.finance_service import FinanceService
from backend.app.services.report_service import ReportService
from backend.seed.seed_july_2026 import run_seed

@pytest.fixture(scope="module")
def db():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    run_seed()
    db_session = SessionLocal()
    try:
        yield db_session
    finally:
        db_session.close()
        Base.metadata.drop_all(bind=engine)
        Base.metadata.create_all(bind=engine)
        run_seed()

def test_daily_log_service(db: Session):
    test_date = date(2026, 9, 1)
    log = DailyLogService.create_daily_log(db, log_date=test_date, notes="September Test Log")
    assert log.id is not None
    assert log.status == "DRAFT"

    # Duplicate test
    with pytest.raises(ValueError):
        DailyLogService.create_daily_log(db, log_date=test_date)

    # Close test
    closed_log = DailyLogService.close_daily_log(db, log.id)
    assert closed_log.status == "CLOSED"

def test_fuel_service_nozzle_readings_validation(db: Session):
    test_date = date(2026, 9, 2)
    log = DailyLogService.create_daily_log(db, log_date=test_date)

    # Valid readings
    readings = FuelService.record_nozzle_readings(
        db,
        daily_log_id=log.id,
        readings_data=[
            {"unit_id": 1, "opening_reading": Decimal("100.00"), "closing_reading": Decimal("250.00")}
        ]
    )
    assert len(readings) == 1
    assert readings[0].gross_sale_liters == Decimal("150.00")

    # Invalid reading: closing < opening
    with pytest.raises(ValueError):
        FuelService.record_nozzle_readings(
            db,
            daily_log_id=log.id,
            readings_data=[
                {"unit_id": 1, "opening_reading": Decimal("300.00"), "closing_reading": Decimal("200.00")}
            ]
        )

def test_fuel_service_record_purchase(db: Session):
    test_date = date(2026, 9, 3)
    log = DailyLogService.create_daily_log(db, log_date=test_date)

    purchase = FuelService.record_fuel_purchase(
        db,
        daily_log_id=log.id,
        product_id=1, # HSD
        tank_id=1,
        purchase_liters=Decimal("5000.00"),
        purchase_rate=Decimal("300.0000"),
        sale_rate=Decimal("306.5000"),
        invoice_no="INV-8899"
    )
    assert purchase.id is not None
    assert purchase.purchase_liters == Decimal("5000.00")

def test_stock_service_formulas_and_journal(db: Session):
    test_date = date(2026, 9, 4)
    log = DailyLogService.create_daily_log(db, log_date=test_date)

    stock = StockService.record_daily_tank_stock(
        db,
        daily_log_id=log.id,
        tank_id=1,
        product_id=1,
        opening_dip_liters=Decimal("10000.00"),
        stock_in_purchase_liters=Decimal("5000.00"),
        testing_loss_liters=Decimal("20.00"),
        net_sales_liters=Decimal("2000.00"),
        actual_dip_liters=Decimal("13000.00"),
        purchase_rate=Decimal("300.0000")
    )

    # Expected: 10000 + 5000 - 2000 - 20 = 12980
    assert stock.expected_closing_liters == Decimal("12980.00")
    # Gain: 13000 - 12980 = +20 Liters
    assert stock.stock_gain_loss_liters == Decimal("20.00")

def test_customer_and_vehicle_service(db: Session):
    cust = CustomerService.create_customer(
        db,
        account_no="CUST-SERVICE-01",
        name="Service Test Logistics",
        credit_limit=Decimal("100000.00")
    )
    assert cust.id is not None

    veh = CustomerService.add_customer_vehicle(
        db,
        customer_id=cust.id,
        vehicle_no="KHI-4455",
        driver_name="Zubair"
    )
    assert veh.id is not None

    balance = CustomerService.get_customer_balance(db, cust.id)
    assert balance["current_balance"] == Decimal("0.00")

def test_credit_service_and_journal(db: Session):
    test_date = date(2026, 9, 5)
    log = DailyLogService.create_daily_log(db, log_date=test_date)

    cust = CustomerService.create_customer(
        db,
        account_no="CUST-CREDIT-01",
        name="Express Transport",
        credit_limit=Decimal("50000.00")
    )

    sale = CreditService.record_credit_sale(
        db,
        daily_log_id=log.id,
        customer_id=cust.id,
        amount=Decimal("15000.00"),
        reference="REF-CREDIT-1"
    )
    assert sale.id is not None

    bal = CustomerService.get_customer_balance(db, cust.id)
    assert bal["current_balance"] == Decimal("15000.00")

    recovery = CreditService.record_credit_recovery(
        db,
        daily_log_id=log.id,
        customer_id=cust.id,
        amount=Decimal("5000.00"),
        reference="REC-PAY-1"
    )
    assert recovery.id is not None

    bal_after = CustomerService.get_customer_balance(db, cust.id)
    assert bal_after["current_balance"] == Decimal("10000.00")

def test_finance_service(db: Session):
    test_date = date(2026, 9, 6)
    log = DailyLogService.create_daily_log(db, log_date=test_date)

    # Operating Expense
    journal = FinanceService.record_expense(
        db,
        daily_log_id=log.id,
        expense_account_code="5040", # Pump Operating Expense
        amount=Decimal("2500.00"),
        description="Electricity Bill Partial Payment"
    )
    assert journal.id is not None

    # Card Sale
    card_tx = FinanceService.record_card_sale(
        db,
        daily_log_id=log.id,
        card_type="BANK_CARD",
        liters=Decimal("50.00"),
        amount=Decimal("15000.00"),
        bank_charges=Decimal("300.00")
    )
    assert card_tx.id is not None

def test_report_service(db: Session):
    pnl = ReportService.generate_monthly_profit_loss(db, year=2026, month=7)
    assert pnl["year"] == 2026
    assert pnl["month"] == 7
    assert pnl["total_income"] == 1879732.81
    assert pnl["total_expenses"] == 287961.66
    assert pnl["net_profit"] == 1591771.15
