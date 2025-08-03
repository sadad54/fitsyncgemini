// lib/screens/splash/splash_screen.dart
import 'dart:async';
import 'package:fitsyncgemini/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fitsyncgemini/widgets/common/gradient_button.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _progress = 0;
  Timer? _timer;
  final List<String> _loadingMessages = [
    "Initializing AI models...",
    "Loading fashion database...",
    "Preparing your experience...",
    "Ready to sync your style!",
  ];
  String _currentMessage = "Initializing AI models...";

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  void _startLoading() {
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        if (_progress >= 1) {
          _timer?.cancel();
          context.go('/auth');
        } else {
          _progress += 0.02;
          if (_progress >= 0.9) {
            _currentMessage = _loadingMessages[3];
          } else if (_progress >= 0.6) {
            _currentMessage = _loadingMessages[2];
          } else if (_progress >= 0.3) {
            _currentMessage = _loadingMessages[1];
          }
        }
      });
    });
  }

  void _skip() {
    _timer?.cancel();
    context.go('/auth');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Stack(
          children: [
            _buildAnimatedBackground(),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/fitSyncLogo.png',
                    width: 200,
                    height: 200,
                  ).animate().fade(duration: 1.seconds).scale(),
                  const SizedBox(height: 24),
                  const Text(
                    'Your AI-Powered Fashion Companion',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: 8),
                  const Text(
                    'Discover • Organize • Style',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ).animate().fadeIn(delay: 700.ms),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: 250,
                    child: Column(
                      children: [
                        LinearProgressIndicator(
                          value: _progress,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          minHeight: 5,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _currentMessage,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 50,
              right: 20,
              child: TextButton(
                onPressed: _skip,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Colors.white54),
                  ),
                ),
                child: const Text('Skip'),
              ),
            ),
            const Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Text(
                'Powered by Advanced AI & Machine Learning',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Stack(
          children: [
            Positioned(
              top: 100,
              left: 40,
              child: _blurryCircle(100, Colors.white10),
            ),
            Positioned(
              top: 200,
              right: 50,
              child: _blurryCircle(80, Colors.white10),
            ),
            Positioned(
              bottom: 150,
              left: 80,
              child: _blurryCircle(60, Colors.white12),
            ),
            Positioned(
              bottom: 80,
              right: 90,
              child: _blurryCircle(90, Colors.white12),
            ),
          ],
        )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: 5.seconds,
          colors: [
            Colors.transparent,
            Colors.white.withOpacity(0.05),
            Colors.transparent,
          ],
        );
  }

  Widget _blurryCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
