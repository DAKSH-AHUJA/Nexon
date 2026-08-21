import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/theme_context.dart';

/// Glassmorphism container for premium overlays.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 16,
    this.blur = 12,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            color: isDark ? AppColors.glassDark : AppColors.glassLight,
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.08),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
