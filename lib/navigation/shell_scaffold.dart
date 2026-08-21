import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    return NavDestination.fromRoute(location) ?? NavDestination.dataEntry;
  }

  void _onNavigate(NavDestination destination) {
    context.go(destination.route);
    if (Responsive(context).isMobile) {
      Navigator.of(context).pop();
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }

    final location = GoRouterState.of(context).matchedLocation;
    final current = NavDestination.fromRoute(location);
    if (current != null && location != current.route) {
      context.go(current.route);
      return;
    }

    if (location != NavDestination.dataEntry.route) {
      context.go(NavDestination.dataEntry.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final current = _currentDestination(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _goBack,
      },
      child: Focus(
        autofocus: true,
        child: responsive.isMobile
            ? _MobileShell(
                scaffoldKey: _scaffoldKey,
                current: current,
                isDark: isDark,
                onNavigate: _onNavigate,
                child: widget.child,
              )
            : _DesktopShell(
                current: current,
                isDark: isDark,
                sidebarCollapsed: _sidebarCollapsed,
                onNavigate: _onNavigate,
                onToggleSidebar: responsive.isDesktop
                    ? () => setState(
                          () => _sidebarCollapsed = !_sidebarCollapsed,
                        )
                    : null,
                child: widget.child,
              ),
      ),
    );
  }
}

class _MobileShell extends StatelessWidget {
  const _MobileShell({
    required this.scaffoldKey,
    required this.current,
    required this.isDark,
    required this.child,
    required this.onNavigate,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final NavDestination current;
  final bool isDark;
  final Widget child;
  final ValueChanged<NavDestination> onNavigate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      drawer: Drawer(
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
        child: AppSidebar(
          current: current,
          onNavigate: onNavigate,
          expanded: true,
        ),
      ),
      body: Column(
        children: [
          AppTopBar(
            onMenuTap: () => scaffoldKey.currentState?.openDrawer(),
            showMenuButton: true,
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _DesktopShell extends StatelessWidget {
  const _DesktopShell({
    required this.current,
    required this.isDark,
    required this.sidebarCollapsed,
    required this.child,
    required this.onNavigate,
    required this.onToggleSidebar,
  });

  final NavDestination current;
  final bool isDark;
  final bool sidebarCollapsed;
  final Widget child;
  final ValueChanged<NavDestination> onNavigate;
  final VoidCallback? onToggleSidebar;

  @override
  Widget build(BuildContext context) {
    final sidebarWidth = sidebarCollapsed
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
              onNavigate: onNavigate,
              expanded: !sidebarCollapsed,
              onToggleCollapse: onToggleSidebar,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                const AppTopBar(showMenuButton: false),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
