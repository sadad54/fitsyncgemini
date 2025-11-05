#!/usr/bin/env python3
"""
FitSync Backend Integration Test Suite
Tests all API endpoints and external service integrations
"""

import asyncio
import httpx
import json
import os
from pathlib import Path
from typing import Dict, Any, Optional

# Test configuration
BASE_URL = "http://localhost:8000"
TEST_USER = {
    "email": "test@fitsync.com",
    "password": "testpassword123",
    "username": "testuser",
    "first_name": "Test",
    "last_name": "User"
}

class FitSyncTester:
    def __init__(self):
        self.client = httpx.AsyncClient(timeout=30.0)
        self.auth_token: Optional[str] = None
        self.test_results = []
        
    async def __aenter__(self):
        return self
        
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        await self.client.aclose()
    
    def log_test(self, test_name: str, success: bool, message: str = ""):
        status = "✅" if success else "❌"
        print(f"{status} {test_name}: {message}")
        self.test_results.append({
            "test": test_name,
            "success": success,
            "message": message
        })
    
    async def test_health_check(self):
        """Test basic health endpoint"""
        try:
            response = await self.client.get(f"{BASE_URL}/health")
            if response.status_code == 200:
                data = response.json()
                self.log_test("Health Check", True, f"Status: {data.get('status')}")
                return True
            else:
                self.log_test("Health Check", False, f"HTTP {response.status_code}")
                return False
        except Exception as e:
            self.log_test("Health Check", False, str(e))
            return False
    
    async def test_api_docs(self):
        """Test API documentation endpoint"""
        try:
            response = await self.client.get(f"{BASE_URL}/docs")
            success = response.status_code == 200
            self.log_test("API Documentation", success, 
                         "Available" if success else f"HTTP {response.status_code}")
            return success
        except Exception as e:
            self.log_test("API Documentation", False, str(e))
            return False
    
    async def test_cors_headers(self):
        """Test CORS configuration"""
        try:
            response = await self.client.options(
                f"{BASE_URL}/health",
                headers={
                    "Origin": "http://localhost:3000",
                    "Access-Control-Request-Method": "GET"
                }
            )
            
            cors_origin = response.headers.get("access-control-allow-origin")
            success = cors_origin is not None
            self.log_test("CORS Headers", success, 
                         f"Allow-Origin: {cors_origin}" if success else "Not configured")
            return success
        except Exception as e:
            self.log_test("CORS Headers", False, str(e))
            return False
    
    async def test_user_registration(self):
        """Test user registration endpoint"""
        try:
            response = await self.client.post(
                f"{BASE_URL}/api/v1/auth/register",
                json=TEST_USER
            )
            
            if response.status_code in [200, 201]:
                data = response.json()
                self.log_test("User Registration", True, f"User ID: {data.get('id', 'N/A')}")
                return True
            elif response.status_code == 400:
                # User might already exist
                self.log_test("User Registration", True, "User already exists (expected)")
                return True
            else:
                self.log_test("User Registration", False, f"HTTP {response.status_code}: {response.text}")
                return False
        except Exception as e:
            self.log_test("User Registration", False, str(e))
            return False
    
    async def test_user_login(self):
        """Test user login and get auth token"""
        try:
            response = await self.client.post(
                f"{BASE_URL}/api/v1/auth/login",
                data={
                    "username": TEST_USER["email"],
                    "password": TEST_USER["password"]
                }
            )
            
            if response.status_code == 200:
                data = response.json()
                self.auth_token = data.get("access_token")
                self.log_test("User Login", True, f"Token: {self.auth_token[:20]}..." if self.auth_token else "No token")
                return True
            else:
                self.log_test("User Login", False, f"HTTP {response.status_code}: {response.text}")
                return False
        except Exception as e:
            self.log_test("User Login", False, str(e))
            return False
    
    async def test_authenticated_endpoints(self):
        """Test endpoints that require authentication"""
        if not self.auth_token:
            self.log_test("Authenticated Endpoints", False, "No auth token available")
            return False
        
        headers = {"Authorization": f"Bearer {self.auth_token}"}
        
        # Test endpoints
        endpoints = [
            ("GET", "/api/v1/auth/me", "Get Current User"),
            ("GET", "/api/v1/clothing/", "Get Clothing Items"),
            ("GET", "/api/v1/clothing/recommendations/smart", "Smart Recommendations"),
            ("GET", "/api/v1/trends/", "Get Trends"),
            ("GET", "/api/v1/community/posts", "Community Posts"),
        ]
        
        success_count = 0
        for method, endpoint, name in endpoints:
            try:
                if method == "GET":
                    response = await self.client.get(f"{BASE_URL}{endpoint}", headers=headers)
                else:
                    response = await self.client.request(method, f"{BASE_URL}{endpoint}", headers=headers)
                
                if response.status_code in [200, 201]:
                    self.log_test(name, True, f"HTTP {response.status_code}")
                    success_count += 1
                else:
                    self.log_test(name, False, f"HTTP {response.status_code}")
            except Exception as e:
                self.log_test(name, False, str(e))
        
        return success_count == len(endpoints)
    
    async def test_external_apis(self):
        """Test external API integrations"""
        # This would require actual API keys, so we'll just test the endpoints exist
        external_tests = [
            ("Weather API", "/api/v1/weather/current?lat=40.7128&lon=-74.0060"),
            ("Locations API", "/api/v1/locations/nearby?lat=40.7128&lon=-74.0060"),
        ]
        
        headers = {"Authorization": f"Bearer {self.auth_token}"} if self.auth_token else {}
        
        for name, endpoint in external_tests:
            try:
                response = await self.client.get(f"{BASE_URL}{endpoint}", headers=headers)
                # We expect these to potentially fail due to missing API keys
                # but they should return proper error codes, not 404
                if response.status_code != 404:
                    self.log_test(name, True, f"Endpoint exists (HTTP {response.status_code})")
                else:
                    self.log_test(name, False, "Endpoint not found")
            except Exception as e:
                self.log_test(name, False, str(e))
    
    async def run_all_tests(self):
        """Run all tests in sequence"""
        print("🚀 Starting FitSync Backend Integration Tests...\n")
        
        # Basic connectivity tests
        health_ok = await self.test_health_check()
        if not health_ok:
            print("\n❌ Backend is not running or not accessible!")
            print("💡 Make sure to start the backend with: ./start_backend.sh")
            return False
        
        await self.test_api_docs()
        await self.test_cors_headers()
        
        # Authentication tests
        await self.test_user_registration()
        login_ok = await self.test_user_login()
        
        if login_ok:
            await self.test_authenticated_endpoints()
        
        await self.test_external_apis()
        
        # Summary
        print(f"\n📊 Test Results Summary:")
        total_tests = len(self.test_results)
        passed_tests = sum(1 for result in self.test_results if result["success"])
        
        print(f"   Total Tests: {total_tests}")
        print(f"   Passed: {passed_tests}")
        print(f"   Failed: {total_tests - passed_tests}")
        print(f"   Success Rate: {(passed_tests/total_tests)*100:.1f}%")
        
        if passed_tests == total_tests:
            print("\n🎉 All tests passed! Backend is ready for Flutter integration.")
        else:
            print("\n⚠️  Some tests failed. Check the issues above.")
        
        return passed_tests == total_tests

async def main():
    async with FitSyncTester() as tester:
        await tester.run_all_tests()

if __name__ == "__main__":
    asyncio.run(main())