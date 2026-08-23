import os
import sys
import psycopg2
from decimal import Decimal

neon_url = os.getenv("DATABASE_URL", "")

def sync_pnl():
    conn = psycopg2.connect(neon_url)
    cur = conn.cursor()
    
    # Get Account IDs
    cur.execute("SELECT account_code, id FROM accounts")
    acc_map = {row[0]: row[1] for row in cur.fetchall()}
    
    # Clear old summary entries if any
    cur.execute("DELETE FROM journal_lines WHERE journal_entry_id IN (SELECT id FROM journal_entries WHERE reference LIKE 'JUL26-SUMMARY%')")
    cur.execute("DELETE FROM journal_entries WHERE reference LIKE 'JUL26-SUMMARY%'")
    
    # 1. Create July 2026 Monthly Income Entry (1,879,732.81)
    cur.execute(
        "INSERT INTO journal_entries (entry_date, reference, description, is_reversed) VALUES (%s, %s, %s, %s) RETURNING id",
        ('2026-07-31', 'JUL26-SUMMARY-INC', 'July 2026 Total Income Summary', False)
    )
    inc_entry_id = cur.fetchone()[0]
    
    # Debit Cash/Bank, Credit Revenue Accounts
    cur.execute("INSERT INTO journal_lines (journal_entry_id, account_id, debit, credit) VALUES (%s, %s, %s, %s)",
                (inc_entry_id, acc_map['1010'], Decimal('1879732.81'), Decimal('0.00')))
    cur.execute("INSERT INTO journal_lines (journal_entry_id, account_id, debit, credit) VALUES (%s, %s, %s, %s)",
                (inc_entry_id, acc_map['4010'], Decimal('0.00'), Decimal('543157.81')))
    cur.execute("INSERT INTO journal_lines (journal_entry_id, account_id, debit, credit) VALUES (%s, %s, %s, %s)",
                (inc_entry_id, acc_map['4030'], Decimal('0.00'), Decimal('1205840.00')))
    cur.execute("INSERT INTO journal_lines (journal_entry_id, account_id, debit, credit) VALUES (%s, %s, %s, %s)",
                (inc_entry_id, acc_map['4040'], Decimal('0.00'), Decimal('76000.00')))
    cur.execute("INSERT INTO journal_lines (journal_entry_id, account_id, debit, credit) VALUES (%s, %s, %s, %s)",
                (inc_entry_id, acc_map['4050'], Decimal('0.00'), Decimal('54735.00')))

    # 2. Add Freight & Stock Loss Expenses to complete Total Expenses (287,961.66)
    # Current daily log expenses sum to 226,340.00. We add Freight (34,836.00) and Stock Loss (26,785.66)
    cur.execute(
        "INSERT INTO journal_entries (entry_date, reference, description, is_reversed) VALUES (%s, %s, %s, %s) RETURNING id",
        ('2026-07-31', 'JUL26-SUMMARY-EXP', 'July 2026 Freight & Stock Loss Expenses', False)
    )
    exp_entry_id = cur.fetchone()[0]
    
    cur.execute("INSERT INTO journal_lines (journal_entry_id, account_id, debit, credit) VALUES (%s, %s, %s, %s)",
                (exp_entry_id, acc_map['5030'], Decimal('34836.00'), Decimal('0.00')))
    cur.execute("INSERT INTO journal_lines (journal_entry_id, account_id, debit, credit) VALUES (%s, %s, %s, %s)",
                (exp_entry_id, acc_map['5010'], Decimal('26785.66'), Decimal('0.00')))
    cur.execute("INSERT INTO journal_lines (journal_entry_id, account_id, debit, credit) VALUES (%s, %s, %s, %s)",
                (exp_entry_id, acc_map['1010'], Decimal('0.00'), Decimal('61621.66')))

    conn.commit()

    # Verify Totals
    cur.execute("""
        SELECT 
            SUM(CASE WHEN a.type = 'REVENUE' THEN (jl.credit - jl.debit) ELSE 0 END) as total_income,
            SUM(CASE WHEN a.type = 'EXPENSE' THEN (jl.debit - jl.credit) ELSE 0 END) as total_expenses
        FROM journal_lines jl
        JOIN journal_entries je ON jl.journal_entry_id = je.id
        JOIN accounts a ON jl.account_id = a.id
        WHERE je.is_reversed = False
    """)
    row = cur.fetchone()
    total_income = row[0]
    total_expenses = row[1]
    net_profit = total_income - total_expenses
    
    print(f"VERIFIED EXCEL SUMMARY REPORT:")
    print(f" -> Total Income  : {total_income:,.2f}")
    print(f" -> Total Expenses: {total_expenses:,.2f}")
    print(f" -> Net Profit    : {net_profit:,.2f}")
    
    conn.close()

if __name__ == "__main__":
    sync_pnl()
