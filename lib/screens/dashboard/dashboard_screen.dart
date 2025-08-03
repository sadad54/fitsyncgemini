// lib/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fitsyncgemini/constants/app_colors.dart';
import 'package:fitsyncgemini/constants/app_data.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        title: Row(
          children: [
            Image.asset('assets/images/fitSyncLogo.png', width: 32, height: 32),
            const SizedBox(width: 8),
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
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.smartphone, size: 20),
            onPressed: () => context.go('/mockups'),
          ),
          IconButton(
            icon: const Icon(LucideIcons.palette, size: 20),
            onPressed: () => context.go('/assets'),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0, left: 8.0),
            child: CircleAvatar(
              radius: 16,
              child: Text(
                'JS',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: AppColors.pink,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    _buildFeatureCard(
                      context,
                      icon: LucideIcons.shoppingBag,
                      title: 'My Closet',
                      subtitle: '${sampleCloset.length} items',
                      gradient: const LinearGradient(
                        colors: [AppColors.pink, AppColors.purple],
                      ),
                      onTap: () => context.go('/closet'),
                    ),
                    _buildFeatureCard(
                      context,
                      icon: LucideIcons.sparkles,
                      title: 'Outfit AI',
                      subtitle: 'Get suggestions',
                      gradient: const LinearGradient(
                        colors: [AppColors.purple, AppColors.teal],
                      ),
                      onTap: () {},
                    ),
                    _buildFeatureCard(
                      context,
                      icon: LucideIcons.trendingUp,
                      title: 'Trends',
                      subtitle: 'What\'s hot now',
                      gradient: const LinearGradient(
                        colors: [AppColors.teal, AppColors.blue],
                      ),
                      onTap: () {},
                    ),
                    _buildFeatureCard(
                      context,
                      icon: LucideIcons.mapPin,
                      title: 'Nearby',
                      subtitle: 'Local inspiration',
                      gradient: const LinearGradient(
                        colors: [AppColors.blue, AppColors.pink],
                      ),
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSuggestionCard(context),
                const SizedBox(height: 16),
                _buildStyleDnaCard(context),
              ]
              .animate(interval: 100.ms)
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.2),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: gradient,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(BuildContext context) {
    final outfit = sampleOutfits.first;
    return Card(
      color: AppColors.pink.withOpacity(0.05),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    gradient: AppColors.fitsyncGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.zap,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Today\'s Outfit Suggestion',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 80,
                  height: 48,
                  child: Stack(
                    children:
                        outfit.items.take(3).toList().asMap().entries.map((
                          entry,
                        ) {
                          final index = entry.key;
                          final item = entry.value;
                          return Positioned(
                            left: (index * 20).toDouble(),
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: Theme.of(context).cardColor,
                              child: CircleAvatar(
                                radius: 22,
                                backgroundImage: NetworkImage(item.image),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        outfit.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Perfect for ${outfit.occasion}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    foregroundColor: Colors.white,
                    backgroundColor: AppColors.pink,
                  ),
                  child: const Text('Try On'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleDnaCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(LucideIcons.star, color: AppColors.gold, size: 20),
                SizedBox(width: 8),
                Text(
                  'Your Style DNA',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    gradient: AppColors.quizGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('✨', style: TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Minimalist',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Clean lines, neutral colors, timeless pieces',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children:
                            ['Neutral Colors', 'Clean Lines', 'Timeless']
                                .map(
                                  (trait) => Chip(
                                    label: Text(trait),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    labelStyle:
                                        Theme.of(context).textTheme.bodySmall,
                                    backgroundColor:
                                        Theme.of(
                                          context,
                                        ).scaffoldBackgroundColor,
                                  ),
                                )
                                .toList(),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(onPressed: () {}, child: const Text('Explore')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
