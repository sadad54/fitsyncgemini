import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitsyncgemini/services/MLAPI_service.dart';
import 'dart:convert';

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
      // First, try to recover from MLAPIService if it has a token
      print('🔄 AuthService: Attempting to recover from MLAPIService first...');
      try {
        // Test if MLAPIService has a working token
        final userInfo = await MLAPIService.getCurrentUser();
        _currentUser = userInfo;
        _currentUserId = userInfo['id'].toString();

        // Get the token from MLAPIService
        _accessToken = MLAPIService.authToken;

        if (_accessToken != null) {
          print(
            '✅ AuthService: Successfully recovered auth data from MLAPIService',
          );
          // Try to save to SharedPreferences for future use (but don't rely on it)
          try {
            await _saveAuth(_accessToken!, userInfo);
          } catch (e) {
            print('⚠️ AuthService: Failed to save to SharedPreferences: $e');
          }
          return; // Successfully recovered, no need to check SharedPreferences
        } else {
          print('⚠️ AuthService: MLAPIService has user data but no token');
        }
      } catch (e) {
        print('❌ AuthService: Failed to recover from MLAPIService: $e');
      }

      // Fallback to SharedPreferences (mainly for mobile)
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString(_tokenKey);
      final userJson = prefs.getString(_userKey);

      print('🔍 AuthService: Debug - Raw SharedPreferences data:');
      print('  - Token key: $_tokenKey');
      print('  - User key: $_userKey');
      print(
        '  - Stored token: ${_accessToken != null ? 'exists (${_accessToken!.substring(0, 20)}...)' : 'null'}',
      );
      print(
        '  - Stored user JSON: ${userJson != null ? 'exists (${userJson.substring(0, 50)}...)' : 'null'}',
      );

      if (_accessToken != null && userJson != null) {
        _currentUser = json.decode(userJson);
        _currentUserId = _currentUser!['id'].toString();
        MLAPIService.setAuthToken(_accessToken!);

        print(
          '🔧 AuthService: Loaded stored auth from SharedPreferences - Token: ${_accessToken != null ? 'exists' : 'null'}, User: ${_currentUser != null ? 'exists' : 'null'}',
        );
      } else if (_accessToken != null && userJson == null) {
        // Token exists but user data is missing - try to get user data from API
        print(
          '🔄 AuthService: Token exists but user data missing, attempting to fetch user data...',
        );
        try {
          MLAPIService.setAuthToken(_accessToken!);
          final userInfo = await MLAPIService.getCurrentUser();
          _currentUser = userInfo;
          _currentUserId = userInfo['id'].toString();

          // Save the user data for future use
          await _saveAuth(_accessToken!, userInfo);

          print('✅ AuthService: Successfully recovered user data from API');
        } catch (e) {
          print('❌ AuthService: Failed to recover user data: $e');
          await _clearStoredAuth();
        }
      } else {
        print(
          '⚠️ AuthService: No auth data found in SharedPreferences or MLAPIService',
        );
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

    print('💾 AuthService: Saved auth data:');
    print('  - Token: ${token.substring(0, 20)}...');
    print('  - User: ${json.encode(user).substring(0, 50)}...');
  }

  Future<void> _clearStoredAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_onboardingKey); // Clear onboarding status too
    _accessToken = null;
    _currentUser = null;
    _currentUserId = null;
  }

  // Sign up with email and password
  Future<AuthResult> signUpWithEmail(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    try {
      final username = email
          .split('@')[0]
          .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');

      final result = await MLAPIService.registerUser(
        email: email,
        password: password,
        username: username,
        firstName: firstName,
        lastName: lastName,
      );

      _currentUserId = result['id'].toString();
      _currentUser = result;

      // After registration, user needs to login to get token
      return await signInWithEmail(email, password);
    } catch (e) {
      return AuthResult.failure(_parseError(e.toString()));
    }
  }

  // Sign in with email and password
  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      final result = await MLAPIService.loginUser(
        email: email,
        password: password,
      );

      _accessToken = result['access_token'];
      MLAPIService.setAuthToken(_accessToken!);

      // Try to get user info from the login response first
      if (result['user'] != null) {
        _currentUser = result['user'];
        _currentUserId = _currentUser!['id'].toString();
      } else {
        // Fallback: try to get user info via API call
        try {
          final userInfo = await MLAPIService.getCurrentUser();
          _currentUserId = userInfo['id'].toString();
          _currentUser = userInfo;
        } catch (apiError) {
          print(
            '⚠️ AuthService: Failed to get user info via API, using basic user data',
          );
          // Create basic user data from login response
          _currentUser = {
            'id': result['user_id'] ?? 'unknown',
            'email': email,
            'username': email.split('@')[0],
          };
          _currentUserId = _currentUser!['id'].toString();
        }
      }

      // Save to local storage
      await _saveAuth(_accessToken!, _currentUser!);

      print(
        '✅ AuthService: Sign in successful - Token: ${_accessToken != null ? 'exists' : 'null'}, User: ${_currentUser != null ? 'exists' : 'null'}, UserID: $_currentUserId',
      );

      return AuthResult.success(_currentUserId!);
    } catch (e) {
      print('❌ AuthService: Sign in failed - $e');
      return AuthResult.failure(_parseError(e.toString()));
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await MLAPIService.logout();
    } catch (e) {
      // Continue with logout even if API call fails
    } finally {
      await _clearStoredAuth();
    }
  }

  String _parseError(String error) {
    // Extract meaningful error messages
    if (error.contains('User with this email already exists')) {
      return 'An account with this email already exists';
    } else if (error.contains('Invalid email or password')) {
      return 'Invalid email or password';
    } else if (error.contains('Network error')) {
      return 'Network connection failed. Please check your internet connection.';
    } else if (error.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    return 'An unexpected error occurred. Please try again.';
  }

  // Get current user ID
  String? getCurrentUserId() => _currentUserId;

  // Get current user info
  Map<String, dynamic>? getCurrentUser() => _currentUser;

  // Check if user is authenticated
  bool get isAuthenticated {
    // If still loading, return false to avoid premature redirects
    if (_isLoading) {
      print(
        '🔧 AuthService: Still loading, returning false for isAuthenticated',
      );
      return false;
    }

    final isAuth = _currentUserId != null && _accessToken != null;
    print(
      '🔧 AuthService: isAuthenticated check - User: ${_currentUserId != null ? 'exists' : 'null'}, Token: ${_accessToken != null ? 'exists' : 'null'}, Result: $isAuth',
    );
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
        // Update the user data with onboarding status
        _currentUser!['hasCompletedOnboarding'] = hasCompleted;

        // Save updated user data to local storage
        await _saveAuth(_accessToken!, _currentUser!);

        // Optionally, you can also update this on the backend
        // await MLAPIService.updateUserProfile({'hasCompletedOnboarding': hasCompleted});
      }
    } catch (e) {
      // Don't throw error to avoid breaking the flow
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

  // Debug method to print current onboarding status
  Future<void> debugOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final status = prefs.getBool(_onboardingKey);
      print('🔍 AuthService: Debug - Current onboarding status:');
      print('   - SharedPreferences value: $status');
      print('   - User data value: ${_currentUser?['hasCompletedOnboarding']}');
      print('   - isAuthenticated: $isAuthenticated');
      print('   - Current user: ${_currentUser != null ? 'exists' : 'null'}');
      print('   - Access token: ${_accessToken != null ? 'exists' : 'null'}');
      print('   - User ID: $_currentUserId');
      print('   - Is initialized: $_isInitialized');
      print('   - Is loading: $_isLoading');
    } catch (e) {
      print('   - Error: $e');
    }
  }

  // Force refresh auth state from MLAPIService
  Future<bool> forceRefreshAuthState() async {
    try {
      print('🔄 AuthService: Force refreshing auth state from MLAPIService...');

      // Test if MLAPIService has a working token
      final userInfo = await MLAPIService.getCurrentUser();
      _currentUser = userInfo;
      _currentUserId = userInfo['id'].toString();

      // Get the token from MLAPIService
      _accessToken = MLAPIService.authToken;

      if (_accessToken != null) {
        print('✅ AuthService: Force refresh successful');
        // Try to save to SharedPreferences for future use
        try {
          await _saveAuth(_accessToken!, userInfo);
        } catch (e) {
          print('⚠️ AuthService: Failed to save to SharedPreferences: $e');
        }
        return true;
      } else {
        print('❌ AuthService: Force refresh failed - no token in MLAPIService');
        return false;
      }
    } catch (e) {
      print('❌ AuthService: Force refresh failed: $e');
      return false;
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
