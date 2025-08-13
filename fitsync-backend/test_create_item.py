import requests
import json

def test_create_clothing_item():
    """Test the new clothing create endpoint"""
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
        
        # Test creating a clothing item
        print("\n👕 Testing /api/v1/clothing/create...")
        item_data = {
            "name": "Test White T-Shirt",
            "category": "tops",
            "subcategory": "t_shirts",
            "color": "white",
            "color_hex": "#FFFFFF",
            "brand": "Test Brand",
            "price": 25.0,
            "image_url": "https://example.com/white-tshirt.jpg",
            "seasons": ["spring", "summer"],
            "occasions": ["casual"],
            "style_tags": ["basic", "casual"]
        }
        
        create_response = requests.post(
            f"{base_url}/api/v1/clothing/create",
            json=item_data,
            headers=headers
        )
        
        print(f"Create status: {create_response.status_code}")
        print(f"Create response: {create_response.text[:200]}...")
        
        if create_response.status_code == 201:
            print("✅ Clothing item created successfully!")
            
            # Now test getting the items to see if it appears
            print("\n📝 Testing /api/v1/clothing/items...")
            items_response = requests.get(
                f"{base_url}/api/v1/clothing/items",
                headers=headers
            )
            print(f"Items status: {items_response.status_code}")
            print(f"Items response: {items_response.text[:200]}...")
            
            # Test wardrobe stats
            print("\n📊 Testing /api/v1/clothing/stats/wardrobe...")
            stats_response = requests.get(
                f"{base_url}/api/v1/clothing/stats/wardrobe",
                headers=headers
            )
            print(f"Stats status: {stats_response.status_code}")
            print(f"Stats response: {stats_response.text[:200]}...")
        else:
            print("❌ Failed to create clothing item")
            
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    test_create_clothing_item()
