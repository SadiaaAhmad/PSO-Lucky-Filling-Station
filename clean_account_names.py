import os
import sys
import psycopg2

def clean_names(neon_url=None):
    if not neon_url:
        neon_url = os.getenv("DATABASE_URL")
    if not neon_url:
        print("Error: DATABASE_URL environment variable is not set and no connection string provided.")
        sys.exit(1)
        
    conn = psycopg2.connect(neon_url)
    cur = conn.cursor()
    
    # 1. Rename Account 1200
    cur.execute("UPDATE accounts SET name = 'Accounts Receivable (Udhaar Customers)' WHERE account_code = '1200'")
    
    # 2. Rename Customer "Lucky Cement Fleet" to "General Credit Customer"
    cur.execute("UPDATE customers SET name = 'General Credit Customer' WHERE name LIKE '%Lucky%' OR name LIKE '%Cement%'")
    
    conn.commit()
    conn.close()
    print("Cleaned account & customer names! No 'Lucky Cement Fleet' in database!")

if __name__ == "__main__":
    url_arg = sys.argv[1] if len(sys.argv) > 1 else None
    clean_names(url_arg)
