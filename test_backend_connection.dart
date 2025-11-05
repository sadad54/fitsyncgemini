import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Test script to verify backend connection from Flutter
/// Run with: dart test_backend_connection.dart
void main() async {
  print('🔍 Testing FitSync Backend Connection...\n');
  
  const baseUrl = 'http://localhost:8000';
  
  // Test 1: Health Check
  await testHealthCheck(baseUrl);
  
  // Test 2: API Documentation
  await testApiDocs(baseUrl);
  
  // Test 3: CORS Headers
  await testCorsHeaders(baseUrl);
  
  // Test 4: Authentication Endpoints
  await testAuthEndpoints(baseUrl);
  
  print('\n✅ Backend connection tests completed!');
}

Future<void> testHealthCheck(String baseUrl) async {
  print('1️⃣ Testing Health Check...');
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/health'),
      headers: {'Accept': 'application/json'},
    ).timeout(Duration(seconds: 10));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('   ✅ Health check successful');
      print('   📊 Status: ${data['status']}');
      print('   🏷️  Service: ${data['service']}');
      print('   🌍 Environment: ${data['env']}');
    } else {
      print('   ❌ Health check failed: ${response.statusCode}');
    }
  } catch (e) {
    print('   ❌ Health check error: $e');
    print('   💡 Make sure backend is running on $baseUrl');
  }
}

Future<void> testApiDocs(String baseUrl) async {
  print('\n2️⃣ Testing API Documentation...');
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/docs'),
    ).timeout(Duration(seconds: 5));
    
    if (response.statusCode == 200) {
      print('   ✅ API documentation accessible');
      print('   🔗 Visit: $baseUrl/docs');
    } else {
      print('   ❌ API docs not accessible: ${response.statusCode}');
    }
  } catch (e) {
    print('   ❌ API docs error: $e');
  }
}

Future<void> testCorsHeaders(String baseUrl) async {
  print('\n3️⃣ Testing CORS Headers...');
  try {
    final response = await http.options(
      Uri.parse('$baseUrl/health'),
      headers: {
        'Origin': 'http://localhost:3000',
        'Access-Control-Request-Method': 'GET',
      },
    ).timeout(Duration(seconds: 5));
    
    final corsHeaders = response.headers;
    if (corsHeaders.containsKey('access-control-allow-origin')) {
      print('   ✅ CORS properly configured');
      print('   🌐 Allow Origin: ${corsHeaders['access-control-allow-origin']}');
    } else {
      print('   ⚠️  CORS headers not found');
    }
  } catch (e) {
    print('   ❌ CORS test error: $e');
  }
}

Future<void> testAuthEndpoints(String baseUrl) async {
  print('\n4️⃣ Testing Authentication Endpoints...');
  
  // Test auth endpoints exist (should return 422 for missing data, not 404)
  final authEndpoints = [
    '/api/v1/auth/register',
    '/api/v1/auth/login',
    '/api/v1/auth/me',
  ];
  
  for (final endpoint in authEndpoints) {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({}),
      ).timeout(Duration(seconds: 5));
      
      // 422 = Validation Error (endpoint exists but data invalid)
      // 404 = Not Found (endpoint doesn't exist)
      if (response.statusCode == 422) {
        print('   ✅ $endpoint exists and working');
      } else if (response.statusCode == 404) {
        print('   ❌ $endpoint not found');
      } else {
        print('   ⚠️  $endpoint returned: ${response.statusCode}');
      }
    } catch (e) {
      print('   ❌ $endpoint error: $e');
    }
  }
}