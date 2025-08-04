// lib/viewmodels/auth_viewmodel.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// === State ===
class AuthState {
  final bool isAuthenticated;
  final String? userName;
  final String? userId;

  const AuthState({required this.isAuthenticated, this.userName, this.userId});

  AuthState copyWith({
    bool? isAuthenticated,
    String? userName,
    String? userId,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userName: userName ?? this.userName,
      userId: userId ?? this.userId,
    );
  }
}

// === ViewModel ===
class AuthViewModel extends StateNotifier<AuthState> {
  AuthViewModel() : super(const AuthState(isAuthenticated: false)) {
    // 🔄 Listen to Firebase auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        // User is logged in (anonymous or otherwise)
        state = AuthState(
          isAuthenticated: true,
          userId: user.uid,
          userName: user.displayName ?? 'User',
        );
      } else {
        // User signed out
        state = const AuthState(isAuthenticated: false);
      }
    });
  }

  // 🔓 Sign in anonymously (perfect for onboarding)
  Future<void> signInAnonymously() async {
    try {
      await FirebaseAuth.instance.signInAnonymously();
      // State will update automatically via listener
    } catch (e) {
      print("Anonymous sign-in failed: $e");
    }
  }

  // 🚪 Optional: Sign out
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}

// === Provider ===
final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>(
  (ref) => AuthViewModel(),
);
