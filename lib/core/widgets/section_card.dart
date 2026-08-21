import 'package:flutter/material.dart';

import 'nexon_card.dart';

/// Card with a titled header, a divider and a list-style body.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    this.action,
    this.large = false,
    this.children = const <Widget>[],
    this.expandedChild,
  });

  final String title;

  /// Optional widget shown at the trailing edge of the header.
  final Widget? action;

  /// Renders the title with `titleLarge` instead of `titleMedium`.
  final bool large;

  /// Body widgets stacked below the header.
  final List<Widget> children;

  /// Body widget that fills the remaining height (for scrollable lists).
  final Widget? expandedChild;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final expandedChild = this.expandedChild;

    return NexonCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  title,
                  style: large ? textTheme.titleLarge : textTheme.titleMedium,
                ),
                if (action != null) ...[const Spacer(), action!],
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
          if (expandedChild != null) Expanded(child: expandedChild),
        ],
      ),
    );
  }
}
