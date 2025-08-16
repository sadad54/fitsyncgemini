#!/usr/bin/env python3
"""
Test the endpoints after fixing enum values
"""
import requests
import json

BASE_URL = "http://127.0.0.1:8000/api/v1"

def test_fixed_endpoints():
    """Test the endpoints after fixing enum values"""
    
    # First, login to get token
    print("🔐 Logging in to get token...")
    login_data = {
        "email": "flutter@test.com",
        "password": "Test1234!"
    }
    
    try:
        login_response = requests.post(f"{BASE_URL}/auth/login", json=login_data)
        if login_response.status_code != 200:
            print(f"❌ Login failed: {login_response.text}")
            return
            
        login_result = login_response.json()
        token = login_result.get('access_token')
        print(f"✅ Login successful! Token: {token[:20]}...")
        
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }
        
        # Test wardrobe stats
        print("\n📊 Testing wardrobe stats...")
        stats_response = requests.get(f"{BASE_URL}/clothing/stats/wardrobe", headers=headers)
        print(f"Stats status: {stats_response.status_code}")
        if stats_response.status_code == 200:
            stats = stats_response.json()
            print(f"✅ Wardrobe stats successful!")
            print(f"  - Total items: {stats.get('total_items', 0)}")
            print(f"  - Total value: ${stats.get('total_value', 0):.2f}")
            print(f"  - Categories: {list(stats.get('items_by_category', {}).keys())}")
        else:
            print(f"❌ Wardrobe stats failed: {stats_response.text}")
        
        # Test clothing items
        print("\n👕 Testing clothing items...")
        items_response = requests.get(f"{BASE_URL}/clothing/items?limit=5&offset=0", headers=headers)
        print(f"Items status: {items_response.status_code}")
        if items_response.status_code == 200:
            items = items_response.json()
            print(f"✅ Clothing items successful!")
            print(f"  - Retrieved {len(items)} items")
            if items:
                print(f"  - Sample item: {items[0].get('name', 'N/A')} ({items[0].get('category', 'N/A')})")
        else:
            print(f"❌ Clothing items failed: {items_response.text}")
            
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    test_fixed_endpoints()
