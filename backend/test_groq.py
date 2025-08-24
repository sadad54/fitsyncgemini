#!/usr/bin/env python3
"""
Simple test script to verify Groq API integration
"""

import asyncio
import httpx
import json
from app.core.config import settings

async def test_groq_api():
    """Test Groq API with a simple fashion analysis request"""
    
    api_key = "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"
    base_url = "https://api.groq.com/openai/v1"
    
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }
    
    # Simple fashion analysis prompt
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
    
    try:
        async with httpx.AsyncClient() as client:
            print("Testing Groq API connection...")
            response = await client.post(
                f"{base_url}/chat/completions",
                headers=headers,
                json=payload,
                timeout=30.0
            )
            
            if response.status_code == 200:
                result = response.json()
                content = result["choices"][0]["message"]["content"]
                print("✅ Groq API test successful!")
                print(f"Response: {content}")
                return True
            else:
                print(f"❌ Groq API test failed with status {response.status_code}")
                print(f"Error: {response.text}")
                return False
                
    except Exception as e:
        print(f"❌ Groq API test failed with exception: {str(e)}")
        return False

if __name__ == "__main__":
    asyncio.run(test_groq_api())
