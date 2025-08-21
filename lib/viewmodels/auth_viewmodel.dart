import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitsyncgemini/services/auth_service.dart';

// === State ===
class AuthState {
  final bool isAuthenticated;
  final String? userName;
  final String? userId;
  final String? email;
  final bool isLoading;
  final String? error;
  final bool hasCompletedOnboarding; // Add this field

  const AuthState({
    required this.isAuthenticated,
    this.userName,
    this.userId,
    this.email,
    this.isLoading = false,
    this.error,
    this.hasCompletedOnboarding = false, // Add this field
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? userName,
    String? userId,
    String? email,
    bool? isLoading,
    String? error,
    bool? hasCompletedOnboarding, // Add this field
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userName: userName ?? this.userName,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      hasCompletedOnboarding:
          hasCompletedOnboarding ??
          this.hasCompletedOnboarding, // Add this field
    );
  }
}

// === ViewModel ===
class AuthViewModel extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthViewModel(this._authService)
    : super(const AuthState(isAuthenticated: false)) {
    _checkInitialAuthState();
  }

  Future<void> _checkInitialAuthState() async {
    print('🔄 AuthViewModel: Starting initial auth state check...');
    try {
      // Wait for AuthService to initialize
      await _authService.waitForInitialization();

      final isAuth = _authService.isAuthenticated;
      final user = _authService.getCurrentUser();
      final hasCompletedOnboarding = await _authService.isOnboardingCompleted();

      print('🔍 AuthViewModel: Auth state check results:');
      print('  - isAuth: $isAuth');
      print('  - user: ${user != null ? 'exists' : 'null'}');
      print('  - hasCompletedOnboarding: $hasCompletedOnboarding');

      if (isAuth && user != null) {
        state = AuthState(
          isAuthenticated: true,
          userId: user['id'].toString(),
          userName: user['username'],
          email: user['email'],
          hasCompletedOnboarding: hasCompletedOnboarding,
        );
        print('✅ AuthViewModel: User is authenticated and state updated');
      } else {
        print('ℹ️ AuthViewModel: User is not authenticated');
      }
    } catch (e) {
      print('❌ AuthViewModel: Error checking initial auth state: $e');
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Wait for AuthService to initialize
      await _authService.waitForInitialization();

      final result = await _authService.signUpWithEmail(
        email,
        password,
        firstName,
        lastName,
      );

      if (result.isSuccess) {
        final user = _authService.getCurrentUser();
        final hasCompletedOnboarding =
            await _authService.isOnboardingCompleted();

        state = AuthState(
          isAuthenticated: true,
          userId: result.userId!,
          userName: user?['username'],
          email: email,
          hasCompletedOnboarding: hasCompletedOnboarding,
        );
      } else {
        state = state.copyWith(isLoading: false, error: result.error);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    print('🔄 AuthViewModel: Starting sign in for $email');
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Wait for AuthService to initialize
      await _authService.waitForInitialization();

      final result = await _authService.signInWithEmail(email, password);

      if (result.isSuccess) {
        print('✅ AuthViewModel: Sign in successful');
        final user = _authService.getCurrentUser();
        final hasCompletedOnboarding =
            await _authService.isOnboardingCompleted();

        print('🔍 AuthViewModel: After sign in:');
        print('  - user: ${user != null ? 'exists' : 'null'}');
        print('  - hasCompletedOnboarding: $hasCompletedOnboarding');

        state = AuthState(
          isAuthenticated: true,
          userId: result.userId!,
          userName: user?['username'],
          email: email,
          hasCompletedOnboarding: hasCompletedOnboarding,
        );
        print('✅ AuthViewModel: Auth state updated after sign in');
      } else {
        print('❌ AuthViewModel: Sign in failed: ${result.error}');
        state = state.copyWith(isLoading: false, error: result.error);
      }
    } catch (e) {
      print('❌ AuthViewModel: Sign in error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Add method to mark onboarding as completed
  Future<void> completeOnboarding() async {
    print('🔄 AuthViewModel: Starting completeOnboarding...');
    try {
      // Update the user's onboarding status in the backend
      print('💾 AuthViewModel: Updating onboarding status in AuthService...');
      await _authService.updateOnboardingStatus(true);

      // Update local state - preserve existing auth state
      print('📊 AuthViewModel: Updating local state...');
      state = state.copyWith(
        hasCompletedOnboarding: true,
        // Ensure we preserve the authenticated state
        isAuthenticated: true,
      );
      print('✅ AuthViewModel: Onboarding completed successfully');
      print(
        '   - New state: isAuthenticated=${state.isAuthenticated}, hasCompletedOnboarding=${state.hasCompletedOnboarding}',
      );
    } catch (e) {
      // Handle error if needed
      print('❌ AuthViewModel: Error updating onboarding status: $e');
    }
  }

  // Force refresh authentication state
  Future<void> refreshAuthState() async {
    print('🔄 AuthViewModel: Refreshing auth state...');
    try {
      // Wait for AuthService to initialize
      await _authService.waitForInitialization();

      final isAuth = _authService.isAuthenticated;
      final user = _authService.getCurrentUser();
      final hasCompletedOnboarding = await _authService.isOnboardingCompleted();

      print('🔍 AuthViewModel: Refresh results:');
      print('  - isAuth: $isAuth');
      print('  - user: ${user != null ? 'exists' : 'null'}');
      print('  - hasCompletedOnboarding: $hasCompletedOnboarding');

      if (isAuth && user != null) {
        state = AuthState(
          isAuthenticated: true,
          userId: user['id'].toString(),
          userName: user['username'],
          email: user['email'],
          hasCompletedOnboarding: hasCompletedOnboarding,
        );
        print('✅ AuthViewModel: Auth state refreshed successfully');
      } else {
        print('⚠️ AuthViewModel: User not authenticated during refresh');
      }
    } catch (e) {
      print('❌ AuthViewModel: Error refreshing auth state: $e');
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = const AuthState(isAuthenticated: false);
  }
}

// === Provider ===
final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>(
  (ref) => AuthViewModel(ref.read(authServiceProvider)),
);
