#!/usr/bin/env python3
"""
Test script to verify Flutter app can connect to backend
"""
import requests
import json

BASE_URL = "http://127.0.0.1:8000/api/v1"

def test_flutter_connection():
    """Test that Flutter app can connect to backend"""
    
    print("🧪 Testing Flutter app connection to backend...")
    print("=" * 50)
    
    # Test 1: Login with Flutter test user
    print("1. Testing login with Flutter test user...")
    login_data = {
        "email": "flutter@test.com",
        "password": "Test1234!"
    }
    
    try:
        login_response = requests.post(f"{BASE_URL}/auth/login", json=login_data)
        if login_response.status_code == 200:
            token = login_response.json().get('access_token')
            print("   ✅ Login successful!")
            print(f"   📝 Token: {token[:20]}...")
        else:
            print(f"   ❌ Login failed: {login_response.text}")
            return
    except Exception as e:
        print(f"   ❌ Login error: {e}")
        return
    
    # Test 2: Get wardrobe stats
    print("\n2. Testing wardrobe stats...")
    headers = {"Authorization": f"Bearer {token}"}
    
    try:
        stats_response = requests.get(f"{BASE_URL}/clothing/stats/wardrobe", headers=headers)
        if stats_response.status_code == 200:
            stats = stats_response.json()
            print("   ✅ Wardrobe stats successful!")
            print(f"   📊 Total items: {stats.get('total_items', 0)}")
            print(f"   💰 Total value: ${stats.get('total_value', 0):.2f}")
        else:
            print(f"   ❌ Wardrobe stats failed: {stats_response.text}")
    except Exception as e:
        print(f"   ❌ Wardrobe stats error: {e}")
    
    # Test 3: Get clothing items
    print("\n3. Testing clothing items...")
    
    try:
        items_response = requests.get(f"{BASE_URL}/clothing/items?limit=10&offset=0", headers=headers)
        if items_response.status_code == 200:
            items = items_response.json()
            print("   ✅ Clothing items successful!")
            print(f"   👕 Retrieved {len(items)} items")
            if items:
                print(f"   📝 Sample items:")
                for i, item in enumerate(items[:3]):
                    print(f"      {i+1}. {item.get('name', 'N/A')} ({item.get('category', 'N/A')})")
        else:
            print(f"   ❌ Clothing items failed: {items_response.text}")
    except Exception as e:
        print(f"   ❌ Clothing items error: {e}")
    
    print("\n" + "=" * 50)
    print("🎉 Flutter app connection test completed!")
    print("\n📱 Flutter App Instructions:")
    print("1. Start the Flutter app")
    print("2. Use these credentials to login:")
    print(f"   Email: flutter@test.com")
    print(f"   Password: Test1234!")
    print("3. The app should now load wardrobe data successfully")
    print("4. Navigation between screens should work without errors")

if __name__ == "__main__":
    test_flutter_connection()
