// lib/config/api_config.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // API prefix from backend
  static const String _apiPrefix = '/api/v1';

  // Environment-based configuration
  static const String _developmentBase = 'http://localhost:8000';
  static const String _androidEmulatorBase = 'http://10.0.2.2:8000';
  static const String _iosSimulatorBase = 'http://127.0.0.1:8000';
  static const String _webBase = 'http://127.0.0.1:8000';

  static String get baseUrl {
    // For development, always use localhost first
    if (kDebugMode) {
      if (kIsWeb) return _webBase;
      if (Platform.isAndroid) return _androidEmulatorBase;
      return _iosSimulatorBase;
    }
    
    // Production URLs would go here
    return _developmentBase;
  }

  // Common endpoints used by the app (align with backend)
  static String get healthUrl => '$baseUrl/health';
  static String get clothingBase => '$baseUrl$_apiPrefix/clothing';
  static String get outfitsBase => '$baseUrl$_apiPrefix/outfits';
  static String get tryOnBase => '$baseUrl$_apiPrefix/tryon';
  static String get virtualTryOnBase => '$baseUrl/virtual-tryon';
  static String get trendsBase => '$baseUrl$_apiPrefix/trends';
  static String get communityBase => '$baseUrl$_apiPrefix/community';
  static String get weatherBase => '$baseUrl$_apiPrefix/weather';

  // Request configuration
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration healthCheckTimeout = Duration(seconds: 10);

  // Headers
  static const Map<String, String> defaultMultipartHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'multipart/form-data',
  };
  static const Map<String, String> defaultJsonHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };
}
