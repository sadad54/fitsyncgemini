import sqlite3
import bcrypt

def test_password():
    """Test password verification"""
    conn = sqlite3.connect('fitsync.db')
    cursor = conn.cursor()
    
    try:
        # Get the test user's hashed password
        cursor.execute("SELECT hashed_password FROM users WHERE email = 'test@example.com'")
        result = cursor.fetchone()
        
        if not result:
            print("❌ Test user not found!")
            return
        
        hashed_password = result[0]
        print(f"Hashed password: {hashed_password}")
        
        # Test password verification
        test_password = "testpass123"
        is_valid = bcrypt.checkpw(test_password.encode('utf-8'), hashed_password.encode('utf-8'))
        
        print(f"Password '{test_password}' is valid: {is_valid}")
        
        # Test with wrong password
        wrong_password = "wrongpass"
        is_valid_wrong = bcrypt.checkpw(wrong_password.encode('utf-8'), hashed_password.encode('utf-8'))
        print(f"Password '{wrong_password}' is valid: {is_valid_wrong}")
        
    except Exception as e:
        print(f"❌ Error: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    test_password()
