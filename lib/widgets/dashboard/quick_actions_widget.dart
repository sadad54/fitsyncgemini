// lib/widgets/dashboard/quick_actions_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fitsyncgemini/constants/app_colors.dart';
import 'package:fitsyncgemini/widgets/closet/add_item_modal.dart';
import 'package:flutter_animate/flutter_animate.dart';

class QuickActionsWidget extends ConsumerWidget {
  const QuickActionsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildQuickActionCard(
                context,
                icon: LucideIcons.camera,
                label: 'Add Item',
                subtitle: 'Upload new clothing',
                color: AppColors.pink,
                onTap: () => _showAddItemModal(context),
              ),
              const SizedBox(width: 12),
              _buildQuickActionCard(
                context,
                icon: LucideIcons.sparkles,
                label: 'Get Outfit',
                subtitle: 'AI suggestions',
                color: AppColors.purple,
                onTap: () => context.go('/outfit-suggestions'),
              ),
              const SizedBox(width: 12),
              _buildQuickActionCard(
                context,
                icon: LucideIcons.play,
                label: 'Try On',
                subtitle: 'Virtual fitting',
                color: AppColors.teal,
                onTap: () => context.go('/try-on'),
              ),
              const SizedBox(width: 12),
              _buildQuickActionCard(
                context,
                icon: LucideIcons.trendingUp,
                label: 'Trends',
                subtitle: 'What\'s hot now',
                color: AppColors.blue,
                onTap: () => context.go('/trends'),
              ),
              const SizedBox(width: 12),
              _buildQuickActionCard(
                context,
                icon: LucideIcons.users,
                label: 'Social',
                subtitle: 'Share & discover',
                color: AppColors.gold,
                onTap: () => context.go('/explore'),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddItemModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddItemModal(),
    );
  }
}
