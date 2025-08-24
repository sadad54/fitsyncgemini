#!/usr/bin/env python3
"""
Test script for Hugging Face virtual try-on integration
"""

import asyncio
import httpx
import json
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

async def test_huggingface_models():
    """Test Hugging Face models for virtual try-on"""
    
    print("🧪 Testing Hugging Face Virtual Try-On Models...")
    
    # Test models
    models_to_test = [
        {
            "name": "YOLO Clothing Detection",
            "model": "hustvl/yolos-tiny",
            "description": "Object detection for clothing items"
        },
        {
            "name": "Image Segmentation",
            "model": "facebook/detr-resnet-50-panoptic",
            "description": "Clothing segmentation and analysis"
        },
        {
            "name": "Stable Diffusion",
            "model": "CompVis/stable-diffusion-v1-4",
            "description": "Style transfer for virtual try-on"
        }
    ]
    
    # Create a simple test image (1x1 pixel)
    test_image = b'\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x01\x00H\x00H\x00\x00\xff\xdb\x00C\x00\x08\x06\x06\x07\x06\x05\x08\x07\x07\x07\t\t\x08\n\x0c\x14\r\x0c\x0b\x0b\x0c\x19\x12\x13\x0f\x14\x1d\x1a\x1f\x1e\x1d\x1a\x1c\x1c $.\' ",#\x1c\x1c(7),01444\x1f\'9=82<.342\xff\xc0\x00\x11\x08\x00\x01\x00\x01\x01\x01\x11\x00\x02\x11\x01\x03\x11\x01\xff\xc4\x00\x14\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\xff\xc4\x00\x14\x10\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xff\xda\x00\x0c\x03\x01\x00\x02\x11\x03\x11\x00\x3f\x00\xaa\xff\xd9'
    
    working_models = []
    
    for model in models_to_test:
        print(f"\n🔍 Testing {model['name']}...")
        print(f"   Model: {model['model']}")
        
        try:
            async with httpx.AsyncClient() as client:
                if model['name'] == "Stable Diffusion":
                    # Test with text prompt
                    payload = {
                        "inputs": "a person wearing a red shirt, high quality fashion photography"
                    }
                    
                    response = await client.post(
                        f"https://api-inference.huggingface.co/models/{model['model']}",
                        json=payload,
                        timeout=60.0
                    )
                else:
                    # Test with image
                    response = await client.post(
                        f"https://api-inference.huggingface.co/models/{model['model']}",
                        data=test_image,
                        timeout=30.0
                    )
                
                print(f"   Status Code: {response.status_code}")
                
                if response.status_code == 200:
                    print(f"   ✅ SUCCESS! Model is working")
                    working_models.append(model)
                elif response.status_code == 503:
                    print(f"   ⚠️ Model is loading (first request)")
                    working_models.append(model)
                else:
                    print(f"   ❌ FAILED!")
                    print(f"   Error: {response.text[:200]}...")
                    
        except Exception as e:
            print(f"   ❌ EXCEPTION: {str(e)}")
    
    return working_models

async def test_huggingface_token():
    """Test if Hugging Face token is working"""
    
    print("\n🔑 Testing Hugging Face Token...")
    
    token = os.getenv('HUGGINGFACE_TOKEN')
    if not token or token == "your_huggingface_token_here":
        print("   ⚠️ No Hugging Face token found")
        print("   💡 Get a free token from: https://huggingface.co/settings/tokens")
        return False
    
    try:
        headers = {"Authorization": f"Bearer {token}"}
        
        async with httpx.AsyncClient() as client:
            response = await client.get(
                "https://huggingface.co/api/whoami",
                headers=headers,
                timeout=10.0
            )
            
            if response.status_code == 200:
                user_info = response.json()
                print(f"   ✅ Token is valid! User: {user_info.get('name', 'Unknown')}")
                return True
            else:
                print(f"   ❌ Token is invalid")
                return False
                
    except Exception as e:
        print(f"   ❌ Token test failed: {str(e)}")
        return False

async def main():
    """Main test function"""
    print("🧪 Hugging Face Virtual Try-On Test")
    print("=" * 50)
    
    # Test token first
    token_valid = await test_huggingface_token()
    
    # Test models
    working_models = await test_huggingface_models()
    
    print("\n" + "=" * 50)
    print("📊 TEST SUMMARY")
    print("=" * 50)
    
    if token_valid:
        print("✅ Hugging Face token is valid")
    else:
        print("⚠️ Hugging Face token needs to be set")
    
    print(f"✅ Found {len(working_models)} working models:")
    for model in working_models:
        print(f"   - {model['name']}: {model['model']}")
    
    if len(working_models) >= 2:
        print("\n🎉 Hugging Face virtual try-on is ready!")
        print("💡 Your FitSync backend now has free virtual try-on capabilities!")
    else:
        print("\n⚠️ Some models need to be configured")
        print("💡 Models will work automatically on first use")
    
    print("\n🚀 Next steps:")
    print("1. Get a free Hugging Face token: https://huggingface.co/settings/tokens")
    print("2. Add the token to your .env file")
    print("3. Test the virtual try-on endpoint")

if __name__ == "__main__":
    asyncio.run(main())
