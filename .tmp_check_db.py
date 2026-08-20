import sqlite3
import sys
p = r"c:\Users\Sadia Ahmad\FuelStationAccounting\fuel_station.db"
try:
    conn = sqlite3.connect(p)
    cur = conn.cursor()
    cur.execute("SELECT name FROM sqlite_master WHERE type='table';")
    tables = cur.fetchall()
    print('OK', tables)
    conn.close()
except Exception as e:
    print('ERR', e)
    sys.exit(1)
