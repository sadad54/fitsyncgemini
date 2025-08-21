// lib/widgets/common/gradient_button.dart
import 'package:flutter/material.dart';

// Primary CTA button that respects global ElevatedButtonTheme
class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.padding = const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
    this.borderRadius = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ).merge(theme.elevatedButtonTheme.style),
      child: child,
    );
  }
}
