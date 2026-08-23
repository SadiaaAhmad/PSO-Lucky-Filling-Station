import os
import sys
import psycopg2

neon_url = os.getenv("DATABASE_URL", "")

def fix_sequences():
    print("Fixing PostgreSQL auto-increment sequences...")
    conn = psycopg2.connect(neon_url)
    cur = conn.cursor()
    
    tables = [
        'journal_entries', 'journal_lines', 'daily_logs', 'nozzle_readings', 
        'daily_tank_stocks', 'customers', 'customer_vehicles', 'card_transactions', 
        'credit_transactions', 'fuel_purchases', 'accounts', 'products', 'tanks', 'dispensing_units'
    ]
    
    for t in tables:
        try:
            sql = f"SELECT setval(pg_get_serial_sequence('{t}', 'id'), COALESCE((SELECT MAX(id) FROM {t}), 1))"
            cur.execute(sql)
            print(f" -> Reset sequence for table: {t}")
        except Exception as e:
            print(f" -> Warning for {t}: {e}")
            conn.rollback()
            
    conn.commit()
    conn.close()
    print("All PostgreSQL primary key sequences successfully reset!")

if __name__ == "__main__":
    fix_sequences()
