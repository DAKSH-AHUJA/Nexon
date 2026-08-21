import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Axis without titles; fl_chart needs one of these per unused side.
const hiddenAxisTitles = AxisTitles(sideTitles: SideTitles(showTitles: false));

/// Axis that labels each data index with the matching entry of [labels].
AxisTitles categoryAxisTitles(
  List<String> labels, {
  TextStyle? style,
  EdgeInsetsGeometry padding = EdgeInsets.zero,
  double reservedSize = 22,
}) {
  return AxisTitles(
    sideTitles: SideTitles(
      showTitles: true,
      reservedSize: reservedSize,
      getTitlesWidget: (value, _) {
        final index = value.toInt();
        if (index < 0 || index >= labels.length) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: padding,
          child: Text(labels[index], style: style),
        );
      },
    ),
  );
}
