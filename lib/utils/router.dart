// lib/utils/router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitsyncgemini/screens/splash/splash_screen.dart';
import 'package:fitsyncgemini/screens/auth/auth_screen.dart';
import 'package:fitsyncgemini/screens/onboarding/onboarding_screen.dart';
import 'package:fitsyncgemini/screens/quiz/quiz_screen.dart';
import 'package:fitsyncgemini/screens/dashboard/dashboard_screen.dart';
import 'package:fitsyncgemini/screens/closet/closet_screen.dart';
import 'package:fitsyncgemini/screens/trends/trends_screen.dart';
import 'package:fitsyncgemini/screens/nearby/nearby_screen.dart';
import 'package:fitsyncgemini/screens/try_on/try_on_screen.dart';
import 'package:fitsyncgemini/screens/explore/explore_screen.dart';
import 'package:fitsyncgemini/screens/settings/settings_screen.dart';
import 'package:fitsyncgemini/screens/outfit_suggestions/outfit_suggestions_screen.dart';
import 'package:fitsyncgemini/providers/providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authViewModelProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final hasCompletedOnboarding = authState.hasCompletedOnboarding;
      final isGoingToAuth = state.uri.toString() == '/auth';
      final isGoingToSplash = state.uri.toString() == '/splash';
      final isGoingToOnboarding = state.uri.toString() == '/onboarding';
      final isGoingToQuiz = state.uri.toString() == '/quiz';
      final isGoingToDashboard = state.uri.toString() == '/dashboard';

      // Debug prints
      print('🔍 Router Debug:');
      print('  - Current location: ${state.uri}');
      print('  - isAuthenticated: $isAuthenticated');
      print('  - hasCompletedOnboarding: $hasCompletedOnboarding');
      print('  - isGoingToAuth: $isGoingToAuth');
      print('  - isGoingToSplash: $isGoingToSplash');
      print('  - isGoingToOnboarding: $isGoingToOnboarding');
      print('  - isGoingToQuiz: $isGoingToQuiz');
      print('  - isGoingToDashboard: $isGoingToDashboard');

      // Special handling for splash screen - if authenticated and completed onboarding, go to dashboard
      if (isGoingToSplash && isAuthenticated && hasCompletedOnboarding) {
        print(
          '  ➡️ Redirecting from splash to dashboard (authenticated and completed onboarding)',
        );
        return '/dashboard';
      }

      // If not authenticated and not going to auth/splash/onboarding/quiz, redirect to auth
      if (!isAuthenticated &&
          !isGoingToAuth &&
          !isGoingToSplash &&
          !isGoingToOnboarding &&
          !isGoingToQuiz) {
        print('  ➡️ Redirecting to /auth (not authenticated)');
        return '/auth';
      }

      // If authenticated but hasn't completed onboarding and not going to onboarding/quiz, redirect to onboarding
      if (isAuthenticated &&
          !hasCompletedOnboarding &&
          !isGoingToOnboarding &&
          !isGoingToQuiz &&
          !isGoingToSplash) {
        print('  ➡️ Redirecting to /onboarding (not completed onboarding)');
        return '/onboarding';
      }

      // If authenticated and has completed onboarding and going to auth/splash/onboarding, redirect to dashboard
      // But don't redirect if they're already going to dashboard or quiz (quiz completion flow)
      if (isAuthenticated &&
          hasCompletedOnboarding &&
          (isGoingToAuth || isGoingToSplash || isGoingToOnboarding) &&
          !isGoingToDashboard &&
          !isGoingToQuiz) {
        print(
          '  ➡️ Redirecting to /dashboard (authenticated and completed onboarding)',
        );
        return '/dashboard';
      }

      print('  ✅ No redirect needed');
      return null; // No redirect
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
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
      GoRoute(
        path: '/closet',
        builder: (context, state) => const ClosetScreen(),
      ),
      GoRoute(
        path: '/trends',
        builder: (context, state) => const TrendsScreen(),
      ),
      GoRoute(
        path: '/nearby',
        builder: (context, state) => const NearbyScreen(),
      ),
      GoRoute(
        path: '/try-on',
        builder: (context, state) => const TryOnScreen(),
      ),
      GoRoute(
        path: '/explore',
        builder: (context, state) => const ExploreScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/outfit-suggestions',
        builder: (context, state) => const OutfitSuggestionsScreen(),
      ),
      // Individual outfit view
      GoRoute(
        path: '/outfit/:id',
        builder: (context, state) {
          final outfitId = state.pathParameters['id']!;
          return OutfitDetailScreen(outfitId: outfitId);
        },
      ),
      // Individual clothing item view
      GoRoute(
        path: '/item/:id',
        builder: (context, state) {
          final itemId = state.pathParameters['id']!;
          return ClothingItemDetailScreen(itemId: itemId);
        },
      ),
      // Profile view
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
    errorBuilder:
        (context, state) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Page Not Found',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'The page you\'re looking for doesn\'t exist.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/dashboard'),
                  child: const Text('Go Home'),
                ),
              ],
            ),
          ),
        ),
  );
});

// Placeholder screens for new routes
class OutfitDetailScreen extends StatelessWidget {
  final String outfitId;

  const OutfitDetailScreen({super.key, required this.outfitId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Outfit Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.checkroom, size: 64),
            const SizedBox(height: 16),
            Text('Outfit ID: $outfitId'),
            const SizedBox(height: 8),
            const Text('Outfit details will be displayed here'),
          ],
        ),
      ),
    );
  }
}

class ClothingItemDetailScreen extends StatelessWidget {
  final String itemId;

  const ClothingItemDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_bag, size: 64),
            const SizedBox(height: 16),
            Text('Item ID: $itemId'),
            const SizedBox(height: 8),
            const Text('Clothing item details will be displayed here'),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 64),
            SizedBox(height: 16),
            Text('User Profile'),
            SizedBox(height: 8),
            Text('Profile details will be displayed here'),
          ],
        ),
      ),
    );
  }
}
