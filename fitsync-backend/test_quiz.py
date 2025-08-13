import requests
import json

def test_quiz_completion():
    """Test quiz completion endpoint"""
    base_url = "http://127.0.0.1:8000"
    
    # First, login to get a token
    print("🔐 Testing login...")
    login_data = {
        "email": "safsha@gmail.com",
        "password": "password123"  # Use the actual password
    }
    
    login_response = requests.post(f"{base_url}/api/v1/auth/login", json=login_data)
    print(f"Login status: {login_response.status_code}")
    
    if login_response.status_code != 200:
        print(f"❌ Login failed: {login_response.text}")
        return
    
    login_result = login_response.json()
    access_token = login_result.get('access_token')
    
    if not access_token:
        print("❌ No access token received")
        return
    
    print(f"✅ Login successful, token: {access_token[:50]}...")
    
    # Now test quiz completion
    print("\n📝 Testing quiz completion...")
    quiz_data = {
        "weekend_outfit": "Tailored pants and a crisp button-down",
        "color_palette": "Bright and bold hues (red, cobalt blue, hot pink)",
        "shoe_style": "Sleek, minimalist sneakers",
        "accessories": "Bold, architectural jewelry",
        "print_preference": "Geometric or abstract"
    }
    
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {access_token}"
    }
    
    quiz_response = requests.post(
        f"{base_url}/api/v1/users/quiz-completion",
        json=quiz_data,
        headers=headers
    )
    
    print(f"Quiz completion status: {quiz_response.status_code}")
    print(f"Response: {quiz_response.text}")
    
    if quiz_response.status_code == 201:
        print("✅ Quiz completion successful!")
    else:
        print("❌ Quiz completion failed")

if __name__ == "__main__":
    test_quiz_completion()
