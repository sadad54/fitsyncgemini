#!/usr/bin/env python3
"""
Specific test for Replicate API to debug the issue
"""

import asyncio
import httpx
import json

async def test_replicate_api():
    """Test Replicate API with your specific key"""
    
    api_key = "r8_a3nDu36tR0G2fpnnrrCRrDkynyzGj6R1qMIgi"
    
    print(f"🔍 Testing Replicate API with key: {api_key[:10]}...")
    
    headers = {
        "Authorization": f"Token {api_key}",
        "Content-Type": "application/json"
    }
    
    # Test 1: Simple prediction creation
    print("\n1️⃣ Testing prediction creation...")
    
    payload = {
        "version": "c221b2b8ef527988fb59bf24a8b97c4565f1dd671ea73c704fdc6a22e9d2a0a5",
        "input": {
            "person_image": "https://example.com/test.jpg",
            "garment_image": "https://example.com/test.jpg"
        }
    }
    
    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                "https://api.replicate.com/v1/predictions",
                headers=headers,
                json=payload,
                timeout=30.0
            )
            
            print(f"   Status Code: {response.status_code}")
            print(f"   Response Headers: {dict(response.headers)}")
            
            if response.status_code in [200, 201]:
                result = response.json()
                print(f"   ✅ SUCCESS! Prediction ID: {result.get('id', 'N/A')}")
                print(f"   Status: {result.get('status', 'N/A')}")
                return True
            else:
                print(f"   ❌ FAILED!")
                print(f"   Error Response: {response.text}")
                return False
                
    except Exception as e:
        print(f"   ❌ EXCEPTION: {str(e)}")
        return False

async def test_replicate_models():
    """Test if we can list available models"""
    
    api_key = "r8_a3nDu36tR0G2fpnnrrCRrDkynyzGj6R1qMIgi"
    
    print("\n2️⃣ Testing model listing...")
    
    headers = {
        "Authorization": f"Token {api_key}",
        "Content-Type": "application/json"
    }
    
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(
                "https://api.replicate.com/v1/models",
                headers=headers,
                timeout=30.0
            )
            
            print(f"   Status Code: {response.status_code}")
            
            if response.status_code == 200:
                result = response.json()
                print(f"   ✅ SUCCESS! Found {len(result.get('results', []))} models")
                return True
            else:
                print(f"   ❌ FAILED!")
                print(f"   Error Response: {response.text}")
                return False
                
    except Exception as e:
        print(f"   ❌ EXCEPTION: {str(e)}")
        return False

async def test_replicate_account():
    """Test account information"""
    
    api_key = "r8_a3nDu36tR0G2fpnnrrCRrDkynyzGj6R1qMIgi"
    
    print("\n3️⃣ Testing account information...")
    
    headers = {
        "Authorization": f"Token {api_key}",
        "Content-Type": "application/json"
    }
    
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(
                "https://api.replicate.com/v1/account",
                headers=headers,
                timeout=30.0
            )
            
            print(f"   Status Code: {response.status_code}")
            
            if response.status_code == 200:
                result = response.json()
                print(f"   ✅ SUCCESS! Account: {result.get('username', 'N/A')}")
                print(f"   Type: {result.get('type', 'N/A')}")
                return True
            else:
                print(f"   ❌ FAILED!")
                print(f"   Error Response: {response.text}")
                return False
                
    except Exception as e:
        print(f"   ❌ EXCEPTION: {str(e)}")
        return False

async def main():
    """Main test function"""
    print("🔍 Replicate API Debug Test")
    print("=" * 50)
    
    # Run all tests
    test1 = await test_replicate_api()
    test2 = await test_replicate_models()
    test3 = await test_replicate_account()
    
    print("\n" + "=" * 50)
    print("📊 DEBUG SUMMARY")
    print("=" * 50)
    
    if test1 and test2 and test3:
        print("🎉 All tests passed! Your Replicate API key is working correctly.")
        print("The issue might be in the test script or model version.")
    elif test2 and test3:
        print("⚠️ API key is valid, but prediction creation failed.")
        print("This might be due to model version or input format.")
    elif test3:
        print("⚠️ API key is valid, but some endpoints are failing.")
        print("Check your account permissions and API access.")
    else:
        print("❌ API key appears to be invalid or expired.")
        print("Please check your Replicate account and regenerate the key.")

if __name__ == "__main__":
    asyncio.run(main())
