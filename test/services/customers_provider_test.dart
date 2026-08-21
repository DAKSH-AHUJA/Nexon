import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexon_erp/models/customer_model.dart';
import 'package:nexon_erp/services/customers_provider.dart';
import 'package:nexon_erp/services/data_service.dart';

import '../helpers/fake_data_service.dart';
import '../helpers/fixtures.dart';

void main() {
  group('CustomersState.filtered', () {
    final customers = [
      buildCustomer(id: 'c1', name: 'Rajesh Traders', city: 'Bengaluru'),
      buildCustomer(
        id: 'c2',
        name: 'Fresh Mart',
        city: 'Mysuru',
        phone: '9000000001',
        status: 'inactive',
        outstandingBalance: 0,
      ),
      buildCustomer(
        id: 'c3',
        name: 'City Bazaar',
        city: 'Hubli',
        phone: '9000000002',
        outstandingBalance: 250,
      ),
    ];

    test('returns everything for the all filter', () {
      const state = CustomersState(customers: []);

      expect(state.filtered, isEmpty);
      expect(
        CustomersState(customers: customers).filtered,
        hasLength(3),
      );
    });

    test('active filter keeps only active customers', () {
      final state = CustomersState(
        customers: customers,
        filter: CustomerFilter.active,
      );

      expect(state.filtered.map((c) => c.id), ['c1', 'c3']);
    });

    test('outstanding filter keeps only customers with a balance', () {
      final state = CustomersState(
        customers: customers,
        filter: CustomerFilter.outstanding,
      );

      expect(state.filtered.map((c) => c.id), ['c1', 'c3']);
    });

    test('search matches name, phone and city case-insensitively', () {
      CustomersState withQuery(String q) =>
          CustomersState(customers: customers, searchQuery: q);

      expect(withQuery('rajesh').filtered.map((c) => c.id), ['c1']);
      expect(withQuery('MYSURU').filtered.map((c) => c.id), ['c2']);
      expect(withQuery('9000000002').filtered.map((c) => c.id), ['c3']);
      expect(withQuery('zzz').filtered, isEmpty);
    });

    test('search and filter combine', () {
      final state = CustomersState(
        customers: customers,
        filter: CustomerFilter.active,
        searchQuery: 'mart',
      );

      expect(state.filtered, isEmpty);
    });
  });

  group('CustomersState.selected', () {
    test('is null without a selection or for an unknown id', () {
      final customers = [buildCustomer(id: 'c1')];

      expect(CustomersState(customers: customers).selected, isNull);
      expect(
        CustomersState(customers: customers, selectedId: 'nope').selected,
        isNull,
      );
    });

    test('resolves the selected customer', () {
      final state = CustomersState(
        customers: [buildCustomer(id: 'c1'), buildCustomer(id: 'c2')],
        selectedId: 'c2',
      );

      expect(state.selected?.id, 'c2');
    });
  });

  group('CustomersState.copyWith', () {
    test('keeps unspecified fields and clears the selection on request', () {
      final state = CustomersState(
        customers: [buildCustomer(id: 'c1')],
        searchQuery: 'raj',
        filter: CustomerFilter.outstanding,
        selectedId: 'c1',
        isLoading: true,
      );

      final copy = state.copyWith();
      expect(copy.searchQuery, 'raj');
      expect(copy.filter, CustomerFilter.outstanding);
      expect(copy.selectedId, 'c1');
      expect(copy.isLoading, isTrue);

      expect(state.copyWith(clearSelection: true).selectedId, isNull);
      expect(state.copyWith(isLoading: false).isLoading, isFalse);
    });
  });

  group('CustomersNotifier', () {
    late FakeJsonDataService service;
    late ProviderContainer container;

    setUp(() {
      service = FakeJsonDataService({'customers.json': customersFixture()});
      container = ProviderContainer(
        overrides: [jsonDataServiceProvider.overrideWithValue(service)],
      );
    });

    tearDown(() => container.dispose());

    Future<CustomersNotifier> loadedNotifier() async {
      final notifier = container.read(customersProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      return notifier;
    }

    test('loads customers and selects the first one', () async {
      final notifier = await loadedNotifier();

      expect(service.requestedFiles, ['customers.json']);
      expect(notifier.state.customers, hasLength(2));
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.selectedId, 'cust_001');
      expect(notifier.state.selected?.name, 'Rajesh Traders');
    });

    test('setSearch, setFilter and select update the state', () async {
      final notifier = await loadedNotifier();

      notifier.setSearch('fresh');
      expect(notifier.state.searchQuery, 'fresh');
      expect(notifier.state.filtered.map((c) => c.id), ['cust_002']);

      notifier.setFilter(CustomerFilter.outstanding);
      expect(notifier.state.filter, CustomerFilter.outstanding);

      notifier.select('cust_002');
      expect(notifier.state.selected?.id, 'cust_002');
    });

    test('addCustomer appends and selects the new customer', () async {
      final notifier = await loadedNotifier();

      notifier.addCustomer(buildCustomer(id: 'cust_999', name: 'New Co'));

      expect(notifier.state.customers, hasLength(3));
      expect(notifier.state.selectedId, 'cust_999');
    });

    test('updateCustomer replaces the matching customer only', () async {
      final notifier = await loadedNotifier();
      final original = notifier.state.customers.first;

      notifier.updateCustomer(original.copyWith(name: 'Renamed'));

      expect(notifier.state.customers.first.name, 'Renamed');
      expect(notifier.state.customers.last.name, 'Fresh Mart');
      expect(notifier.state.customers, hasLength(2));
    });

    test('updateCustomer ignores an unknown id', () async {
      final notifier = await loadedNotifier();

      notifier.updateCustomer(buildCustomer(id: 'missing'));

      expect(notifier.state.customers.map((c) => c.id),
          ['cust_001', 'cust_002']);
    });

    test('deleteCustomer removes the customer', () async {
      final notifier = await loadedNotifier();

      notifier.deleteCustomer('cust_001');

      expect(notifier.state.customers.map((c) => c.id), ['cust_002']);
    });

    test('deleteCustomer leaves no selection when the selected row goes',
        () async {
      // clearSelection takes precedence over the selectedId fallback in
      // CustomersState.copyWith, so no customer is reselected.
      final notifier = await loadedNotifier();

      notifier.deleteCustomer('cust_001');

      expect(notifier.state.selectedId, isNull);
      expect(notifier.state.selected, isNull);
    });

    test('deleteCustomer keeps the selection when another row is removed',
        () async {
      final notifier = await loadedNotifier();

      notifier.deleteCustomer('cust_002');

      expect(notifier.state.selectedId, 'cust_001');
    });

    test('deleteCustomer clears the selection when nothing is left', () async {
      final notifier = await loadedNotifier();

      notifier
        ..deleteCustomer('cust_002')
        ..deleteCustomer('cust_001');

      expect(notifier.state.customers, isEmpty);
      expect(notifier.state.selectedId, isNull);
    });

    test('nextId produces sequential zero-padded ids', () async {
      final notifier = await loadedNotifier();

      expect(notifier.nextId(), 'cust_101');
      expect(notifier.nextId(), 'cust_102');
    });

    group('applyCashPayment', () {
      test('reduces the balance and prepends a ledger credit', () async {
        final notifier = await loadedNotifier();
        final receivedAt = DateTime(2024, 6, 1, 9, 30);

        final updated = notifier.applyCashPayment(
          customerId: 'cust_001',
          amount: 500,
          mode: 'UPI',
          receivedAt: receivedAt,
          reference: ' TXN-77 ',
          notes: ' partial ',
        );

        expect(updated, isNotNull);
        expect(updated!.outstandingBalance, 1000);
        expect(updated.ledger, hasLength(1));

        final entry = updated.ledger.first;
        expect(entry.date, receivedAt);
        expect(entry.credit, 500);
        expect(entry.debit, 0);
        expect(entry.balance, 1000);
        expect(
          entry.description,
          'Cash received - UPI - Ref: TXN-77 - partial',
        );
        expect(notifier.state.selectedId, 'cust_001');
        expect(notifier.state.customers.first.outstandingBalance, 1000);
      });

      test('omits blank references and notes from the description', () async {
        final notifier = await loadedNotifier();

        final updated = notifier.applyCashPayment(
          customerId: 'cust_001',
          amount: 100,
          mode: 'Cash',
          receivedAt: DateTime(2024, 6, 1),
          reference: '   ',
          notes: '',
        );

        expect(updated!.ledger.first.description, 'Cash received - Cash');
      });

      test('caps the payment at the outstanding balance', () async {
        final notifier = await loadedNotifier();

        final updated = notifier.applyCashPayment(
          customerId: 'cust_001',
          amount: 5000,
          mode: 'Cash',
          receivedAt: DateTime(2024, 6, 1),
        );

        expect(updated!.outstandingBalance, 0);
        expect(updated.ledger.first.credit, 1500);
      });

      test('keeps existing ledger entries below the new one', () async {
        final notifier = await loadedNotifier();
        notifier.updateCustomer(
          notifier.state.customers.first.copyWith(
            ledger: [
              LedgerEntry(
                date: DateTime(2024, 5, 1),
                description: 'Invoice INV-1',
                debit: 1500,
                credit: 0,
                balance: 1500,
              ),
            ],
          ),
        );

        final updated = notifier.applyCashPayment(
          customerId: 'cust_001',
          amount: 200,
          mode: 'Cash',
          receivedAt: DateTime(2024, 6, 1),
        );

        expect(updated!.ledger, hasLength(2));
        expect(updated.ledger.first.credit, 200);
        expect(updated.ledger.last.description, 'Invoice INV-1');
      });

      test('returns null for a non-positive amount', () async {
        final notifier = await loadedNotifier();

        expect(
          notifier.applyCashPayment(
            customerId: 'cust_001',
            amount: 0,
            mode: 'Cash',
            receivedAt: DateTime(2024, 6, 1),
          ),
          isNull,
        );
        expect(
          notifier.applyCashPayment(
            customerId: 'cust_001',
            amount: -50,
            mode: 'Cash',
            receivedAt: DateTime(2024, 6, 1),
          ),
          isNull,
        );
        expect(notifier.state.customers.first.outstandingBalance, 1500);
      });

      test('returns null for an unknown customer', () async {
        final notifier = await loadedNotifier();

        expect(
          notifier.applyCashPayment(
            customerId: 'missing',
            amount: 100,
            mode: 'Cash',
            receivedAt: DateTime(2024, 6, 1),
          ),
          isNull,
        );
      });
    });
  });
}
