import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'navigation/app_router.dart';
import 'widgets/offline_indicator.dart';
import 'widgets/sync_indicator.dart';

/// Root application widget with theme and routing.
class NexonApp extends ConsumerStatefulWidget {
  const NexonApp({super.key});

  @override
  ConsumerState<NexonApp> createState() => _NexonAppState();
}

class _NexonAppState extends ConsumerState<NexonApp> {
  @override
  void initState() {
    super.initState();
    // Initialize sync engine
    ref.read(syncEngineProvider);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Nexon ERP',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
      builder: (context, child) {
        return Column(
          children: const [
            OfflineIndicator(),
            SyncStatusIndicator(),
          ],
        );
      },
    );
  }
}
