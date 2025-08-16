// lib/widgets/common/fitsync_assets.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fitsyncgemini/constants/app_colors.dart';

/// Centralized FitSync-themed icon badges to ensure consistent assets across the app
class FitSyncFeatureIcon extends StatelessWidget {
  final String
  type; // camera, wardrobe, ai, weather, outfit, social, trends, virtual
  final double size; // icon glyph size
  final double container; // outer badge size

  const FitSyncFeatureIcon({
    super.key,
    required this.type,
    this.size = 20,
    this.container = 40,
  });

  @override
  Widget build(BuildContext context) {
    final _IconToken token = _mapFeature(type);
    return Container(
      width: container,
      height: container,
      decoration: BoxDecoration(
        color: token.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: token.color.withOpacity(0.18)),
      ),
      alignment: Alignment.center,
      child: Icon(token.icon, color: token.color, size: size),
    );
  }

  _IconToken _mapFeature(String t) {
    switch (t) {
      case 'camera':
        return _IconToken(LucideIcons.camera, AppColors.pink);
      case 'wardrobe':
        return _IconToken(LucideIcons.shoppingBag, AppColors.blue);
      case 'ai':
        return _IconToken(LucideIcons.sparkles, AppColors.purple);
      case 'weather':
        return _IconToken(LucideIcons.sun, Colors.orange);
      case 'outfit':
        return _IconToken(LucideIcons.shirt, AppColors.teal);
      case 'social':
        return _IconToken(LucideIcons.users, AppColors.gold);
      case 'trends':
        return _IconToken(LucideIcons.trendingUp, AppColors.teal);
      case 'virtual':
        return _IconToken(LucideIcons.play, AppColors.pink);
      default:
        return _IconToken(LucideIcons.circle, AppColors.dark);
    }
  }
}

class _IconToken {
  final IconData icon;
  final Color color;
  _IconToken(this.icon, this.color);
}
