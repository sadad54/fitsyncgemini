import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'MLAPI_service.dart';

/// Enhanced backend service with proper error handling and connection management
class EnhancedBackendService {
  static bool _isBackendConnected = false;
  static String? _lastError;
  static DateTime? _lastHealthCheck;
  
  // Cache health check for 30 seconds
  static const Duration _healthCheckCacheDuration = Duration(seconds: 30);
  
  /// Check if backend is reachable and healthy
  static Future<BackendHealthStatus> checkBackendHealth() async {
    // Return cached result if recent
    if (_lastHealthCheck != null && 
        DateTime.now().difference(_lastHealthCheck!) < _healthCheckCacheDuration) {
      return BackendHealthStatus(
        isConnected: _isBackendConnected,
        error: _lastError,
        lastChecked: _lastHealthCheck,
      );
    }
    
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.healthUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _isBackendConnected = true;
        _lastError = null;
        _lastHealthCheck = DateTime.now();
        
        if (kDebugMode) {
          print('✅ Backend health check successful: ${data['status']}');
        }
        
        return BackendHealthStatus(
          isConnected: true,
          healthData: data,
          lastChecked: _lastHealthCheck,
        );
      } else {
        throw HttpException('Health check failed: ${response.statusCode}');
      }
    } catch (e) {
      _isBackendConnected = false;
      _lastError = e.toString();
      _lastHealthCheck = DateTime.now();
      
      if (kDebugMode) {
        print('❌ Backend health check failed: $e');
      }
      
      return BackendHealthStatus(
        isConnected: false,
        error: _lastError,
        lastChecked: _lastHealthCheck,
      );
    }
  }
  
  /// Make authenticated API request with proper error handling
  static Future<ApiResponse<T>> makeAuthenticatedRequest<T>({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? parser,
  }) async {
    try {
      // Check backend health first
      final health = await checkBackendHealth();
      if (!health.isConnected) {
        return ApiResponse<T>.error(
          'Backend not available: ${health.error ?? 'Connection failed'}',
          isNetworkError: true,
        );
      }
      
      // Get auth token
      final token = MLAPIService.authToken;
      final requestHeaders = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        ...?headers,
      };
      
      if (token != null) {
        requestHeaders['Authorization'] = 'Bearer $token';
      }
      
      // Make request
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      late http.Response response;
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: requestHeaders);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: requestHeaders,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: requestHeaders,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: requestHeaders);
          break;
        default:
          throw ArgumentError('Unsupported HTTP method: $method');
      }
      
      // Handle response
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = json.decode(response.body);
        
        if (parser != null && responseData is Map<String, dynamic>) {
          return ApiResponse<T>.success(parser(responseData));
        } else {
          return ApiResponse<T>.success(responseData as T);
        }
      } else if (response.statusCode == 401) {
        return ApiResponse<T>.error(
          'Authentication required. Please log in again.',
          isAuthError: true,
        );
      } else if (response.statusCode == 403) {
        return ApiResponse<T>.error(
          'Access denied. You don\'t have permission for this action.',
          isAuthError: true,
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse<T>.error(
          errorData['detail'] ?? 'Request failed: ${response.statusCode}',
        );
      }
    } on SocketException {
      return ApiResponse<T>.error(
        'No internet connection. Please check your network.',
        isNetworkError: true,
      );
    } on HttpException catch (e) {
      return ApiResponse<T>.error(
        'Network error: ${e.message}',
        isNetworkError: true,
      );
    } catch (e) {
      return ApiResponse<T>.error('Unexpected error: $e');
    }
  }
  
  /// Upload file with progress tracking
  static Future<ApiResponse<Map<String, dynamic>>> uploadFile({
    required String endpoint,
    required File file,
    required String fieldName,
    Map<String, String>? additionalFields,
    void Function(double progress)? onProgress,
  }) async {
    try {
      // Check backend health
      final health = await checkBackendHealth();
      if (!health.isConnected) {
        return ApiResponse.error(
          'Backend not available: ${health.error ?? 'Connection failed'}',
          isNetworkError: true,
        );
      }
      
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final request = http.MultipartRequest('POST', uri);
      
      // Add auth header
      final token = MLAPIService.authToken;
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      // Add file
      final fileStream = http.ByteStream(file.openRead());
      final fileLength = await file.length();
      
      request.files.add(http.MultipartFile(
        fieldName,
        fileStream,
        fileLength,
        filename: file.path.split('/').last,
      ));
      
      // Add additional fields
      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = json.decode(response.body);
        return ApiResponse.success(responseData);
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse.error(
          errorData['detail'] ?? 'Upload failed: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse.error('Upload error: $e');
    }
  }
}

/// Backend health status
class BackendHealthStatus {
  final bool isConnected;
  final String? error;
  final Map<String, dynamic>? healthData;
  final DateTime? lastChecked;
  
  const BackendHealthStatus({
    required this.isConnected,
    this.error,
    this.healthData,
    this.lastChecked,
  });
  
  String get statusMessage {
    if (isConnected) {
      return 'Connected';
    } else if (error != null) {
      if (error!.contains('Connection refused') || 
          error!.contains('No route to host')) {
        return 'Backend server not running';
      } else if (error!.contains('timeout')) {
        return 'Connection timeout';
      } else {
        return 'Connection error';
      }
    }
    return 'Unknown status';
  }
}

/// Generic API response wrapper
class ApiResponse<T> {
  final bool isSuccess;
  final T? data;
  final String? error;
  final bool isNetworkError;
  final bool isAuthError;
  
  const ApiResponse._({
    required this.isSuccess,
    this.data,
    this.error,
    this.isNetworkError = false,
    this.isAuthError = false,
  });
  
  factory ApiResponse.success(T data) {
    return ApiResponse._(isSuccess: true, data: data);
  }
  
  factory ApiResponse.error(
    String error, {
    bool isNetworkError = false,
    bool isAuthError = false,
  }) {
    return ApiResponse._(
      isSuccess: false,
      error: error,
      isNetworkError: isNetworkError,
      isAuthError: isAuthError,
    );
  }
}