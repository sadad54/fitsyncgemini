import requests
import json

def test_simple_endpoint():
    """Test the simple test-create endpoint"""
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
        
        # Test the simple endpoint
        print("\n🧪 Testing /api/v1/clothing/test-create...")
        
        create_response = requests.post(
            f"{base_url}/api/v1/clothing/test-create",
            headers=headers
        )
        
        print(f"Create status: {create_response.status_code}")
        print(f"Create response: {create_response.text}")
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    test_simple_endpoint()
