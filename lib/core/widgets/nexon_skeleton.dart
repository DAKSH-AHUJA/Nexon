import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';
import '../theme/theme_context.dart';

/// Loading skeleton placeholder for async content.
class NexonSkeleton extends StatelessWidget {
  const NexonSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 8,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final base =
        context.isDarkMode ? AppColors.darkCard : AppColors.lightBorder;
    final highlight = context.appCardElevated;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Grid of skeleton cards for dashboard loading state.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: List.generate(
            4,
            (_) => const SizedBox(
              width: 240,
              child: NexonSkeleton(height: 120, borderRadius: 16),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const NexonSkeleton(height: 280, borderRadius: 16),
      ],
    );
  }
}
