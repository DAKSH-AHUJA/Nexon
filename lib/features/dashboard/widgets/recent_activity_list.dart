import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/nexon_card.dart';
import '../../../models/dashboard_model.dart';

/// Timeline of recent business activity.
class RecentActivityList extends StatelessWidget {
  const RecentActivityList({super.key, required this.activities});

  final List<RecentActivity> activities;

  @override
  Widget build(BuildContext context) {
    return NexonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ...activities.asMap().entries.map((entry) {
            final index = entry.key;
            final activity = entry.value;
            return _ActivityTile(activity: activity)
                .animate(delay: (index * 80).ms)
                .fadeIn(duration: 400.ms)
                .slideX(begin: 0.03);
          }),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity});

  final RecentActivity activity;

  @override
  Widget build(BuildContext context) {
    final iconData = _iconForType(activity.icon);
    final iconColor = _colorForType(activity.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(iconData, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            Formatters.relativeTime(activity.timestamp),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String icon) {
    return switch (icon) {
      'receipt' => Icons.receipt_long_outlined,
      'payment' => Icons.payments_outlined,
      'inventory' => Icons.inventory_2_outlined,
      'warning' => Icons.warning_amber_rounded,
      'person_add' => Icons.person_add_outlined,
      _ => Icons.circle_outlined,
    };
  }

  Color _colorForType(String type) {
    return switch (type) {
      'sale' => AppColors.emerald500,
      'payment' => AppColors.blue500,
      'stock' => AppColors.info,
      'alert' => AppColors.warning,
      'customer' => AppColors.orange500,
      _ => AppColors.textSecondaryDark,
    };
  }
}
