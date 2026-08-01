import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/accounting/accounting_page.dart';
import '../features/auth/login_page.dart';
import '../features/billing/billing_page.dart';
import '../features/customers/customers_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/inventory/inventory_page.dart';
import '../features/notifications/notifications_page.dart';
import '../features/reports/reports_page.dart';
import '../features/settings/settings_page.dart';
import '../features/suppliers/suppliers_page.dart';
import '../services/auth_service.dart';
import 'shell_scaffold.dart';

/// Rebuilds router when auth state changes.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this._ref) {
    _ref.listen<bool>(authProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final isAuthenticated = ref.read(authProvider);
      final loggingIn = state.matchedLocation == '/login';

      if (!isAuthenticated && !loggingIn) return '/login';
      if (isAuthenticated && loggingIn) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginPage(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => ShellScaffold(child: child),
        routes: [
          _shellRoute('/dashboard', const DashboardPage()),
          _shellRoute('/customers', const CustomersPage()),
          _shellRoute('/inventory', const InventoryPage()),
          _shellRoute('/suppliers', const SuppliersPage()),
          _shellRoute('/billing', const BillingPage()),
          _shellRoute('/accounting', const AccountingPage()),
          _shellRoute('/reports', const ReportsPage()),
          _shellRoute('/notifications', const NotificationsPage()),
          _shellRoute('/settings', const SettingsPage()),
        ],
      ),
    ],
  );
});

GoRoute _shellRoute(String path, Widget page) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => CustomTransitionPage(
      key: state.pageKey,
      child: page,
      transitionsBuilder: _slideTransition,
    ),
  );
}

Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(opacity: animation, child: child);
}

Widget _slideTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final offset = Tween<Offset>(
    begin: const Offset(0.02, 0),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

  return FadeTransition(
    opacity: animation,
    child: SlideTransition(position: offset, child: child),
  );
}
