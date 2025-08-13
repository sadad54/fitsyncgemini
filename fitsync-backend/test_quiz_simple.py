import requests
import json

def test_quiz_simple():
    """Simple test to check quiz completion endpoint"""
    base_url = "http://127.0.0.1:8000"
    
    # First, let's test if the endpoint exists
    print("🔍 Testing if quiz completion endpoint exists...")
    try:
        response = requests.get(f"{base_url}/docs")
        print(f"API docs status: {response.status_code}")
    except Exception as e:
        print(f"❌ Cannot access API docs: {e}")
        return
    
    # Test with a simple quiz data
    print("\n📝 Testing quiz completion with minimal data...")
    quiz_data = {
        "weekend_outfit": "comfortable jeans",
        "color_palette": "neutral tones",
        "shoe_style": "minimalist sneakers",
        "accessories": "less is more",
        "print_preference": "solid colors"
    }
    
    # Use a fresh token by logging in first
    login_data = {
        "email": "safsha@gmail.com",
        "password": "safsha$ADAD54"
    }
    
    try:
        login_response = requests.post(f"{base_url}/api/v1/auth/login", json=login_data)
        if login_response.status_code == 200:
            token = login_response.json().get('access_token')
            print(f"✅ Got fresh token: {token[:50]}...")
            
            headers = {
                "Content-Type": "application/json",
                "Authorization": f"Bearer {token}"
            }
            
            quiz_response = requests.post(
                f"{base_url}/api/v1/users/quiz-completion",
                json=quiz_data,
                headers=headers,
                timeout=10
            )
            
            print(f"Quiz completion status: {quiz_response.status_code}")
            print(f"Response: {quiz_response.text}")
            
            if quiz_response.status_code == 201:
                print("✅ Quiz completion successful!")
            else:
                print("❌ Quiz completion failed")
        else:
            print(f"❌ Login failed: {login_response.text}")
            
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    test_quiz_simple()
