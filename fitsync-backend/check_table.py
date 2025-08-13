import sqlite3

def check_table():
    conn = sqlite3.connect('fitsync.db')
    cursor = conn.cursor()
    
    # Check if clothing_items table exists
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='clothing_items'")
    result = cursor.fetchone()
    print('Clothing items table exists:', result is not None)
    
    if result:
        # Check table structure
        cursor.execute("PRAGMA table_info(clothing_items)")
        columns = cursor.fetchall()
        print('Table columns:')
        for col in columns:
            print(f'  {col[1]} ({col[2]})')
    
    conn.close()

if __name__ == "__main__":
    check_table()
