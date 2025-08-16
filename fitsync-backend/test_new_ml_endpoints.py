#!/usr/bin/env python3
"""
Test script for the new ML endpoints
Run this from the fitsync-backend directory with: python test_new_ml_endpoints.py
"""

import requests
import json
from typing import Dict, Any

# Base URL (adjust if your backend runs on a different port)
BASE_URL = "http://127.0.0.1:8000"
API_BASE = f"{BASE_URL}/api/v1"

# Mock authentication token (replace with actual token from login)
AUTH_TOKEN = None

def get_headers() -> Dict[str, str]:
    """Get request headers with auth token if available"""
    headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
    }
    if AUTH_TOKEN:
        headers['Authorization'] = f'Bearer {AUTH_TOKEN}'
    return headers

def test_endpoint(endpoint: str, params: Dict[str, Any] = None) -> None:
    """Test a single endpoint"""
    try:
        print(f"\n🔍 Testing: {endpoint}")
        response = requests.get(
            f"{API_BASE}{endpoint}",
            headers=get_headers(),
            params=params,
            timeout=10
        )
        
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Success: {json.dumps(data, indent=2)[:200]}...")
        else:
            print(f"❌ Error: {response.text}")
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Network error: {e}")

def test_health_check():
    """Test basic health check first"""
    try:
        print("🔍 Testing health check...")
        response = requests.get(f"{BASE_URL}/health", timeout=5)
        if response.status_code == 200:
            print("✅ Backend is running")
            return True
        else:
            print(f"❌ Health check failed: {response.status_code}")
            return False
    except requests.exceptions.RequestException as e:
        print(f"❌ Backend not accessible: {e}")
        return False

def main():
    """Run all endpoint tests"""
    print("🚀 Testing New ML Endpoints")
    print("=" * 50)
    
    # Check if backend is running
    if not test_health_check():
        print("\n❌ Backend is not running. Please start the FastAPI server first.")
        print("From fitsync-backend directory, run: uvicorn app.main:app --reload")
        return
    
    # Note: These tests will fail with 401 without proper authentication
    # But we can at least verify the endpoints are registered and return expected error codes
    
    print("\n📋 Testing Outfit Recommendations:")
    test_endpoint("/ml/recommendations/outfits")
    test_endpoint("/ml/recommendations/outfits", {"limit": "5"})
    
    print("\n🔍 Testing Explore Endpoints:")
    test_endpoint("/ml/explore/categories")
    test_endpoint("/ml/explore/trending-styles")
    test_endpoint("/ml/explore/items")
    test_endpoint("/ml/explore/items", {"category": "tops", "trending": "true"})
    
    print("\n📈 Testing Trends Endpoints:")
    test_endpoint("/ml/trends/trending-now")
    test_endpoint("/ml/trends/trending-now", {"scope": "global", "timeframe": "week"})
    test_endpoint("/ml/trends/fashion-insights")
    test_endpoint("/ml/trends/influencer-spotlight")
    
    print("\n📍 Testing Nearby Endpoints:")
    # Mock coordinates for San Francisco
    test_endpoint("/ml/nearby/people", {"lat": "37.7749", "lng": "-122.4194"})
    test_endpoint("/ml/nearby/events", {"lat": "37.7749", "lng": "-122.4194"})
    test_endpoint("/ml/nearby/hotspots", {"lat": "37.7749", "lng": "-122.4194"})
    test_endpoint("/ml/nearby/map", {
        "lat": "37.7749", 
        "lng": "-122.4194",
        "limit_people": "5",
        "limit_events": "5",
        "limit_hotspots": "5"
    })
    
    print("\n" + "=" * 50)
    print("🎯 Test Summary:")
    print("• If you see 401 errors, that's expected without authentication")
    print("• If you see 404 errors, check that the endpoints are properly registered")
    print("• If you see 500 errors, check the backend logs for implementation issues")
    print("• Status 200 responses indicate the endpoints are working correctly")

if __name__ == "__main__":
    main()
