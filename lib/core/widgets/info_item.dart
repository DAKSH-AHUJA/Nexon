import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Fixed-width label/value pair used inside detail panels.
class InfoItem extends StatelessWidget {
  const InfoItem({
    super.key,
    required this.label,
    required this.value,
    this.highlight = false,
    this.width = 180,
  });

  final String label;
  final String value;

  /// Draws the value in the warning color (e.g. outstanding balances).
  final bool highlight;

  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: highlight ? AppColors.warning : null,
                ),
          ),
        ],
      ),
    );
  }
}
