import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConnectivityStatus { online, offline, unknown }

class ConnectivityState {
  const ConnectivityState({
    required this.status,
    required this.lastChanged,
  });

  final ConnectivityStatus status;
  final DateTime lastChanged;

  bool get isOnline => status == ConnectivityStatus.online;
  bool get isOffline => status == ConnectivityStatus.offline;

  ConnectivityState copyWith({
    ConnectivityStatus? status,
    DateTime? lastChanged,
  }) {
    return ConnectivityState(
      status: status ?? this.status,
      lastChanged: lastChanged ?? this.lastChanged,
    );
  }
}

class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  ConnectivityNotifier()
      : super(ConnectivityState(
          status: ConnectivityStatus.unknown,
          lastChanged: DateTime.now(),
        )) {
    _init();
  }

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Future<void> _init() async {
    // Check initial connectivity
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(
      _updateStatus,
    );
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final hasConnection = results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);

    state = ConnectivityState(
      status: hasConnection
          ? ConnectivityStatus.online
          : ConnectivityStatus.offline,
      lastChanged: DateTime.now(),
    );
  }

  Future<bool> checkConnection() async {
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);
    return state.isOnline;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, ConnectivityState>((ref) {
  return ConnectivityNotifier();
});