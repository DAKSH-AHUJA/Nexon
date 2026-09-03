import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_page.dart';
import '../features/trading/classic_trading_pages.dart';
import '../features/trading/purc_spat_page.dart';
import '../features/trading/purc_spat_detail_page.dart';
import '../services/auth_service.dart';
import 'shell_scaffold.dart';

/// Rebuilds router when auth state changes.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final isAuthenticated = ref.read(authProvider).isAuthenticated;
      final loggingIn = state.matchedLocation == '/login';

      if (!isAuthenticated && !loggingIn) return '/login';
      if (isAuthenticated && loggingIn) return '/data-entry';
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
          _shellRoute('/data-entry', const DataEntryPage()),
          _shellRoute(
            '/data-entry/purc-spat',
            const PurcSpatPage(),
          ),
          _shellRoute(
            '/data-entry/purc-spat/:lotId',
            const PurcSpatDetailPage(),
          ),
          _shellRoute(
              '/data-entry/sale', const TradingFeaturePage(title: 'Sale')),
          _shellRoute(
              '/data-entry/cash', const TradingFeaturePage(title: 'Cash')),
          _shellRoute(
              '/data-entry/bank', const TradingFeaturePage(title: 'Bank')),
          _shellRoute(
            '/data-entry/journal',
            const TradingFeaturePage(title: 'Journal'),
          ),
          _shellRoute(
            '/data-entry/sale-patti',
            const TradingFeaturePage(title: 'Sale Patti'),
          ),
          _shellRoute(
            '/data-entry/carets-entry',
            const TradingFeaturePage(title: 'Carets Entry'),
          ),
          _shellRoute('/correct-entry', const CorrectEntryPage()),
          _shellRoute(
            '/correct-entry/account',
            const TradingFeaturePage(title: 'Account'),
          ),
          _shellRoute(
            '/correct-entry/item',
            const TradingFeaturePage(title: 'Item'),
          ),
          _shellRoute('/reports', const TradingReportsPage()),
          _shellRoute(
              '/reports/master', const TradingFeaturePage(title: 'Master')),
          _shellRoute(
            '/reports/statement',
            const TradingFeaturePage(title: 'Statement'),
          ),
          _shellRoute(
              '/reports/books', const TradingFeaturePage(title: 'Books')),
          _shellRoute(
              '/reports/ledger', const TradingFeaturePage(title: 'Ledger')),
          _shellRoute(
            '/reports/outstanding',
            const TradingFeaturePage(title: 'Outstanding'),
          ),
          _shellRoute(
            '/reports/balancesheet',
            const TradingFeaturePage(title: 'Balancesheet'),
          ),
          _shellRoute('/backup', const BackupPage()),
          _shellRoute('/restore', const RestorePage()),
          _shellRoute('/tools', const ToolsPage()),
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
