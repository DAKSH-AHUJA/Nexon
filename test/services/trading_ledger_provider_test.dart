import 'package:flutter_test/flutter_test.dart';
import 'package:nexon_erp/services/trading_ledger_provider.dart';

void main() {
  CaretEntry entry({
    String id = 'e1',
    String partyId = 'party_1',
    CaretEntryType type = CaretEntryType.inward,
    int quantity = 10,
  }) {
    return CaretEntry(
      id: id,
      companyId: 'company_1',
      partyId: partyId,
      partyName: 'Green Farms',
      type: type,
      quantity: quantity,
      date: DateTime(2024, 6, 1),
      referenceNumber: 'REF-$id',
    );
  }

  late TradingLedgerNotifier notifier;

  setUp(() => notifier = TradingLedgerNotifier());
  tearDown(() => notifier.dispose());

  test('starts empty', () {
    expect(notifier.state.caretEntries, isEmpty);
    expect(notifier.state.caretBalances, isEmpty);
    expect(notifier.caretBalanceForParty('party_1'), 0);
  });

  group('recordCaretEntry', () {
    test('inward entries increase the party balance', () {
      notifier.recordCaretEntry(entry(quantity: 10));
      notifier.recordCaretEntry(entry(id: 'e2', quantity: 5));

      expect(notifier.state.caretEntries, hasLength(2));
      expect(notifier.caretBalanceForParty('party_1'), 15);
    });

    test('outward entries decrease the party balance', () {
      notifier.recordCaretEntry(entry(quantity: 10));
      notifier.recordCaretEntry(
        entry(id: 'e2', type: CaretEntryType.outward, quantity: 4),
      );

      expect(notifier.caretBalanceForParty('party_1'), 6);
    });

    test('balances can go negative', () {
      notifier.recordCaretEntry(
        entry(type: CaretEntryType.outward, quantity: 7),
      );

      expect(notifier.caretBalanceForParty('party_1'), -7);
    });

    test('tracks parties independently', () {
      notifier.recordCaretEntry(entry(quantity: 10));
      notifier.recordCaretEntry(
        entry(id: 'e2', partyId: 'party_2', quantity: 3),
      );

      expect(notifier.caretBalanceForParty('party_1'), 10);
      expect(notifier.caretBalanceForParty('party_2'), 3);
      expect(notifier.state.caretBalances, hasLength(2));
    });

    test('ignores non-positive quantities', () {
      notifier.recordCaretEntry(entry(quantity: 0));
      notifier.recordCaretEntry(entry(id: 'e2', quantity: -5));

      expect(notifier.state.caretEntries, isEmpty);
      expect(notifier.state.caretBalances, isEmpty);
    });

    test('preserves entry details', () {
      notifier.recordCaretEntry(entry());
      final stored = notifier.state.caretEntries.single;

      expect(stored.id, 'e1');
      expect(stored.companyId, 'company_1');
      expect(stored.partyName, 'Green Farms');
      expect(stored.referenceNumber, 'REF-e1');
      expect(stored.date, DateTime(2024, 6, 1));
    });
  });

  group('reverseCaretEntry', () {
    test('removes an inward entry and restores the balance', () {
      notifier.recordCaretEntry(entry(quantity: 10));
      notifier.recordCaretEntry(entry(id: 'e2', quantity: 6));

      notifier.reverseCaretEntry('e1');

      expect(notifier.state.caretEntries.map((e) => e.id), ['e2']);
      expect(notifier.caretBalanceForParty('party_1'), 6);
    });

    test('removes an outward entry and restores the balance', () {
      notifier.recordCaretEntry(entry(quantity: 10));
      notifier.recordCaretEntry(
        entry(id: 'e2', type: CaretEntryType.outward, quantity: 4),
      );

      notifier.reverseCaretEntry('e2');

      expect(notifier.caretBalanceForParty('party_1'), 10);
      expect(notifier.state.caretEntries, hasLength(1));
    });

    test('is a no-op for an unknown entry id', () {
      notifier.recordCaretEntry(entry(quantity: 10));

      notifier.reverseCaretEntry('missing');

      expect(notifier.state.caretEntries, hasLength(1));
      expect(notifier.caretBalanceForParty('party_1'), 10);
    });

    test('reversing every entry returns the balance to zero', () {
      notifier.recordCaretEntry(entry(quantity: 10));
      notifier.reverseCaretEntry('e1');

      expect(notifier.state.caretEntries, isEmpty);
      expect(notifier.caretBalanceForParty('party_1'), 0);
    });
  });

  group('TradingLedgerState.copyWith', () {
    test('keeps unspecified fields', () {
      final state = TradingLedgerState(
        caretEntries: [entry()],
        caretBalances: const {'party_1': 10},
      );
      final copy = state.copyWith();

      expect(copy.caretEntries, state.caretEntries);
      expect(copy.caretBalances, state.caretBalances);
      expect(state.copyWith(caretBalances: const {}).caretBalances, isEmpty);
    });
  });
}
