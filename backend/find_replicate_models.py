#!/usr/bin/env python3
"""
Find available virtual try-on models on Replicate
"""

import asyncio
import httpx
import json

async def find_virtual_tryon_models():
    """Find virtual try-on models on Replicate"""
    
    api_key = "r8_a3nDu36tR0G2fpnnrrCRrDkynyzGj6R1qMIgi"
    
    print("🔍 Searching for virtual try-on models on Replicate...")
    
    headers = {
        "Authorization": f"Token {api_key}",
        "Content-Type": "application/json"
    }
    
    # Search for virtual try-on related models
    search_terms = [
        "virtual try-on",
        "fashion try-on", 
        "clothing try-on",
        "garment try-on",
        "outfit try-on",
        "fashion ai",
        "clothing ai"
    ]
    
    found_models = []
    
    for term in search_terms:
        print(f"\n🔎 Searching for: '{term}'")
        
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"https://api.replicate.com/v1/models?search={term}",
                    headers=headers,
                    timeout=30.0
                )
                
                if response.status_code == 200:
                    result = response.json()
                    models = result.get('results', [])
                    
                    for model in models:
                        model_info = {
                            'name': model.get('name', 'N/A'),
                            'description': model.get('description', 'N/A'),
                            'url': model.get('url', 'N/A'),
                            'owner': model.get('owner', 'N/A'),
                            'latest_version': model.get('latest_version', {}).get('id', 'N/A')
                        }
                        
                        # Check if it's a virtual try-on model
                        if any(keyword in model_info['description'].lower() or keyword in model_info['name'].lower() 
                               for keyword in ['try-on', 'fashion', 'clothing', 'garment', 'outfit']):
                            found_models.append(model_info)
                            print(f"   ✅ Found: {model_info['name']} by {model_info['owner']}")
                            print(f"      Description: {model_info['description'][:100]}...")
                            print(f"      Latest Version: {model_info['latest_version']}")
                
        except Exception as e:
            print(f"   ❌ Error searching for '{term}': {str(e)}")
    
    # Also get popular models
    print(f"\n🔎 Getting popular models...")
    
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(
                "https://api.replicate.com/v1/models?cursor=&limit=50",
                headers=headers,
                timeout=30.0
            )
            
            if response.status_code == 200:
                result = response.json()
                models = result.get('results', [])
                
                for model in models:
                    model_info = {
                        'name': model.get('name', 'N/A'),
                        'description': model.get('description', 'N/A'),
                        'url': model.get('url', 'N/A'),
                        'owner': model.get('owner', 'N/A'),
                        'latest_version': model.get('latest_version', {}).get('id', 'N/A')
                    }
                    
                    # Check if it's fashion-related
                    if any(keyword in model_info['description'].lower() or keyword in model_info['name'].lower() 
                           for keyword in ['fashion', 'clothing', 'garment', 'outfit', 'style', 'dress']):
                        found_models.append(model_info)
                        print(f"   ✅ Found: {model_info['name']} by {model_info['owner']}")
                        print(f"      Description: {model_info['description'][:100]}...")
                        print(f"      Latest Version: {model_info['latest_version']}")
    
    except Exception as e:
        print(f"   ❌ Error getting popular models: {str(e)}")
    
    # Remove duplicates
    unique_models = []
    seen_names = set()
    
    for model in found_models:
        if model['name'] not in seen_names:
            unique_models.append(model)
            seen_names.add(model['name'])
    
    print(f"\n📊 Found {len(unique_models)} unique fashion-related models")
    
    # Save results
    with open("replicate_fashion_models.json", "w") as f:
        json.dump(unique_models, f, indent=2)
    
    print(f"📄 Results saved to: replicate_fashion_models.json")
    
    return unique_models

async def test_specific_model(model_version):
    """Test a specific model version"""
    
    api_key = "r8_a3nDu36tR0G2fpnnrrCRrDkynyzGj6R1qMIgi"
    
    print(f"\n🧪 Testing model version: {model_version}")
    
    headers = {
        "Authorization": f"Token {api_key}",
        "Content-Type": "application/json"
    }
    
    # Test with minimal input
    payload = {
        "version": model_version,
        "input": {
            "text": "test"
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
                return True
            else:
                print(f"   ❌ FAILED!")
                print(f"   Error Response: {response.text}")
                return False
                
    except Exception as e:
        print(f"   ❌ EXCEPTION: {str(e)}")
        return False

async def main():
    """Main function"""
    print("🔍 Replicate Fashion Models Finder")
    print("=" * 50)
    
    # Find models
    models = await find_virtual_tryon_models()
    
    if models:
        print(f"\n🎯 Top 5 recommended models for virtual try-on:")
        for i, model in enumerate(models[:5], 1):
            print(f"{i}. {model['name']} by {model['owner']}")
            print(f"   Version: {model['latest_version']}")
            print(f"   Description: {model['description'][:80]}...")
            print()
        
        # Test the first model
        if models:
            await test_specific_model(models[0]['latest_version'])
    else:
        print("❌ No fashion-related models found")

if __name__ == "__main__":
    asyncio.run(main())
