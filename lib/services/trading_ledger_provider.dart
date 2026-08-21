import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CaretEntryType { inward, outward }

class CaretEntry {
  const CaretEntry({
    required this.id,
    required this.companyId,
    required this.partyId,
    required this.partyName,
    required this.type,
    required this.quantity,
    required this.date,
    this.referenceNumber,
  });

  final String id;
  final String companyId;
  final String partyId;
  final String partyName;
  final CaretEntryType type;
  final int quantity;
  final DateTime date;
  final String? referenceNumber;
}

class TradingLedgerState {
  const TradingLedgerState({
    this.caretEntries = const [],
    this.caretBalances = const {},
  });

  final List<CaretEntry> caretEntries;
  final Map<String, int> caretBalances;

  TradingLedgerState copyWith({
    List<CaretEntry>? caretEntries,
    Map<String, int>? caretBalances,
  }) {
    return TradingLedgerState(
      caretEntries: caretEntries ?? this.caretEntries,
      caretBalances: caretBalances ?? this.caretBalances,
    );
  }
}

class TradingLedgerNotifier extends StateNotifier<TradingLedgerState> {
  TradingLedgerNotifier() : super(const TradingLedgerState());

  void recordCaretEntry(CaretEntry entry) {
    if (entry.quantity <= 0) return;

    final balances = Map<String, int>.from(state.caretBalances);
    final currentBalance = balances[entry.partyId] ?? 0;
    final signedQuantity =
        entry.type == CaretEntryType.inward ? entry.quantity : -entry.quantity;

    balances[entry.partyId] = currentBalance + signedQuantity;

    state = state.copyWith(
      caretEntries: [...state.caretEntries, entry],
      caretBalances: balances,
    );
  }

  void reverseCaretEntry(String entryId) {
    final entry = state.caretEntries.where((e) => e.id == entryId).firstOrNull;
    if (entry == null) return;

    final balances = Map<String, int>.from(state.caretBalances);
    final currentBalance = balances[entry.partyId] ?? 0;
    final reversalQuantity =
        entry.type == CaretEntryType.inward ? -entry.quantity : entry.quantity;

    balances[entry.partyId] = currentBalance + reversalQuantity;

    state = state.copyWith(
      caretEntries: state.caretEntries.where((e) => e.id != entryId).toList(),
      caretBalances: balances,
    );
  }

  int caretBalanceForParty(String partyId) => state.caretBalances[partyId] ?? 0;
}

final tradingLedgerProvider =
    StateNotifierProvider<TradingLedgerNotifier, TradingLedgerState>((ref) {
  return TradingLedgerNotifier();
});
