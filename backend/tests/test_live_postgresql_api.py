import json
from decimal import Decimal
import pytest
from fastapi.testclient import TestClient

from backend.app.main import app
from backend.app.database.session import SessionLocal, engine
from backend.app.database.base import Base
from backend.seed.seed_july_2026 import run_seed

client = TestClient(app)

@pytest.fixture(scope="module", autouse=True)
def setup_postgres_db():
    Base.metadata.create_all(bind=engine)
    run_seed()
    yield

def test_live_postgres_health():
    res = client.get("/health")
    assert res.status_code == 200
    assert res.json()["status"] == "healthy"

def test_live_postgres_daily_logs():
    res = client.get("/api/v1/daily-logs/?limit=5")
    assert res.status_code == 200
    logs = res.json()
    assert len(logs) > 0

def test_live_postgres_single_log():
    res = client.get("/api/v1/daily-logs/1")
    assert res.status_code == 200
    assert res.json()["id"] == 1

def test_live_postgres_customer_balance():
    c_res = client.post("/api/v1/customers/", json={"account_no": "TEST-CUST-LIVE", "name": "Live Test Customer", "credit_limit": 50000})
    assert c_res.status_code == 201
    cust_id = c_res.json()["id"]

    res = client.get(f"/api/v1/customers/{cust_id}/balance")
    assert res.status_code == 200
    data = res.json()
    assert data["customer_id"] == cust_id

def test_live_postgres_daily_report():
    res = client.get("/api/v1/reports/daily/2026-07-01")
    assert res.status_code == 200
    assert res.json()["status"] == "CLOSED"

def test_live_postgres_monthly_pnl_reconciliation():
    res = client.get("/api/v1/reports/monthly/2026/7")
    assert res.status_code == 200
    data = res.json()
    
    total_income = Decimal(str(data["total_income"]))
    total_expenses = Decimal(str(data["total_expenses"]))
    net_profit = Decimal(str(data["net_profit"]))

    assert total_income == Decimal("1879732.81")
    assert total_expenses == Decimal("287961.66")
    assert net_profit == Decimal("1591771.15")
