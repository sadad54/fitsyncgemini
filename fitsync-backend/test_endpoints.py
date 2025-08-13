import requests
import json

def test_failing_endpoints():
    """Test the endpoints that are failing in the Flutter app"""
    base_url = "http://127.0.0.1:8000"
    
    # Login to get a token
    login_data = {
        "email": "safsha@gmail.com",
        "password": "safsha$ADAD54"
    }
    
    try:
        login_response = requests.post(f"{base_url}/api/v1/auth/login", json=login_data)
        if login_response.status_code != 200:
            print(f"❌ Login failed: {login_response.text}")
            return
        
        token = login_response.json().get('access_token')
        print(f"✅ Got token: {token[:50]}...")
        
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {token}"
        }
        
        # Test 1: Get clothing items
        print("\n📝 Testing /api/v1/clothing/items...")
        items_response = requests.get(
            f"{base_url}/api/v1/clothing/items?limit=10&offset=0",
            headers=headers
        )
        print(f"Items status: {items_response.status_code}")
        print(f"Items response: {items_response.text[:200]}...")
        
        # Test 2: Get wardrobe stats
        print("\n📊 Testing /api/v1/clothing/stats/wardrobe...")
        stats_response = requests.get(
            f"{base_url}/api/v1/clothing/stats/wardrobe",
            headers=headers
        )
        print(f"Stats status: {stats_response.status_code}")
        print(f"Stats response: {stats_response.text[:200]}...")
        
        # Test 3: Get style preferences
        print("\n🎨 Testing /api/v1/users/style-preferences...")
        prefs_response = requests.get(
            f"{base_url}/api/v1/users/style-preferences",
            headers=headers
        )
        print(f"Preferences status: {prefs_response.status_code}")
        print(f"Preferences response: {prefs_response.text[:200]}...")
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    test_failing_endpoints()
