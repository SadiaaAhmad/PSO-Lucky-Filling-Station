from datetime import date
from decimal import Decimal
import pytest
from pydantic import ValidationError

from backend.app.schemas import (
    DailyLogCreate, NozzleReadingItem, FuelPurchaseCreate,
    DailyTankStockCreate, CustomerCreate, CustomerVehicleCreate,
    CreditSaleCreate, CreditRecoveryCreate, ExpenseCreate,
    CardTransactionCreate, MonthlyPnLResponse
)

def test_nozzle_reading_closing_ge_opening():
    # Valid
    item = NozzleReadingItem(unit_id=1, opening_reading=Decimal("100.00"), closing_reading=Decimal("150.00"))
    assert item.closing_reading >= item.opening_reading

    # Invalid: closing < opening
    with pytest.raises(ValidationError):
        NozzleReadingItem(unit_id=1, opening_reading=Decimal("200.00"), closing_reading=Decimal("150.00"))

def test_fuel_purchase_validation():
    # Valid
    fp = FuelPurchaseCreate(
        daily_log_id=1,
        product_id=1,
        tank_id=1,
        purchase_liters=Decimal("5000.00"),
        purchase_rate=Decimal("300.0000"),
        sale_rate=Decimal("306.5000")
    )
    assert fp.purchase_liters == Decimal("5000.00")

    # Invalid: zero or negative liters
    with pytest.raises(ValidationError):
        FuelPurchaseCreate(
            daily_log_id=1,
            product_id=1,
            tank_id=1,
            purchase_liters=Decimal("0.00"),
            purchase_rate=Decimal("300.0000"),
            sale_rate=Decimal("306.5000")
        )

def test_expense_account_code_pattern():
    # Valid 5000 series
    exp = ExpenseCreate(
        daily_log_id=1,
        expense_account_code="5040",
        amount=Decimal("1200.00"),
        description="Station Light Repair"
    )
    assert exp.expense_account_code == "5040"

    # Invalid series (e.g. 4010 Revenue account)
    with pytest.raises(ValidationError):
        ExpenseCreate(
            daily_log_id=1,
            expense_account_code="4010",
            amount=Decimal("1200.00"),
            description="Invalid Expense Code"
        )

def test_card_transaction_type_validation():
    # Valid
    card = CardTransactionCreate(
        daily_log_id=1,
        card_type="BANK_CARD",
        amount=Decimal("5000.00")
    )
    assert card.card_type == "BANK_CARD"

    # Invalid card type
    with pytest.raises(ValidationError):
        CardTransactionCreate(
            daily_log_id=1,
            card_type="INVALID_CARD",
            amount=Decimal("5000.00")
        )

def test_customer_validation():
    # Valid
    cust = CustomerCreate(
        account_no="CUST-100",
        name="Lucky Logistics",
        credit_limit=Decimal("250000.00")
    )
    assert cust.name == "Lucky Logistics"

    # Invalid short account_no
    with pytest.raises(ValidationError):
        CustomerCreate(
            account_no="AB",
            name="Lucky Logistics"
        )
