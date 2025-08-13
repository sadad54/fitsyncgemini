import bcrypt
import sqlite3

def test_password():
    """Test different passwords for the user"""
    conn = sqlite3.connect('fitsync.db')
    cursor = conn.cursor()
    
    cursor.execute('SELECT hashed_password FROM users WHERE email = "safsha@gmail.com"')
    row = cursor.fetchone()
    
    if not row:
        print("❌ User not found")
        return
    
    hashed = row[0]
    print(f"Found hashed password: {hashed[:50]}...")
    
    # Test different passwords
    test_passwords = [
        'password123',
        'safsha$ADAD54',
        'safsha@gmail.com',
        'safsha',
        '123456',
        'password',
        'admin'
    ]
    
    for password in test_passwords:
        try:
            is_valid = bcrypt.checkpw(password.encode('utf-8'), hashed.encode('utf-8'))
            print(f"Password '{password}' is valid: {is_valid}")
            if is_valid:
                print(f"✅ Found correct password: {password}")
                break
        except Exception as e:
            print(f"Error testing password '{password}': {e}")
    
    conn.close()

if __name__ == "__main__":
    test_password()
