import requests
import json

def test_quiz_completion_direct():
    """Test quiz completion endpoint with the exact token from Flutter app"""
    base_url = "http://127.0.0.1:8000"
    
    # Use the exact token from the Flutter app logs
    access_token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzU1MDUwMzE4LCJpYXQiOjE3NTUwNDY3MTgsInR5cGUiOiJhY2Nlc3MiLCJqdGkiOiJsUnh0U3dVeklOdFJNcFU1TnJfSGRKVjJtMGtQRWRJNGJSY3Rrb0xyS1dRIn0.nN7l2OuZZEJD1OmhUnTiSVjX6Tfw09vxFvfc4KJb14g"
    
    print("📝 Testing quiz completion with direct token...")
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
    
    try:
        quiz_response = requests.post(
            f"{base_url}/api/v1/users/quiz-completion",
            json=quiz_data,
            headers=headers,
            timeout=10
        )
        
        print(f"Quiz completion status: {quiz_response.status_code}")
        print(f"Response headers: {dict(quiz_response.headers)}")
        print(f"Response body: {quiz_response.text}")
        
        if quiz_response.status_code == 201:
            print("✅ Quiz completion successful!")
            result = quiz_response.json()
            print(f"Assigned archetype: {result.get('style_archetype', 'unknown')}")
        else:
            print("❌ Quiz completion failed")
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Network error: {e}")
    except Exception as e:
        print(f"❌ Unexpected error: {e}")

if __name__ == "__main__":
    test_quiz_completion_direct()
