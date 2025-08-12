// lib/screens/auth/auth_screen.dart
import 'package:fitsyncgemini/viewmodels/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fitsyncgemini/constants/app_colors.dart';
import 'package:fitsyncgemini/widgets/common/gradient_button.dart';
import 'package:fitsyncgemini/widgets/common/social_button.dart';
import 'package:fitsyncgemini/widgets/common/custom_text_field.dart';
import 'package:fitsyncgemini/services/auth_service.dart';

enum AuthMode { login, signup }

extension AuthModeExtension on AuthMode {
  bool get isLogin => this == AuthMode.login;
}

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  AuthMode _authMode = AuthMode.login;
  bool _showPassword = false;
  bool _isLoading = false;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _authMode =
          _authMode == AuthMode.login ? AuthMode.signup : AuthMode.login;
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _showPassword = !_showPassword;
    });
  }

  void _submit() async {
    if (_isLoading) return;

    // Basic validation
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showErrorSnackBar('Please fill in all required fields');
      return;
    }

    if (!_authMode.isLogin &&
        (_firstNameController.text.trim().isEmpty ||
            _lastNameController.text.trim().isEmpty)) {
      _showErrorSnackBar('Please fill in your name');
      return;
    }

    if (!_authMode.isLogin &&
        _passwordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authViewModel = ref.read(authViewModelProvider.notifier);

      if (_authMode == AuthMode.login) {
        await authViewModel.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await authViewModel.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
        );
      }

      // Check if authentication was successful
      final authState = ref.read(authViewModelProvider);
      if (authState.isAuthenticated && mounted) {
        // Check if user has completed onboarding
        if (authState.hasCompletedOnboarding) {
          context.go('/dashboard');
        } else {
          context.go('/onboarding');
        }
      } else if (authState.error != null) {
        _showErrorSnackBar(authState.error!);
      }
    } catch (e) {
      _showErrorSnackBar('Network error. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLogin = _authMode == AuthMode.login;
    final authState = ref.watch(authViewModelProvider);
    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      if (next.isAuthenticated && mounted) {
        // Check if user has completed onboarding
        if (next.hasCompletedOnboarding) {
          context.go('/dashboard');
        } else {
          context.go('/onboarding');
        }
      } else if (next.error != null && mounted) {
        _showErrorSnackBar(next.error!);
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/fitSyncLogo.png', width: 40, height: 40),
            const SizedBox(width: 12),
            Text(
              'FitSync',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                foreground:
                    Paint()
                      ..shader = AppColors.fitsyncGradient.createShader(
                        const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0),
                      ),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isLogin ? 'Welcome Back!' : 'Join FitSync',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isLogin
                        ? 'Sign in to sync your style'
                        : 'Create your fashion profile',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (!isLogin) ...[
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _firstNameController,
                            hintText: 'First name',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: _lastNameController,
                            hintText: 'Last name',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  CustomTextField(
                    controller: _emailController,
                    hintText: 'Email address',
                    prefixIcon: LucideIcons.mail,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _passwordController,
                    hintText: 'Password',
                    prefixIcon: LucideIcons.lock,
                    obscureText: !_showPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                        color: Colors.grey,
                        size: 20,
                      ),
                      onPressed: _togglePasswordVisibility,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (!isLogin) ...[
                    CustomTextField(
                      controller: _confirmPasswordController,
                      hintText: 'Confirm password',
                      prefixIcon: LucideIcons.lock,
                      obscureText: true,
                    ),
                    const SizedBox(height: 24),
                  ],

                  GradientButton(
                    onPressed: _isLoading ? null : _submit,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isLoading) ...[
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isLogin ? 'Signing In...' : 'Creating Account...',
                          ),
                        ] else ...[
                          Text(isLogin ? 'Sign In' : 'Create Account'),
                          const SizedBox(width: 8),
                          const Icon(LucideIcons.arrowRight, size: 16),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  _buildSeparator(context),
                  const SizedBox(height: 24),
                  const SocialButton(),
                  const SizedBox(height: 24),

                  TextButton(
                    onPressed: _toggleAuthMode,
                    child: Text(
                      isLogin
                          ? "Don't have an account? Sign up"
                          : "Already have an account? Sign in",
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeparator(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'Or continue with',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
