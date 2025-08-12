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

  void _checkInitialAuthState() {
    final isAuth = _authService.isAuthenticated;
    final user = _authService.getCurrentUser();

    if (isAuth && user != null) {
      state = AuthState(
        isAuthenticated: true,
        userId: user['id'].toString(),
        userName: user['username'],
        email: user['email'],
        hasCompletedOnboarding:
            user['hasCompletedOnboarding'] ?? false, // Check from user data
      );
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
      final result = await _authService.signUpWithEmail(
        email,
        password,
        firstName,
        lastName,
      );

      if (result.isSuccess) {
        final user = _authService.getCurrentUser();
        state = AuthState(
          isAuthenticated: true,
          userId: result.userId!,
          userName: user?['username'],
          email: email,
          hasCompletedOnboarding:
              false, // New users haven't completed onboarding
        );
      } else {
        state = state.copyWith(isLoading: false, error: result.error);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authService.signInWithEmail(email, password);

      if (result.isSuccess) {
        final user = _authService.getCurrentUser();
        state = AuthState(
          isAuthenticated: true,
          userId: result.userId!,
          userName: user?['username'],
          email: email,
          hasCompletedOnboarding:
              user?['hasCompletedOnboarding'] ?? false, // Check from user data
        );
      } else {
        state = state.copyWith(isLoading: false, error: result.error);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Add method to mark onboarding as completed
  Future<void> completeOnboarding() async {
    try {
      // Update the user's onboarding status in the backend
      await _authService.updateOnboardingStatus(true);

      // Update local state
      state = state.copyWith(hasCompletedOnboarding: true);
    } catch (e) {
      // Handle error if needed
      print('Error updating onboarding status: $e');
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
