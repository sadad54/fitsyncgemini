import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../config/supabase_config.dart';

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
      // Prefer Supabase session
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null && session.accessToken.isNotEmpty) {
        _accessToken = session.accessToken;
        final u = session.user;
        _currentUser = {
          'id': u.id,
          'email': u.email,
          'username': u.userMetadata?['username'] ?? u.email?.split('@').first,
          'first_name': u.userMetadata?['first_name'],
          'last_name': u.userMetadata?['last_name'],
        };
        _currentUserId = u.id;
        await _saveAuth(_accessToken!, _currentUser!);
        print('✅ AuthService: Loaded Supabase session');
        return;
      }

      // Fallback to stored values
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

  // Sign up with Supabase
  Future<AuthResult> signUpWithEmail(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    try {
      print('🔄 AuthService: Starting Supabase signup for $email');
      final res = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'username': email.split('@')[0],
        },
      );
      print('🔍 AuthService: Supabase signup response:');
      print('  - Session: ${res.session != null ? 'exists' : 'null'}');
      print('  - User: ${res.user != null ? 'exists' : 'null'}');
      print(
        '  - Email confirmed: ${res.user?.emailConfirmedAt != null ? 'yes' : 'no'}',
      );

      final session = res.session;
      final user = res.user;
      if (user == null) {
        return AuthResult.failure('Registration failed - no user returned');
      }

      // Check if email confirmation is required
      if (user.emailConfirmedAt == null) {
        print('⚠️ AuthService: Email confirmation required');
        return AuthResult.failure(
          'Please check your email and confirm your account before signing in.',
        );
      }

      if (session == null) {
        return AuthResult.failure('Registration failed - no session returned');
      }

      _accessToken = session.accessToken;
      _currentUserId = user.id;
      _currentUser = {
        'id': user.id,
        'email': user.email,
        'username':
            user.userMetadata?['username'] ?? user.email?.split('@').first,
        'first_name': user.userMetadata?['first_name'],
        'last_name': user.userMetadata?['last_name'],
      };
      await _saveAuth(_accessToken!, _currentUser!);
      print('✅ AuthService: Sign up successful (Supabase)');
      return AuthResult.success(user.id);
    } catch (e) {
      print('❌ AuthService: Sign up failed - $e');
      print('❌ AuthService: Error type: ${e.runtimeType}');
      if (e.toString().contains('Email not confirmed')) {
        return AuthResult.failure(
          'Please check your email and confirm your account before signing in.',
        );
      }
      return AuthResult.failure('Registration failed. Please try again.');
    }
  }

  // Sign in with Supabase
  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      print('🔄 AuthService: Starting Supabase signin for $email');
      if (email.isEmpty || password.isEmpty) {
        return AuthResult.failure('Please enter both email and password.');
      }
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      print('🔍 AuthService: Supabase signin response:');
      print('  - Session: ${res.session != null ? 'exists' : 'null'}');
      print('  - User: ${res.user != null ? 'exists' : 'null'}');
      print(
        '  - Email confirmed: ${res.user?.emailConfirmedAt != null ? 'yes' : 'no'}',
      );

      final session = res.session;
      final user = res.user;
      if (session == null || user == null) {
        return AuthResult.failure('Invalid email or password.');
      }
      _accessToken = session.accessToken;
      _currentUserId = user.id;
      _currentUser = {
        'id': user.id,
        'email': user.email,
        'username':
            user.userMetadata?['username'] ?? user.email?.split('@').first,
        'first_name': user.userMetadata?['first_name'],
        'last_name': user.userMetadata?['last_name'],
      };
      await _saveAuth(_accessToken!, _currentUser!);
      print('✅ AuthService: Sign in successful (Supabase)');
      return AuthResult.success(user.id);
    } catch (e) {
      print('❌ AuthService: Sign in failed - $e');
      print('❌ AuthService: Error type: ${e.runtimeType}');
      if (e.toString().contains('Email not confirmed')) {
        return AuthResult.failure(
          'Please check your email and confirm your account before signing in.',
        );
      }
      return AuthResult.failure('Invalid email or password.');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
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
    final supa = Supabase.instance.client.auth.currentSession;
    final isAuth =
        (supa != null && supa.accessToken.isNotEmpty) ||
        (_currentUserId != null && _accessToken != null);
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

  // Test Supabase connection
  Future<void> testSupabaseConnection() async {
    try {
      print('🔍 AuthService: Testing Supabase connection...');
      final client = Supabase.instance.client;
      print('  - Client initialized: ${client != null}');
      print('  - URL: ${SupabaseConfig.supabaseUrl}');
      print(
        '  - Current session: ${client.auth.currentSession != null ? 'exists' : 'null'}',
      );

      // Test a simple query to see if connection works
      final response = await client.from('users').select('count').limit(1);
      print('  - Database connection: ✅');
    } catch (e) {
      print('  - Database connection: ❌ $e');
    }
  }

  // Create a test user without email confirmation (for development)
  Future<AuthResult> createTestUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      print('🔄 AuthService: Creating test user for $email');

      // First, try to sign up
      final res = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'username': email.split('@')[0],
        },
      );

      print('🔍 AuthService: Test user signup response:');
      print('  - Session: ${res.session != null ? 'exists' : 'null'}');
      print('  - User: ${res.user != null ? 'exists' : 'null'}');
      print(
        '  - Email confirmed: ${res.user?.emailConfirmedAt != null ? 'yes' : 'no'}',
      );

      // For testing, we'll try to sign in immediately even if email not confirmed
      if (res.user != null) {
        try {
          final signInRes = await Supabase.instance.client.auth
              .signInWithPassword(email: email, password: password);

          if (signInRes.session != null && signInRes.user != null) {
            _accessToken = signInRes.session!.accessToken;
            _currentUserId = signInRes.user!.id;
            _currentUser = {
              'id': signInRes.user!.id,
              'email': signInRes.user!.email,
              'username':
                  signInRes.user!.userMetadata?['username'] ??
                  signInRes.user!.email?.split('@').first,
              'first_name': signInRes.user!.userMetadata?['first_name'],
              'last_name': signInRes.user!.userMetadata?['last_name'],
            };
            await _saveAuth(_accessToken!, _currentUser!);
            print(
              '✅ AuthService: Test user created and signed in successfully',
            );
            return AuthResult.success(signInRes.user!.id);
          }
        } catch (signInError) {
          print(
            '⚠️ AuthService: Could not sign in test user immediately: $signInError',
          );
          return AuthResult.failure(
            'Account created but email confirmation may be required. Please check your email.',
          );
        }
      }

      return AuthResult.failure('Failed to create test user');
    } catch (e) {
      print('❌ AuthService: Test user creation failed - $e');
      return AuthResult.failure('Failed to create test user: $e');
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
