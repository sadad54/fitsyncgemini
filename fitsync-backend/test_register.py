#!/usr/bin/env python3
"""
Test script to reproduce the 500 Internal Server Error on duplicate registration
"""
import requests
import json

BASE_URL = "http://127.0.0.1:8000/api/v1"

def test_duplicate_registration():
    """Test registering the same user twice to trigger the 500 error"""
    
    # Test data
    user_data = {
        "email": "test@example.com",
        "password": "Test1234!",
        "confirm_password": "Test1234!",
        "username": "testuser",
        "first_name": "Test",
        "last_name": "User"
    }
    
    print("Testing duplicate registration...")
    print(f"Base URL: {BASE_URL}")
    print(f"User data: {json.dumps(user_data, indent=2)}")
    print("-" * 50)
    
    # First registration (should succeed)
    print("1. First registration attempt:")
    try:
        response1 = requests.post(
            f"{BASE_URL}/auth/register",
            json=user_data,
            headers={"Content-Type": "application/json"}
        )
        print(f"Status: {response1.status_code}")
        print(f"Response: {response1.text}")
        print()
    except requests.exceptions.ConnectionError:
        print("❌ Connection failed - make sure the server is running on port 8000")
        return
    except Exception as e:
        print(f"❌ Error: {e}")
        return
    
    # Second registration (should fail with 500)
    print("2. Second registration attempt (duplicate):")
    try:
        response2 = requests.post(
            f"{BASE_URL}/auth/register",
            json=user_data,
            headers={"Content-Type": "application/json"}
        )
        print(f"Status: {response2.status_code}")
        print(f"Response: {response2.text}")
        print()
        
        if response2.status_code == 500:
            print("❌ 500 Internal Server Error detected - this is the bug we need to fix!")
        elif response2.status_code == 409:
            print("✅ 409 Conflict - this is the correct behavior!")
        else:
            print(f"⚠️  Unexpected status code: {response2.status_code}")
            
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    test_duplicate_registration()
