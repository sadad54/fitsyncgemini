// lib/config/api_config.dart
class ApiConfig {
  // Base URL - make this configurable for different environments
  static const String _baseUrl = 'http://127.0.0.1:8000/api/v1';

  // Development/Production URL switching
  static String get baseUrl {
    // You can add environment detection logic here
    // For example: return kDebugMode ? _devBaseUrl : _prodBaseUrl;
    return _baseUrl;
  }

  // Endpoint paths
  static const String detectPath = '/detect';
  static const String colorPath = '/color';
  static const String suggestPath = '/suggest';
  static const String healthPath = '/health';

  // Full endpoint URLs
  static String get detectUrl => '$baseUrl$detectPath';
  static String get colorUrl => '$baseUrl$colorPath';
  static String get suggestUrl => '$baseUrl$suggestPath';
  static String get healthUrl => '$baseUrl$healthPath';

  // Request configuration
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration healthCheckTimeout = Duration(seconds: 10);

  // Headers
  static const Map<String, String> defaultHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'multipart/form-data',
  };
}
