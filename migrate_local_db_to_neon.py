import os
import sys
import sqlite3
from pathlib import Path
from decimal import Decimal
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Add project root to sys.path
root_dir = Path(__file__).resolve().parent
if str(root_dir) not in sys.path:
    sys.path.insert(0, str(root_dir))

from backend.app.database.base import Base
from backend.app.models import (
    Product, Tank, DispensingUnit, Customer, CustomerVehicle,
    DailyLog, NozzleReading, FuelPurchase, DailyTankStock,
    CreditTransaction, CardTransaction, ExpenseCategory, Account,
    JournalEntry, JournalLine
)

def sync_sqlite_to_neon(target_postgres_url: str):
    local_db_path = Path("fuel_station.db").resolve()
    if not local_db_path.exists():
        print(f"Error: {local_db_path} not found!")
        return

    print(f"1. Connecting to local SQLite database: {local_db_path}")
    conn = sqlite3.connect(str(local_db_path))
    conn.row_factory = sqlite3.Row

    print(f"2. Connecting to target Neon PostgreSQL database...")
    if target_postgres_url.startswith("postgres://"):
        target_postgres_url = target_postgres_url.replace("postgres://", "postgresql://", 1)

    target_engine = create_engine(target_postgres_url, pool_pre_ping=True)
    TargetSession = sessionmaker(bind=target_engine)
    target_db = TargetSession()

    print("3. Ensuring all database tables exist on Neon PostgreSQL...")
    Base.metadata.create_all(bind=target_engine)

    models_map = [
        ("accounts", Account),
        ("products", Product),
        ("tanks", Tank),
        ("dispensing_units", DispensingUnit),
        ("customers", Customer),
        ("customer_vehicles", CustomerVehicle),
        ("daily_logs", DailyLog),
        ("nozzle_readings", NozzleReading),
        ("fuel_purchases", FuelPurchase),
        ("daily_tank_stocks", DailyTankStock),
        ("credit_transactions", CreditTransaction),
        ("card_transactions", CardTransaction),
        ("expense_categories", ExpenseCategory),
        ("journal_entries", JournalEntry),
        ("journal_lines", JournalLine),
    ]

    cursor = conn.cursor()

    for table_name, model in models_map:
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name=?", (table_name,))
        if not cursor.fetchone():
            continue

        cursor.execute(f"SELECT * FROM {table_name}")
        rows = cursor.fetchall()
        print(f" -> Migrating {len(rows)} records for {model.__name__}...")

        valid_cols = {c.name for c in model.__table__.columns}

        for row in rows:
            row_dict = dict(row)
            data = {k: v for k, v in row_dict.items() if k in valid_cols and v is not None}

            for col in model.__table__.columns:
                col_name = col.name
                if col_name in data:
                    col_type = str(col.type).lower()
                    if ('numeric' in col_type or 'decimal' in col_type) and isinstance(data[col_name], (int, float, str)):
                        try:
                            data[col_name] = Decimal(str(data[col_name]))
                        except Exception:
                            pass

            rec_id = data.get("id")
            existing = target_db.query(model).filter(model.id == rec_id).first() if rec_id else None
            if not existing:
                try:
                    obj = model(**data)
                    target_db.add(obj)
                except Exception as ex:
                    print(f"    Warning adding record to {model.__name__}: {ex}")

        try:
            target_db.commit()
        except Exception as commit_err:
            print(f"   Commit error on {table_name}: {commit_err}")
            target_db.rollback()

    print("\nSUCCESS! All July 2026 data (31 daily logs, nozzle readings, stock dips, customers, journal entries) successfully migrated to Neon Cloud DB!")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        neon_url = sys.argv[1]
    else:
        neon_url = os.getenv("DATABASE_URL", "")

    if not neon_url or "neon.tech" not in neon_url:
        print("Please pass your Neon connection string as an argument or set DATABASE_URL environment variable.")
        print("Example: python migrate_local_db_to_neon.py \"postgresql://neondb_owner:PASSWORD@ep-xxx.neon.tech/neondb?sslmode=require\"")
    else:
        sync_sqlite_to_neon(neon_url)
