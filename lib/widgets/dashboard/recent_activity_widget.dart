// lib/widgets/dashboard/recent_activity_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fitsyncgemini/constants/app_colors.dart';
import 'package:fitsyncgemini/utils/extensions.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RecentActivityWidget extends ConsumerWidget {
  const RecentActivityWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = _getRecentActivities();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.activity, color: AppColors.teal, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Recent Activity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _showAllActivities(context),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
<<<<<<< HEAD

          ...activities.take(5).map((activity) {
            return _buildActivityItem(activity);
          }).toList(),

=======
          
          ...activities.take(5).map((activity) {
            return _buildActivityItem(activity);
          }).toList(),
          
>>>>>>> 4eb743f5c696f1242a8ef094993dd9ef82211e1e
          if (activities.length > 5) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: () => _showAllActivities(context),
                icon: const Icon(LucideIcons.moreHorizontal, size: 16),
                label: Text('${activities.length - 5} more activities'),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 800.ms);
  }

  Widget _buildActivityItem(ActivityItem activity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: activity.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
<<<<<<< HEAD
            child: Icon(activity.icon, size: 18, color: activity.color),
=======
            child: Icon(
              activity.icon,
              size: 18,
              color: activity.color,
            ),
>>>>>>> 4eb743f5c696f1242a8ef094993dd9ef82211e1e
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
<<<<<<< HEAD
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
=======
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
>>>>>>> 4eb743f5c696f1242a8ef094993dd9ef82211e1e
                    children: [
                      TextSpan(
                        text: activity.action,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: ' ${activity.item}'),
                    ],
                  ),
                ),
                if (activity.details != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    activity.details!,
<<<<<<< HEAD
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
=======
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
>>>>>>> 4eb743f5c696f1242a8ef094993dd9ef82211e1e
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                activity.timestamp.toTimeAgo(),
<<<<<<< HEAD
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
=======
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
>>>>>>> 4eb743f5c696f1242a8ef094993dd9ef82211e1e
              ),
              if (activity.hasNotification)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(
                    color: AppColors.pink,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAllActivities(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
<<<<<<< HEAD
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'All Activity',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: _getRecentActivities().length,
                    itemBuilder: (context, index) {
                      return _buildActivityItem(_getRecentActivities()[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
=======
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'All Activity',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _getRecentActivities().length,
                itemBuilder: (context, index) {
                  return _buildActivityItem(_getRecentActivities()[index]);
                },
              ),
            ),
          ],
        ),
      ),
>>>>>>> 4eb743f5c696f1242a8ef094993dd9ef82211e1e
    );
  }

  List<ActivityItem> _getRecentActivities() {
    return [
      ActivityItem(
        action: 'Added',
        item: 'Blue Denim Jacket',
        icon: LucideIcons.plus,
        color: Colors.green,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        details: 'Automatically categorized as Outerwear',
        hasNotification: true,
      ),
      ActivityItem(
        action: 'Created outfit',
        item: 'Summer Vibes',
        icon: LucideIcons.sparkles,
        color: AppColors.purple,
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        details: '3 items • Perfect for sunny weather',
      ),
      ActivityItem(
        action: 'Wore',
        item: 'White Button Shirt',
        icon: LucideIcons.user,
        color: AppColors.blue,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        details: 'Marked as worn for work meeting',
      ),
      ActivityItem(
        action: 'Liked',
        item: 'Black Blazer',
        icon: LucideIcons.heart,
        color: AppColors.pink,
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
      ),
      ActivityItem(
        action: 'Shared',
        item: 'Casual Weekend Look',
        icon: LucideIcons.share2,
        color: AppColors.teal,
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        details: 'Shared to FitSync community',
      ),
      ActivityItem(
        action: 'Updated',
        item: 'Red Dress',
        icon: LucideIcons.edit,
        color: Colors.orange,
        timestamp: DateTime.now().subtract(const Duration(days: 4)),
        details: 'Added new tags: formal, evening',
      ),
      ActivityItem(
        action: 'Analyzed',
        item: 'Style preferences',
        icon: LucideIcons.brain,
        color: AppColors.gold,
        timestamp: DateTime.now().subtract(const Duration(days: 5)),
        details: 'Updated style archetype to Minimalist',
      ),
    ];
  }
}

class ActivityItem {
  final String action;
  final String item;
  final IconData icon;
  final Color color;
  final DateTime timestamp;
  final String? details;
  final bool hasNotification;

  ActivityItem({
    required this.action,
    required this.item,
    required this.icon,
    required this.color,
    required this.timestamp,
    this.details,
    this.hasNotification = false,
  });
<<<<<<< HEAD
}
=======
}
>>>>>>> 4eb743f5c696f1242a8ef094993dd9ef82211e1e
