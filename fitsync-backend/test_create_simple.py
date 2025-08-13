import requests
import json

def test_create_simple():
    """Test creating a clothing item with minimal required fields"""
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
        
        # Test creating a clothing item with minimal fields
        print("\n👕 Testing /api/v1/clothing/create with minimal fields...")
        item_data = {
            "name": "Simple Test Shirt",
            "category": "tops"
        }
        
        create_response = requests.post(
            f"{base_url}/api/v1/clothing/create",
            json=item_data,
            headers=headers
        )
        
        print(f"Create status: {create_response.status_code}")
        print(f"Create response: {create_response.text}")
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    test_create_simple()
