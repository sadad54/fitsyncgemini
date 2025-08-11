import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitsyncgemini/services/MLAPI_service.dart';

class AuthService {
  String? _currentUserId;
  Map<String, dynamic>? _currentUser;

  // Current user stream
  Stream<String?> get authStateChanges {
    return Stream.value(_currentUserId);
  }

  // Sign up with email and password
  Future<AuthResult> signUpWithEmail(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    try {
      // Extract username from email (you can modify this logic)
      final username = email.split('@')[0];

      final result = await MLAPIService.registerUser(
        email: email,
        password: password,
        username: username,
        firstName: firstName,
        lastName: lastName,
      );

      _currentUserId = result['id'].toString();
      _currentUser = result;

      return AuthResult.success(_currentUserId!);
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  // Sign in with email and password
  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      await MLAPIService.loginUser(email: email, password: password);

      // Get user info after successful login
      final userInfo = await MLAPIService.getCurrentUser();
      _currentUserId = userInfo['id'].toString();
      _currentUser = userInfo;

      return AuthResult.success(_currentUserId!);
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  // Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      // For now, return a failure since Google Sign-In requires additional setup
      // You can implement this later with Firebase Auth or Google OAuth
      return AuthResult.failure('Google Sign-In not implemented yet');
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await MLAPIService.logout();
    } finally {
      _currentUserId = null;
      _currentUser = null;
    }
  }

  // Get current user ID
  String? getCurrentUserId() {
    return _currentUserId;
  }

  // Get current user info
  Map<String, dynamic>? getCurrentUser() {
    return _currentUser;
  }

  // Refresh current user info
  Future<Map<String, dynamic>?> refreshUserInfo() async {
    try {
      if (_currentUserId != null) {
        _currentUser = await MLAPIService.getCurrentUser();
        return _currentUser;
      }
      return null;
    } catch (e) {
      // If refresh fails, user might need to re-login
      _currentUserId = null;
      _currentUser = null;
      return null;
    }
  }

  // Check if user is authenticated
  bool get isAuthenticated => _currentUserId != null;
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
