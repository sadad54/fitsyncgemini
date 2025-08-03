// lib/utils/router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fitsyncgemini/screens/splash/splash_screen.dart';
import 'package:fitsyncgemini/screens/auth/auth_screen.dart';
import 'package:fitsyncgemini/screens/onboarding/onboarding_screen.dart';
import 'package:fitsyncgemini/screens/quiz/quiz_screen.dart';
import 'package:fitsyncgemini/screens/dashboard/dashboard_screen.dart';
import 'package:fitsyncgemini/screens/closet/closet_screen.dart';

final router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(path: '/quiz', builder: (context, state) => const QuizScreen()),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(path: '/closet', builder: (context, state) => const ClosetScreen()),

    // Define other routes for trends, nearby, etc. as needed
    // GoRoute(
    //   path: '/trends',
    //   builder: (context, state) => const TrendsScreen(),
    // ),
  ],
);
