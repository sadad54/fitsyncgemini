import sqlite3
import bcrypt
from datetime import datetime

def create_test_user():
    """Create a test user with known credentials"""
    conn = sqlite3.connect('fitsync.db')
    cursor = conn.cursor()
    
    try:
        # Check if test user already exists
        cursor.execute("SELECT id FROM users WHERE email = 'test@example.com'")
        existing_user = cursor.fetchone()
        
        if existing_user:
            print("✅ Test user already exists!")
            return
        
        # Create test user
        email = "test@example.com"
        username = "testuser"
        password = "testpass123"
        first_name = "Test"
        last_name = "User"
        
        # Hash the password
        hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        
        # Insert user
        cursor.execute("""
            INSERT INTO users (email, username, first_name, last_name, hashed_password, is_active, is_verified, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, (email, username, first_name, last_name, hashed_password, True, True, datetime.now()))
        
        conn.commit()
        print("✅ Test user created successfully!")
        print(f"Email: {email}")
        print(f"Password: {password}")
        
    except Exception as e:
        print(f"❌ Error creating test user: {e}")
        conn.rollback()
    finally:
        conn.close()

if __name__ == "__main__":
    create_test_user()
