// lib/widgets/onboarding/onboarding_illustration.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fitsyncgemini/constants/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OnboardingIllustration extends StatelessWidget {
  final String type;
  const OnboardingIllustration({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case 'smartWardrobe':
        return _buildSmartWardrobe();
      case 'aiSuggestions':
        return _buildAiSuggestions();
      case 'weatherSmart':
        return _buildWeatherSmart();
      case 'socialShare':
        return _buildSocialShare();
      default:
        return _buildSmartWardrobe();
    }
  }

  Widget _buildSmartWardrobe() {
    return Container(
      width: 200,
      height: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.fitsyncGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.pink.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: const [
            _ClothingItem(color: AppColors.pink, emoji: '👕'),
            _ClothingItem(color: AppColors.teal, emoji: '👖'),
            _ClothingItem(color: AppColors.purple, emoji: '👗'),
            _ClothingItem(color: AppColors.blue, emoji: '👟'),
          ],
        ),
      ),
    ).animate().slideY(begin: 0.2, duration: 600.ms, curve: Curves.easeOut);
  }

  Widget _buildAiSuggestions() {
    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _ClothingItem(color: AppColors.pink, emoji: '👕')
              .animate(delay: 200.ms)
              .move(begin: const Offset(0, 0), end: const Offset(-80, -80))
              .scale(begin: const Offset(0, 0), end: const Offset(1, 1)),
          _ClothingItem(color: AppColors.teal, emoji: '👖')
              .animate(delay: 400.ms)
              .move(begin: const Offset(0, 0), end: const Offset(80, -80))
              .scale(begin: const Offset(0, 0), end: const Offset(1, 1)),
          _ClothingItem(color: AppColors.blue, emoji: '👟')
              .animate(delay: 600.ms)
              .move(begin: const Offset(0, 0), end: const Offset(-80, 80))
              .scale(begin: const Offset(0, 0), end: const Offset(1, 1)),
          _ClothingItem(color: AppColors.purple, emoji: '👗')
              .animate(delay: 800.ms)
              .move(begin: const Offset(0, 0), end: const Offset(80, 80))
              .scale(begin: const Offset(0, 0), end: const Offset(1, 1)),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.purple, AppColors.teal],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withOpacity(0.4),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const Center(
              child: Text('🧠', style: TextStyle(fontSize: 60)),
            ),
          ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
        ],
      ),
    );
  }

  Widget _buildWeatherSmart() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.gold,
              radius: 30,
              child: Text('☀️', style: TextStyle(fontSize: 28)),
            ),
            const SizedBox(height: 16),
            _ClothingItem(
              color: AppColors.pink,
              emoji: '👗',
              width: 70,
              height: 90,
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Icon(
            LucideIcons.arrowRight,
            size: 32,
            color: AppColors.purple,
          ),
        ),
        Column(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.blue.withOpacity(0.7),
              radius: 30,
              child: const Text('🌧️', style: TextStyle(fontSize: 28)),
            ),
            const SizedBox(height: 16),
            _ClothingItem(
              color: AppColors.teal,
              emoji: '🧥',
              width: 70,
              height: 90,
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildSocialShare() {
    return SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _UserAvatar(
            color: AppColors.pink,
          ).animate().move(end: const Offset(-80, -80)),
          _UserAvatar(
            color: AppColors.teal,
          ).animate().move(end: const Offset(80, -80)),
          _UserAvatar(
            color: AppColors.purple,
          ).animate().move(end: const Offset(-80, 80)),
          _UserAvatar(
            color: AppColors.blue,
          ).animate().move(end: const Offset(80, 80)),

          const CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.gold,
            child: Icon(LucideIcons.share2, color: Colors.white, size: 32),
          ).animate().scale(curve: Curves.elasticOut),
        ],
      ),
    );
  }
}

class _ClothingItem extends StatelessWidget {
  final Color color;
  final String emoji;
  final double width;
  final double height;

  const _ClothingItem({
    required this.color,
    required this.emoji,
    this.width = 80,
    this.height = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10)],
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 40))),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final Color color;
  const _UserAvatar({required this.color});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: color,
      child: const Icon(LucideIcons.user, color: Colors.white),
    );
  }
}
