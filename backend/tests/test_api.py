from datetime import date
from decimal import Decimal
import pytest
from fastapi.testclient import TestClient

from backend.app.main import app
from backend.app.database.session import SessionLocal, engine
from backend.app.database.base import Base
from backend.seed.seed_july_2026 import run_seed

client = TestClient(app)

@pytest.fixture(scope="module", autouse=True)
def setup_test_db():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    run_seed()
    yield
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    run_seed()

def test_health_endpoint():
    response = client.get("/health")
    assert response.status_code == 200
    json_data = response.json()
    assert json_data["status"] == "healthy"
    assert "Fuel Station Accounting System" in json_data["project"]

def test_daily_logs_api():
    payload = {"log_date": "2026-09-10", "notes": "API Test Log"}
    res = client.post("/api/v1/daily-logs/", json=payload)
    assert res.status_code == 201
    data = res.json()
    log_id = data["id"]
    assert data["status"] == "DRAFT"

    res_get = client.get(f"/api/v1/daily-logs/{log_id}")
    assert res_get.status_code == 200

    res_close = client.post(f"/api/v1/daily-logs/{log_id}/close")
    assert res_close.status_code == 200
    assert res_close.json()["status"] == "CLOSED"

def test_fuel_nozzle_readings_api():
    log_res = client.post("/api/v1/daily-logs/", json={"log_date": "2026-09-11"})
    log_id = log_res.json()["id"]

    payload = {
        "daily_log_id": log_id,
        "readings": [
            {"unit_id": 1, "opening_reading": "500.00", "closing_reading": "750.00"}
        ]
    }
    res = client.post("/api/v1/fuel/nozzle-readings", json=payload)
    assert res.status_code == 201
    items = res.json()
    assert len(items) == 1
    assert float(items[0]["gross_sale_liters"]) == 250.0

def test_fuel_purchase_api():
    log_res = client.post("/api/v1/daily-logs/", json={"log_date": "2026-09-12"})
    log_id = log_res.json()["id"]

    payload = {
        "daily_log_id": log_id,
        "product_id": 1,
        "tank_id": 1,
        "invoice_no": "INV-API-99",
        "purchase_liters": "4000.00",
        "purchase_rate": "300.00",
        "sale_rate": "306.50",
        "rate_diff_per_ltr": "1.50"
    }
    res = client.post("/api/v1/fuel/purchases", json=payload)
    assert res.status_code == 201
    assert float(res.json()["purchase_liters"]) == 4000.0

def test_stock_tank_api():
    log_res = client.post("/api/v1/daily-logs/", json={"log_date": "2026-09-13"})
    log_id = log_res.json()["id"]

    payload = {
        "daily_log_id": log_id,
        "tank_id": 1,
        "product_id": 1,
        "opening_dip_liters": "8000.00",
        "stock_in_purchase_liters": "4000.00",
        "testing_loss_liters": "10.00",
        "net_sales_liters": "1000.00",
        "actual_dip_liters": "10990.00",
        "purchase_rate": "300.00"
    }
    res = client.post("/api/v1/stock/tank-stock", json=payload)
    assert res.status_code == 201
    data = res.json()
    assert float(data["expected_closing_liters"]) == 10990.0
    assert float(data["stock_gain_loss_liters"]) == 0.0

def test_customer_and_vehicle_api():
    cust_res = client.post("/api/v1/customers/", json={
        "account_no": "API-CUST-001",
        "name": "API Transport Corp",
        "credit_limit": "200000.00"
    })
    assert cust_res.status_code == 201
    cust_id = cust_res.json()["id"]

    veh_res = client.post(f"/api/v1/customers/{cust_id}/vehicles", json={
        "vehicle_no": "API-V-1100",
        "driver_name": "Hamza"
    })
    assert veh_res.status_code == 201

    bal_res = client.get(f"/api/v1/customers/{cust_id}/balance")
    assert bal_res.status_code == 200
    assert float(bal_res.json()["current_balance"]) == 0.0

def test_credit_sale_and_recovery_api():
    log_res = client.post("/api/v1/daily-logs/", json={"log_date": "2026-09-14"})
    log_id = log_res.json()["id"]

    cust_res = client.post("/api/v1/customers/", json={
        "account_no": "API-CREDIT-99",
        "name": "Rapid Fleet",
        "credit_limit": "100000.00"
    })
    cust_id = cust_res.json()["id"]

    sale_res = client.post("/api/v1/credit/sale", json={
        "daily_log_id": log_id,
        "customer_id": cust_id,
        "amount": "25000.00",
        "reference": "API-REF-01"
    })
    assert sale_res.status_code == 201

    bal_after_sale = client.get(f"/api/v1/customers/{cust_id}/balance").json()
    assert float(bal_after_sale["current_balance"]) == 25000.0

    rec_res = client.post("/api/v1/credit/recovery", json={
        "daily_log_id": log_id,
        "customer_id": cust_id,
        "amount": "10000.00",
        "payment_account_code": "1010"
    })
    assert rec_res.status_code == 201

    bal_after_rec = client.get(f"/api/v1/customers/{cust_id}/balance").json()
    assert float(bal_after_rec["current_balance"]) == 15000.0

def test_finance_api():
    log_res = client.post("/api/v1/daily-logs/", json={"log_date": "2026-09-15"})
    log_id = log_res.json()["id"]

    exp_res = client.post("/api/v1/finance/expense", json={
        "daily_log_id": log_id,
        "expense_account_code": "5040",
        "amount": "1500.00",
        "description": "Generator Diesel Expense"
    })
    assert exp_res.status_code == 201

    card_res = client.post("/api/v1/finance/card-sale", json={
        "daily_log_id": log_id,
        "card_type": "BANK_CARD",
        "liters": "30.00",
        "amount": "9000.00",
        "bank_charges": "180.00"
    })
    assert card_res.status_code == 201

    draw_res = client.post("/api/v1/finance/owner-draw", json={
        "daily_log_id": log_id,
        "amount": "5000.00",
        "description": "Proprietor Home Draw"
    })
    assert draw_res.status_code == 201

def test_reports_api():
    pnl_res = client.get("/api/v1/reports/monthly/2026/7")
    assert pnl_res.status_code == 200
    data = pnl_res.json()
    assert float(data["net_profit"]) == 1591771.15

    daily_res = client.get("/api/v1/reports/daily/2026-07-01")
    assert daily_res.status_code == 200
    assert daily_res.json()["status"] == "CLOSED"
