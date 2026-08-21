import 'package:flutter/material.dart';

/// Main sections for the trading ERP shell.
enum NavDestination {
  dataEntry(
    label: 'Data Entry',
    icon: Icons.edit_note_outlined,
    selectedIcon: Icons.edit_note_rounded,
    route: '/data-entry',
  ),
  correctEntry(
    label: 'Correct Entry',
    icon: Icons.tune_outlined,
    selectedIcon: Icons.tune_rounded,
    route: '/correct-entry',
  ),
  reports(
    label: 'Reports',
    icon: Icons.bar_chart_outlined,
    selectedIcon: Icons.bar_chart_rounded,
    route: '/reports',
  ),
  backup(
    label: 'Back up',
    icon: Icons.backup_outlined,
    selectedIcon: Icons.backup_rounded,
    route: '/backup',
  ),
  restore(
    label: 'Restore',
    icon: Icons.restore_page_outlined,
    selectedIcon: Icons.restore_page_rounded,
    route: '/restore',
  ),
  tools(
    label: 'Tools',
    icon: Icons.build_outlined,
    selectedIcon: Icons.build_rounded,
    route: '/tools',
  );

  const NavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;

  static NavDestination? fromRoute(String route) {
    for (final dest in NavDestination.values) {
      if (route == dest.route || route.startsWith('${dest.route}/')) {
        return dest;
      }
    }
    return null;
  }
}
