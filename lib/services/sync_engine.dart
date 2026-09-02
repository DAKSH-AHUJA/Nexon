import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../database/database.dart';
import '../database/tables.dart';
import 'connectivity_service.dart';
import 'supabase_service.dart';

class SyncResult {
  const SyncResult({required this.success, this.error});
  final bool success;
  final String? error;
}

class SyncEngine extends StateNotifier<bool> {
  SyncEngine(this._ref) : super(false) {
    _init();
  }

  final Ref _ref;
  final Logger _logger = Logger();
  Timer? _syncTimer;
  bool _isSyncing = false;

  void _init() {
    _ref.listen<ConnectivityState>(connectivityProvider, (previous, next) {
      if (next.isOnline && previous?.isOffline == true) {
        syncAll();
      }
    });

    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final connectivity = _ref.read(connectivityProvider);
      if (connectivity.isOnline && !_isSyncing) {
        syncAll();
      }
    });
  }

  AppDatabase get _db => _ref.read(appDatabaseProvider);

  Future<SyncResult> syncAll() async {
    if (_isSyncing) return const SyncResult(success: true);
    if (!_ref.read(connectivityProvider).isOnline) {
      return const SyncResult(success: false, error: 'Offline');
    }

    _isSyncing = true;
    state = true;

    try {
      final pending = await _db.getPendingSyncEntries();
      for (final entry in pending) {
        try {
          await _db.deleteSyncQueueEntry(entry.id);
        } catch (e) {
          _logger.w('Sync error: $e');
        }
      }
      return const SyncResult(success: true);
    } catch (e) {
      return SyncResult(success: false, error: e.toString());
    } finally {
      _isSyncing = false;
      state = false;
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}

final syncEngineProvider = StateNotifierProvider<SyncEngine, bool>((ref) {
  return SyncEngine(ref);
});