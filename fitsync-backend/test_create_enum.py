import requests
import json

def test_create_enum():
    """Test creating a clothing item with exact enum values"""
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
        
        # Test creating a clothing item with exact enum values
        print("\n👕 Testing /api/v1/clothing/create with exact enum values...")
        item_data = {
            "name": "Enum Test Shirt",
            "category": "tops",
            "subcategory": "t_shirts",
            "color": "white",
            "seasons": ["spring", "summer"],
            "occasions": ["casual"]
        }
        
        create_response = requests.post(
            f"{base_url}/api/v1/clothing/create",
            json=item_data,
            headers=headers
        )
        
        print(f"Create status: {create_response.status_code}")
        print(f"Create response: {create_response.text}")
        
        if create_response.status_code == 201:
            print("✅ Success! Now testing the full endpoint...")
            
            # Test the full endpoint
            full_item_data = {
                "name": "Full Test Shirt",
                "category": "tops",
                "subcategory": "t_shirts",
                "color": "blue",
                "color_hex": "#0000FF",
                "brand": "Test Brand",
                "price": 25.0,
                "image_url": "https://example.com/blue-shirt.jpg",
                "seasons": ["spring", "summer"],
                "occasions": ["casual"],
                "style_tags": ["basic", "casual"]
            }
            
            full_response = requests.post(
                f"{base_url}/api/v1/clothing/create",
                json=full_item_data,
                headers=headers
            )
            
            print(f"Full create status: {full_response.status_code}")
            print(f"Full create response: {full_response.text[:200]}...")
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    test_create_enum()
