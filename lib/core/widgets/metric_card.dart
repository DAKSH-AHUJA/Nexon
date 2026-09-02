import 'package:flutter/material.dart';

import 'nexon_card.dart';

/// Card showing a single labelled metric, optionally with a leading icon tile.
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color,
    this.large = false,
    this.padding = const EdgeInsets.all(16),
  });

  final String label;
  final String value;

  /// Leading icon; when set the card renders as a horizontal tile.
  final IconData? icon;

  /// Accent color for the icon tile and, when [icon] is null, the value text.
  final Color? color;

  /// Renders the value with `titleLarge` instead of `titleMedium`.
  final bool large;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final valueStyle = (large ? textTheme.titleLarge : textTheme.titleMedium)
        ?.copyWith(
            fontWeight: FontWeight.w700, color: icon == null ? color : null);

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: valueStyle,
        ),
      ],
    );

    return NexonCard(
      padding: padding,
      child: icon == null
          ? details
          : Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (color ?? Theme.of(context).colorScheme.primary)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: details),
              ],
            ),
    );
  }
}

/// Lays out metric cards in an evenly spaced row.
class MetricRow extends StatelessWidget {
  const MetricRow({super.key, required this.cards, this.spacing = 12});

  final List<Widget> cards;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          Expanded(child: cards[i]),
        ],
      ],
    );
  }
}
