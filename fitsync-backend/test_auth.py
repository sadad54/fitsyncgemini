import requests
import json

def test_auth_and_quiz():
    """Test authentication and quiz completion"""
    base_url = "http://127.0.0.1:8000/api/v1"
    
    # Test login
    print("🔐 Testing login...")
    login_data = {
        "email": "safsha@gmail.com",
        "password": "testpass123"  # You might need to change this password
    }
    
    try:
        login_response = requests.post(f"{base_url}/auth/login", json=login_data)
        print(f"Login status: {login_response.status_code}")
        
        if login_response.status_code == 200:
            login_result = login_response.json()
            token = login_result.get('access_token')
            print(f"✅ Login successful! Token: {token[:20]}...")
            
            # Test quiz completion with token
            print("\n📝 Testing quiz completion...")
            headers = {
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json"
            }
            
            quiz_data = {
                "weekend_outfit": "flowy dress",
                "color_palette": "pastels and soft",
                "shoe_style": "strappy sandals",
                "accessories": "layered and eclectic",
                "print_preference": "floral or paisley"
            }
            
            quiz_response = requests.post(f"{base_url}/users/quiz-completion", 
                                        json=quiz_data, 
                                        headers=headers)
            
            print(f"Quiz completion status: {quiz_response.status_code}")
            print(f"Quiz response: {quiz_response.text}")
            
            if quiz_response.status_code == 201:
                print("✅ Quiz completion successful!")
            else:
                print("❌ Quiz completion failed!")
                
        else:
            print(f"❌ Login failed: {login_response.text}")
            
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    test_auth_and_quiz()
