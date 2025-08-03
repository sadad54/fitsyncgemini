import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class AuthViewModel extends StateNotifier<AuthState> {
  AuthViewModel() : super(const AuthState(isAuthenticated: false));

  void signIn(String userName, String userId) {
    state = AuthState(
      isAuthenticated: true,
      userName: userName,
      userId: userId,
    );
  }

  void signOut() {
    state = const AuthState(isAuthenticated: false);
  }
}

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>(
  (ref) => AuthViewModel(),
);
