import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/responsive.dart';
import 'nav_destinations.dart';
import 'widgets/app_sidebar.dart';
import 'widgets/app_top_bar.dart';

/// Main application shell with adaptive sidebar and top bar.
class ShellScaffold extends ConsumerStatefulWidget {
  const ShellScaffold({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends ConsumerState<ShellScaffold> {
  bool _sidebarCollapsed = false;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  NavDestination _currentDestination(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    return NavDestination.fromRoute(location) ?? NavDestination.dashboard;
  }

  void _onNavigate(NavDestination destination) {
    context.go(destination.route);
    if (Responsive(context).isMobile) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final current = _currentDestination(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (responsive.isMobile) {
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        drawer: Drawer(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          child: AppSidebar(
            current: current,
            onNavigate: _onNavigate,
            expanded: true,
          ),
        ),
        body: Column(
          children: [
            AppTopBar(
              onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
              showMenuButton: true,
            ),
            Expanded(child: widget.child),
          ],
        ),
      );
    }

    final sidebarWidth = _sidebarCollapsed
        ? AppConstants.sidebarCollapsedWidth
        : AppConstants.sidebarExpandedWidth;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Row(
        children: [
          AnimatedContainer(
            duration: AppConstants.animationNormal,
            curve: Curves.easeInOutCubic,
            width: sidebarWidth,
            child: AppSidebar(
              current: current,
              onNavigate: _onNavigate,
              expanded: !_sidebarCollapsed,
              onToggleCollapse: responsive.isDesktop
                  ? () => setState(() => _sidebarCollapsed = !_sidebarCollapsed)
                  : null,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                AppTopBar(showMenuButton: false),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
