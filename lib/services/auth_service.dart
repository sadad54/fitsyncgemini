import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitsyncgemini/services/MLAPI_service.dart';
import 'dart:convert';

class AuthService {
  String? _currentUserId;
  Map<String, dynamic>? _currentUser;
  String? _accessToken;

  static const String _tokenKey = 'access_token';
  static const String _userKey = 'user_data';

  AuthService() {
    _loadStoredAuth();
  }

  Future<void> _loadStoredAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString(_tokenKey);
      final userJson = prefs.getString(_userKey);

      if (_accessToken != null && userJson != null) {
        _currentUser = json.decode(userJson);
        _currentUserId = _currentUser!['id'].toString();
        MLAPIService.setAuthToken(_accessToken!);

        // Verify token is still valid by trying to get current user
        try {
          final userInfo = await MLAPIService.getCurrentUser();
          _currentUser = userInfo;
          await _saveAuth(_accessToken!, _currentUser!);
        } catch (e) {
          // Token expired or invalid, clear stored data
          await _clearStoredAuth();
        }
      }
    } catch (e) {
      await _clearStoredAuth();
    }
  }

  Future<void> _saveAuth(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, json.encode(user));
  }

  Future<void> _clearStoredAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
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

      // Get user info after successful login
      final userInfo = await MLAPIService.getCurrentUser();
      _currentUserId = userInfo['id'].toString();
      _currentUser = userInfo;

      // Save to local storage
      await _saveAuth(_accessToken!, _currentUser!);

      return AuthResult.success(_currentUserId!);
    } catch (e) {
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
  bool get isAuthenticated => _currentUserId != null && _accessToken != null;

  // Get access token
  String? get accessToken => _accessToken;

  // Update onboarding status
  Future<void> updateOnboardingStatus(bool hasCompleted) async {
    try {
      if (_currentUser != null && _accessToken != null) {
        // Update the user data with onboarding status
        _currentUser!['hasCompletedOnboarding'] = hasCompleted;

        // Save updated user data to local storage
        await _saveAuth(_accessToken!, _currentUser!);

        // Optionally, you can also update this on the backend
        // await MLAPIService.updateUserProfile({'hasCompletedOnboarding': hasCompleted});
      }
    } catch (e) {
      print('Error updating onboarding status: $e');
      // Don't throw error to avoid breaking the flow
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
