import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fitsyncgemini/config/api_config.dart';

class AuthService {
  String? _currentUserId;
  Map<String, dynamic>? _currentUser;
  String? _accessToken;
  bool _isInitialized = false;
  bool _isLoading = true;

  static const String _tokenKey = 'access_token';
  static const String _userKey = 'user_data';
  static const String _onboardingKey = 'onboarding_completed';

  AuthService() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    await _loadStoredAuth();
    _isInitialized = true;
    _isLoading = false;
  }

  Future<void> _loadStoredAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString(_tokenKey);
      final userJson = prefs.getString(_userKey);

      if (_accessToken != null && userJson != null) {
        _currentUser = json.decode(userJson);
        _currentUserId = _currentUser!['id'].toString();
        print('✅ AuthService: Loaded stored auth data');
      } else {
        print('⚠️ AuthService: No stored auth data found');
      }
    } catch (e) {
      print('❌ AuthService: Error loading stored auth: $e');
      await _clearStoredAuth();
    }
  }

  Future<void> _saveAuth(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, json.encode(user));
    print('💾 AuthService: Saved auth data');
  }

  Future<void> _clearStoredAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_onboardingKey);
    _accessToken = null;
    _currentUser = null;
    _currentUserId = null;
  }

  // Sign up with email and password (backend-first with fallback)
  Future<AuthResult> signUpWithEmail(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    try {
      if (ApiConfig.useBackend) {
        final uri = Uri.parse(ApiConfig.authRegisterUrl);
        final body = json.encode({
          'email': email,
          'password': password,
          'username': email.split('@')[0].replaceAll(RegExp(r'[^a-zA-Z0-9_]'), ''),
          'full_name': '$firstName $lastName',
        });
        final resp = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: body,
        );
        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          final data = json.decode(resp.body) as Map<String, dynamic>;
          // Immediately login to obtain token
          final loginRes = await signInWithEmail(email, password);
          return loginRes;
        } else {
          // Fall through to mock if backend unavailable or returns error
          print('⚠️ Backend register failed: ${resp.statusCode} ${resp.body}');
        }
      }

      // Fallback mock path
      await Future.delayed(const Duration(milliseconds: 800));
      final username = email.split('@')[0].replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
      final userId = DateTime.now().millisecondsSinceEpoch.toString();
      final userData = {
        'id': userId,
        'email': email,
        'username': username,
        'first_name': firstName,
        'last_name': lastName,
        'avatar': 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150',
        'hasCompletedOnboarding': false,
        'style_preferences': {
          'archetype': 'minimalist',
          'favorite_colors': ['black', 'white', 'navy'],
          'preferred_styles': ['minimalist', 'casual'],
        },
        'wardrobe_stats': {
          'total_items': 0,
          'total_value': 0,
          'recently_added': 0,
        },
      };
      _currentUserId = userId;
      _currentUser = userData;
      _accessToken = 'placeholder_token_${DateTime.now().millisecondsSinceEpoch}';
      await _saveAuth(_accessToken!, userData);
      print('✅ AuthService: Sign up (mock) successful');
      return AuthResult.success(userId);
    } catch (e) {
      print('❌ AuthService: Sign up failed - $e');
      return AuthResult.failure('Registration failed. Please try again.');
    }
  }

  // Sign in with email and password (backend-first with fallback)
  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      if (ApiConfig.useBackend) {
        final uri = Uri.parse(ApiConfig.authLoginUrl);
        final body = 'username=${Uri.encodeQueryComponent(email)}&password=${Uri.encodeQueryComponent(password)}';
        final resp = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': 'application/json',
          },
          body: body,
        );
        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          final data = json.decode(resp.body) as Map<String, dynamic>;
          final token = data['access_token']?.toString();
          if (token == null || token.isEmpty) {
            return AuthResult.failure('Invalid token from server.');
          }
          _accessToken = token;
          final user = data['user'] is Map<String, dynamic>
              ? data['user'] as Map<String, dynamic>
              : {
                  'id': data['user']?['id']?.toString() ?? 'unknown',
                  'email': email,
                  'username': email.split('@')[0],
                };
          _currentUser = user;
          _currentUserId = user['id']?.toString();
          await _saveAuth(_accessToken!, _currentUser!);
          print('✅ AuthService: Sign in (backend) successful');
          return AuthResult.success(_currentUserId);
        } else {
          print('⚠️ Backend login failed: ${resp.statusCode} ${resp.body}');
        }
      }

      // Fallback mock path
      await Future.delayed(const Duration(milliseconds: 600));
      if (email.isEmpty || password.isEmpty) {
        return AuthResult.failure('Please enter both email and password.');
      }
      final username = email.split('@')[0].replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
      final userId = 'demo_user_${DateTime.now().millisecondsSinceEpoch}';
      final userData = {
        'id': userId,
        'email': email,
        'username': username,
        'first_name': 'John',
        'last_name': 'Doe',
        'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        'hasCompletedOnboarding': true,
        'style_preferences': {
          'archetype': 'minimalist',
          'favorite_colors': ['black', 'white', 'navy', 'grey'],
          'preferred_styles': ['minimalist', 'casual', 'professional'],
        },
        'wardrobe_stats': {
          'total_items': 47,
          'total_value': 2500,
          'recently_added': 3,
        },
      };
      _currentUserId = userId;
      _currentUser = userData;
      _accessToken = 'demo_token_${DateTime.now().millisecondsSinceEpoch}';
      await _saveAuth(_accessToken!, userData);
      print('✅ AuthService: Sign in (mock) successful');
      return AuthResult.success(userId);
    } catch (e) {
      print('❌ AuthService: Sign in failed - $e');
      return AuthResult.failure('Invalid email or password.');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _clearStoredAuth();
      print('✅ AuthService: Sign out successful');
    } catch (e) {
      print('❌ AuthService: Sign out failed - $e');
    }
  }

  // Get current user ID
  String? getCurrentUserId() => _currentUserId;

  // Get current user info
  Map<String, dynamic>? getCurrentUser() => _currentUser;

  // Check if user is authenticated
  bool get isAuthenticated {
    if (_isLoading) {
      return false;
    }
    final isAuth = _currentUserId != null && _accessToken != null;
    print('🔧 AuthService: isAuthenticated check - Result: $isAuth');
    return isAuth;
  }

  // Get access token
  String? get accessToken => _accessToken;

  // Wait for initialization to complete
  Future<void> waitForInitialization() async {
    while (!_isInitialized) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  // Update onboarding status
  Future<void> updateOnboardingStatus(bool hasCompleted) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingKey, hasCompleted);

      if (_currentUser != null && _accessToken != null) {
        _currentUser!['hasCompletedOnboarding'] = hasCompleted;
        await _saveAuth(_accessToken!, _currentUser!);
        print('✅ AuthService: Updated onboarding status');
      }
    } catch (e) {
      print('❌ AuthService: Failed to update onboarding status - $e');
    }
  }

  // Check if onboarding is completed
  Future<bool> isOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final status = prefs.getBool(_onboardingKey) ?? false;
      return status;
    } catch (e) {
      return false;
    }
  }

  // Debug method to print current auth status
  Future<void> debugAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final onboardingStatus = prefs.getBool(_onboardingKey);
      print('🔍 AuthService: Debug - Current auth status:');
      print('   - Onboarding status: $onboardingStatus');
      print('   - User data: ${_currentUser != null ? 'exists' : 'null'}');
      print('   - Access token: ${_accessToken != null ? 'exists' : 'null'}');
      print('   - User ID: $_currentUserId');
      print('   - Is authenticated: $isAuthenticated');
      print('   - Is initialized: $_isInitialized');
      print('   - Is loading: $_isLoading');

      // Additional debug info
      if (_currentUser != null) {
        print('   - User email: ${_currentUser!['email']}');
        print('   - User username: ${_currentUser!['username']}');
        print(
          '   - User hasCompletedOnboarding: ${_currentUser!['hasCompletedOnboarding']}',
        );
      }
    } catch (e) {
      print('   - Error: $e');
    }
  }

  // Create demo user for testing
  Future<void> createDemoUser() async {
    try {
      final userId = 'demo_user_${DateTime.now().millisecondsSinceEpoch}';
      final userData = {
        'id': userId,
        'email': 'demo@fitsync.com',
        'username': 'demo_user',
        'first_name': 'Demo',
        'last_name': 'User',
        'avatar':
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        'hasCompletedOnboarding': true,
        'style_preferences': {
          'archetype': 'minimalist',
          'favorite_colors': ['black', 'white', 'navy'],
          'preferred_styles': ['minimalist', 'casual'],
        },
        'wardrobe_stats': {
          'total_items': 47,
          'total_value': 2500,
          'recently_added': 3,
        },
      };

      _currentUserId = userId;
      _currentUser = userData;
      _accessToken = 'demo_token_${DateTime.now().millisecondsSinceEpoch}';

      await _saveAuth(_accessToken!, userData);
      await updateOnboardingStatus(true);

      print('✅ AuthService: Demo user created successfully');
    } catch (e) {
      print('❌ AuthService: Failed to create demo user - $e');
    }
  }
}

class AuthResult {
  final bool isSuccess;
  final String? userId;
  final String? error;

  AuthResult.success(this.userId) : isSuccess = true, error = null;
  AuthResult.failure(this.error) : isSuccess = false, userId = null;
}

// Provider
final authServiceProvider = Provider((ref) => AuthService());
