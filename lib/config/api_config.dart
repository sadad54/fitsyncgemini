// lib/config/api_config.dart
class ApiConfig {
  // Base URL - make this configurable for different environments
  // When running on Android Emulator, the host machine is accessible via 10.0.2.2
  static const String _baseUrl = 'http://10.0.2.2:8000';

  // Toggle to use real backend instead of mocks
  static const bool useBackend = true;

  // Development/Production URL switching
  static String get baseUrl {
    // You can add environment detection logic here
    // For example: return kDebugMode ? _devBaseUrl : _prodBaseUrl;
    return _baseUrl;
  }

  // API v1 base
  static String get apiV1Base => '$baseUrl/api/v1';

  // Endpoint paths
  static const String detectPath = '/detect';
  static const String colorPath = '/color';
  static const String suggestPath = '/suggest';
  static const String healthPath = '/health';

  // Auth endpoints
  static String get authRegisterUrl => '$apiV1Base/auth/register';
  static String get authLoginUrl => '$apiV1Base/auth/login';
  static String get authMeUrl => '$apiV1Base/auth/me';

  // Core features
  static String get clothingUrl => '$apiV1Base/clothing';
  static String get tryOnUrl => '$apiV1Base/tryon';
  static String get recommendationsUrl => '$apiV1Base/recommendations';
  static String get weatherUrl => '$apiV1Base/weather';
  static String get locationsUrl => '$apiV1Base/locations';

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
