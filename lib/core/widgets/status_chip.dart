import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  factory StatusChip.success(String label) =>
      StatusChip(label: label, color: AppColors.success);

  factory StatusChip.warning(String label) =>
      StatusChip(label: label, color: AppColors.warning);

  factory StatusChip.danger(String label) =>
      StatusChip(label: label, color: AppColors.danger);

  factory StatusChip.neutral(String label) =>
      StatusChip(label: label, color: AppColors.textTertiaryLight);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
