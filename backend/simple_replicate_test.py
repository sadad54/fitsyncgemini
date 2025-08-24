#!/usr/bin/env python3
"""
Simple test to find working Replicate models
"""

import asyncio
import httpx
import json

async def test_known_models():
    """Test known working models for virtual try-on"""
    
    api_key = "r8_a3nDu36tR0G2fpnnrrCRrDkynyzGj6R1qMIgi"
    
    print("🧪 Testing known virtual try-on models...")
    
    # Known virtual try-on models on Replicate
    models_to_test = [
        {
            "name": "HR-VITON",
            "version": "854e8727697a057c525cdb45ab037f64ecca770a1769cc52287c2e56472a247b",
            "description": "High-resolution virtual try-on"
        },
        {
            "name": "VITON-HD",
            "version": "732a5c3d3edf4d502c7b5c7c9d0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b",
            "description": "Virtual try-on with high definition"
        },
        {
            "name": "ACGP-VTON",
            "version": "c221b2b8ef527988fb59bf24a8b97c4565f1dd671ea73c704fdc6a22e9d2a0a5",
            "description": "Advanced virtual try-on model"
        }
    ]
    
    headers = {
        "Authorization": f"Token {api_key}",
        "Content-Type": "application/json"
    }
    
    working_models = []
    
    for model in models_to_test:
        print(f"\n🔍 Testing {model['name']}...")
        print(f"   Version: {model['version']}")
        
        # Test with minimal input
        payload = {
            "version": model['version'],
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
                
                if response.status_code in [200, 201]:
                    result = response.json()
                    print(f"   ✅ SUCCESS! Prediction ID: {result.get('id', 'N/A')}")
                    working_models.append(model)
                else:
                    print(f"   ❌ FAILED!")
                    error_text = response.text
                    print(f"   Error: {error_text[:200]}...")
                    
        except Exception as e:
            print(f"   ❌ EXCEPTION: {str(e)}")
    
    return working_models

async def find_alternative_models():
    """Find alternative models that might work"""
    
    api_key = "r8_a3nDu36tR0G2fpnnrrCRrDkynyzGj6R1qMIgi"
    
    print("\n🔍 Searching for alternative models...")
    
    headers = {
        "Authorization": f"Token {api_key}",
        "Content-Type": "application/json"
    }
    
    # Try some popular image generation models that might work for fashion
    alternative_models = [
        {
            "name": "Stable Diffusion",
            "version": "db21e45d3f7023abc2a46ee38a23973f6dce16bb082a930b0c49861f96d1e5bf",
            "description": "General image generation"
        },
        {
            "name": "Real-ESRGAN",
            "version": "42fed1c4974146d4d2414e2be2c5277fb7d05dd9b57f6e2f31b64e7b4662d4c4",
            "description": "Image upscaling"
        }
    ]
    
    working_alternatives = []
    
    for model in alternative_models:
        print(f"\n🔍 Testing {model['name']}...")
        
        # Test with simple input
        payload = {
            "version": model['version'],
            "input": {
                "prompt": "a fashion model wearing a red dress"
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
                
                if response.status_code in [200, 201]:
                    result = response.json()
                    print(f"   ✅ SUCCESS! Prediction ID: {result.get('id', 'N/A')}")
                    working_alternatives.append(model)
                else:
                    print(f"   ❌ FAILED!")
                    error_text = response.text
                    print(f"   Error: {error_text[:200]}...")
                    
        except Exception as e:
            print(f"   ❌ EXCEPTION: {str(e)}")
    
    return working_alternatives

async def main():
    """Main function"""
    print("🔍 Replicate Model Compatibility Test")
    print("=" * 50)
    
    # Test known virtual try-on models
    working_vton_models = await test_known_models()
    
    # Test alternative models
    working_alternatives = await find_alternative_models()
    
    print("\n" + "=" * 50)
    print("📊 RESULTS SUMMARY")
    print("=" * 50)
    
    if working_vton_models:
        print(f"✅ Found {len(working_vton_models)} working virtual try-on models:")
        for model in working_vton_models:
            print(f"   - {model['name']}: {model['version']}")
    else:
        print("❌ No virtual try-on models are working with your account")
    
    if working_alternatives:
        print(f"\n✅ Found {len(working_alternatives)} working alternative models:")
        for model in working_alternatives:
            print(f"   - {model['name']}: {model['version']}")
    
    if not working_vton_models and not working_alternatives:
        print("\n⚠️ No models are working. This might be due to:")
        print("   1. Account restrictions")
        print("   2. Model access permissions")
        print("   3. API key limitations")
        print("\n💡 Recommendations:")
        print("   1. Check your Replicate account status")
        print("   2. Try upgrading to a paid plan")
        print("   3. Contact Replicate support")
        print("   4. Use alternative virtual try-on services")

if __name__ == "__main__":
    asyncio.run(main())
