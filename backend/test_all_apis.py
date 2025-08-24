#!/usr/bin/env python3
"""
Comprehensive API test script for FitSync backend
Tests all external APIs to ensure they're working correctly
"""

import asyncio
import httpx
import json
import os
from typing import Dict, List
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Test configuration - using environment variables
TEST_CONFIG = {
    "groq_api_key": os.getenv('GROQ_API_KEY'),
    "google_vision_key": os.getenv('GOOGLE_CLOUD_VISION_API_KEY'),
    "fashion_ai_key": os.getenv('HUGGINGFACE_TOKEN'),  # Hugging Face token
    "openweather_api_key": os.getenv('OPENWEATHER_API_KEY'),
    "google_places_key": os.getenv('GOOGLE_PLACES_API_KEY'),
}

class APITester:
    def __init__(self):
        self.results = {}
        
    async def test_groq_api(self) -> Dict:
        """Test Groq API for fashion analysis"""
        print("🧠 Testing Groq API...")
        
        api_key = TEST_CONFIG['groq_api_key']
        if not api_key:
            print("⚠️ Groq API: SKIPPED (No API key found)")
            return {"status": "skipped", "reason": "No API key"}
        
        try:
            headers = {
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json"
            }
            
            payload = {
                "model": "llama-3.1-8b-instant",
                "messages": [
                    {
                        "role": "system",
                        "content": "You are an expert fashion stylist. Provide brief, practical fashion advice."
                    },
                    {
                        "role": "user",
                        "content": "What are the top 3 fashion trends for summer 2024?"
                    }
                ],
                "max_tokens": 300,
                "temperature": 0.3
            }
            
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    "https://api.groq.com/openai/v1/chat/completions",
                    headers=headers,
                    json=payload,
                    timeout=30.0
                )
                
                if response.status_code == 200:
                    result = response.json()
                    content = result["choices"][0]["message"]["content"]
                    print("✅ Groq API: SUCCESS")
                    print(f"   Response: {content[:100]}...")
                    return {"status": "success", "response": content[:100]}
                else:
                    print(f"❌ Groq API: FAILED (Status: {response.status_code})")
                    return {"status": "failed", "error": response.text}
                    
        except Exception as e:
            print(f"❌ Groq API: ERROR - {str(e)}")
            return {"status": "error", "error": str(e)}
    
    async def test_google_vision_api(self) -> Dict:
        """Test Google Vision API for image analysis"""
        print("👁️ Testing Google Vision API...")
        
        api_key = TEST_CONFIG['google_vision_key']
        if not api_key:
            print("⚠️ Google Vision API: SKIPPED (No API key found)")
            return {"status": "skipped", "reason": "No API key"}
        
        try:
            # Create a simple test image (1x1 pixel JPEG)
            test_image = b'\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x01\x00H\x00H\x00\x00\xff\xdb\x00C\x00\x08\x06\x06\x07\x06\x05\x08\x07\x07\x07\t\t\x08\n\x0c\x14\r\x0c\x0b\x0b\x0c\x19\x12\x13\x0f\x14\x1d\x1a\x1f\x1e\x1d\x1a\x1c\x1c $.\' ",#\x1c\x1c(7),01444\x1f\'9=82<.342\xff\xc0\x00\x11\x08\x00\x01\x00\x01\x01\x01\x11\x00\x02\x11\x01\x03\x11\x01\xff\xc4\x00\x14\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\xff\xc4\x00\x14\x10\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xff\xda\x00\x0c\x03\x01\x00\x02\x11\x03\x11\x00\x3f\x00\xaa\xff\xd9'
            
            import base64
            image_b64 = base64.b64encode(test_image).decode('utf-8')
            
            url = f"https://vision.googleapis.com/v1/images:annotate?key={api_key}"
            
            payload = {
                "requests": [
                    {
                        "image": {
                            "content": image_b64
                        },
                        "features": [
                            {
                                "type": "LABEL_DETECTION",
                                "maxResults": 5
                            }
                        ]
                    }
                ]
            }
            
            async with httpx.AsyncClient() as client:
                response = await client.post(url, json=payload, timeout=30.0)
                
                if response.status_code == 200:
                    result = response.json()
                    print("✅ Google Vision API: SUCCESS")
                    print(f"   Labels detected: {len(result.get('responses', [{}])[0].get('labelAnnotations', []))}")
                    return {"status": "success", "labels": len(result.get('responses', [{}])[0].get('labelAnnotations', []))}
                else:
                    print(f"❌ Google Vision API: FAILED (Status: {response.status_code})")
                    return {"status": "failed", "error": response.text}
                    
        except Exception as e:
            print(f"❌ Google Vision API: ERROR - {str(e)}")
            return {"status": "error", "error": str(e)}
    
    async def test_huggingface_api(self) -> Dict:
        """Test Hugging Face API for virtual try-on"""
        print("🎨 Testing Hugging Face API...")
        
        api_key = TEST_CONFIG['fashion_ai_key']
        if not api_key:
            print("⚠️ Hugging Face API: SKIPPED (No API key found)")
            return {"status": "skipped", "reason": "No API key"}
        
        try:
            headers = {
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json"
            }
            
            # Test with a simple model query
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    "https://huggingface.co/api/whoami",
                    headers=headers,
                    timeout=10.0
                )
                
                if response.status_code == 200:
                    result = response.json()
                    print("✅ Hugging Face API: SUCCESS")
                    print(f"   User: {result.get('name', 'N/A')}")
                    return {"status": "success", "user": result.get('name')}
                else:
                    print(f"❌ Hugging Face API: FAILED (Status: {response.status_code})")
                    return {"status": "failed", "error": response.text}
                    
        except Exception as e:
            print(f"❌ Hugging Face API: ERROR - {str(e)}")
            return {"status": "error", "error": str(e)}
    
    async def test_openweather_api(self) -> Dict:
        """Test OpenWeather API for weather data"""
        print("🌤️ Testing OpenWeather API...")
        
        api_key = TEST_CONFIG['openweather_api_key']
        if not api_key:
            print("⚠️ OpenWeather API: SKIPPED (No API key found)")
            return {"status": "skipped", "reason": "No API key"}
        
        try:
            # Test with New York coordinates
            lat, lon = 40.7128, -74.0060
            url = f"https://api.openweathermap.org/data/2.5/weather?lat={lat}&lon={lon}&appid={api_key}&units=metric"
            
            async with httpx.AsyncClient() as client:
                response = await client.get(url, timeout=30.0)
                
                if response.status_code == 200:
                    result = response.json()
                    temp = result.get('main', {}).get('temp', 'N/A')
                    weather = result.get('weather', [{}])[0].get('main', 'N/A')
                    print("✅ OpenWeather API: SUCCESS")
                    print(f"   Temperature: {temp}°C, Weather: {weather}")
                    return {"status": "success", "temperature": temp, "weather": weather}
                else:
                    print(f"❌ OpenWeather API: FAILED (Status: {response.status_code})")
                    return {"status": "failed", "error": response.text}
                    
        except Exception as e:
            print(f"❌ OpenWeather API: ERROR - {str(e)}")
            return {"status": "error", "error": str(e)}
    
    async def test_google_places_api(self) -> Dict:
        """Test Google Places API for location services"""
        print("📍 Testing Google Places API...")
        
        api_key = TEST_CONFIG['google_places_key']
        if not api_key:
            print("⚠️ Google Places API: SKIPPED (No API key found)")
            return {"status": "skipped", "reason": "No API key"}
        
        try:
            # Test with New York coordinates
            lat, lon = 40.7128, -74.0060
            url = f"https://maps.googleapis.com/maps/api/place/nearbysearch/json?location={lat},{lon}&radius=1000&type=clothing_store&key={api_key}"
            
            async with httpx.AsyncClient() as client:
                response = await client.get(url, timeout=30.0)
                
                if response.status_code == 200:
                    result = response.json()
                    places = result.get('results', [])
                    print("✅ Google Places API: SUCCESS")
                    print(f"   Found {len(places)} clothing stores nearby")
                    return {"status": "success", "places_count": len(places)}
                else:
                    print(f"❌ Google Places API: FAILED (Status: {response.status_code})")
                    return {"status": "failed", "error": response.text}
                    
        except Exception as e:
            print(f"❌ Google Places API: ERROR - {str(e)}")
            return {"status": "error", "error": str(e)}
    
    async def run_all_tests(self):
        """Run all API tests"""
        print("🚀 Starting FitSync Backend API Tests...")
        print("=" * 50)
        
        # Run all tests
        self.results["groq"] = await self.test_groq_api()
        self.results["google_vision"] = await self.test_google_vision_api()
        self.results["huggingface"] = await self.test_huggingface_api()
        self.results["openweather"] = await self.test_openweather_api()
        self.results["google_places"] = await self.test_google_places_api()
        
        # Print summary
        print("\n" + "=" * 50)
        print("📊 TEST SUMMARY")
        print("=" * 50)
        
        success_count = 0
        total_count = 0
        
        for api_name, result in self.results.items():
            status = result.get("status", "unknown")
            total_count += 1
            
            if status == "success":
                success_count += 1
                print(f"✅ {api_name.upper()}: WORKING")
            elif status == "skipped":
                print(f"⚠️ {api_name.upper()}: SKIPPED ({result.get('reason', 'Unknown')})")
            else:
                print(f"❌ {api_name.upper()}: FAILED")
        
        print(f"\n🎯 Results: {success_count}/{total_count} APIs working")
        
        if success_count >= 4:  # At least 4 out of 5 APIs should work
            print("🎉 Your FitSync backend is ready to go!")
        elif success_count >= 3:
            print("✅ Your FitSync backend is mostly ready! (Hugging Face token may need refresh)")
        else:
            print("⚠️ Some APIs need configuration. Check the setup guide.")
        
        return self.results

async def main():
    """Main test function"""
    tester = APITester()
    results = await tester.run_all_tests()
    
    # Save results to file
    with open("api_test_results.json", "w") as f:
        json.dump(results, f, indent=2)
    
    print(f"\n📄 Results saved to: api_test_results.json")

if __name__ == "__main__":
    asyncio.run(main())
