import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexon_erp/models/supplier_model.dart';
import 'package:nexon_erp/services/data_service.dart';
import 'package:nexon_erp/services/suppliers_provider.dart';

import '../helpers/fake_data_service.dart';

void main() {
  Supplier supplier({
    String id = 'sup_001',
    String name = 'Green Farms',
    String phone = '9812345670',
    String city = 'Kolar',
  }) {
    return Supplier(
      id: id,
      name: name,
      phone: phone,
      email: '',
      gst: '',
      address: 'APMC Yard',
      city: city,
      outstandingPayment: 0,
      totalPurchases: 0,
      status: 'active',
    );
  }

  group('SuppliersState.filtered', () {
    final suppliers = [
      supplier(),
      supplier(
        id: 'sup_002',
        name: 'Hill Produce',
        phone: '9800011122',
        city: 'Hassan',
      ),
    ];

    test('returns every supplier without a query', () {
      expect(SuppliersState(suppliers: suppliers).filtered, hasLength(2));
      expect(const SuppliersState(suppliers: []).filtered, isEmpty);
    });

    test('matches name, phone and city case-insensitively', () {
      SuppliersState withQuery(String q) =>
          SuppliersState(suppliers: suppliers, searchQuery: q);

      expect(withQuery('hill').filtered.map((s) => s.id), ['sup_002']);
      expect(withQuery('KOLAR').filtered.map((s) => s.id), ['sup_001']);
      expect(withQuery('98000').filtered.map((s) => s.id), ['sup_002']);
      expect(withQuery('none').filtered, isEmpty);
    });
  });

  group('SuppliersState.selected', () {
    test('resolves the selection and tolerates unknown ids', () {
      final suppliers = [supplier(), supplier(id: 'sup_002')];

      expect(
        SuppliersState(suppliers: suppliers, selectedId: 'sup_002').selected?.id,
        'sup_002',
      );
      expect(
        SuppliersState(suppliers: suppliers, selectedId: 'nope').selected,
        isNull,
      );
      expect(SuppliersState(suppliers: suppliers).selected, isNull);
    });
  });

  group('SuppliersState.copyWith', () {
    test('keeps unspecified fields', () {
      final original = SuppliersState(
        suppliers: [supplier()],
        searchQuery: 'green',
        selectedId: 'sup_001',
        isLoading: true,
      );
      final copy = original.copyWith();

      expect(copy.suppliers, original.suppliers);
      expect(copy.searchQuery, 'green');
      expect(copy.selectedId, 'sup_001');
      expect(copy.isLoading, isTrue);
      expect(original.copyWith(isLoading: false).isLoading, isFalse);
    });
  });

  group('SuppliersNotifier', () {
    late FakeJsonDataService service;
    late ProviderContainer container;

    setUp(() {
      service = FakeJsonDataService({
        'suppliers.json': suppliersFixture(),
        'expenses.json': {'expenses': []},
        'reports.json': {'reports': []},
      });
      container = ProviderContainer(
        overrides: [jsonDataServiceProvider.overrideWithValue(service)],
      );
    });

    tearDown(() => container.dispose());

    test('loads suppliers and selects the first one', () async {
      final notifier = container.read(suppliersProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.suppliers, hasLength(2));
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.selectedId, 'sup_001');
      expect(notifier.state.selected?.name, 'Green Farms');
    });

    test('setSearch filters the loaded suppliers', () async {
      final notifier = container.read(suppliersProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      notifier.setSearch('hassan');

      expect(notifier.state.searchQuery, 'hassan');
      expect(notifier.state.filtered.map((s) => s.id), ['sup_002']);
    });

    test('select changes the selected supplier', () async {
      final notifier = container.read(suppliersProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      notifier.select('sup_002');

      expect(notifier.state.selected?.name, 'Hill Produce');
    });
  });

  group('accounting and reports providers', () {
    test('expose the raw json payloads', () async {
      final service = FakeJsonDataService({
        'expenses.json': {'expenses': [1, 2]},
        'reports.json': {'reports': [3]},
      });
      final container = ProviderContainer(
        overrides: [jsonDataServiceProvider.overrideWithValue(service)],
      );
      addTearDown(container.dispose);

      final expenses = await container.read(accountingDataProvider.future);
      final reports = await container.read(reportsDataProvider.future);

      expect(expenses['expenses'], [1, 2]);
      expect(reports['reports'], [3]);
      expect(service.requestedFiles, ['expenses.json', 'reports.json']);
    });

    test('surface loading errors', () async {
      final container = ProviderContainer(
        overrides: [
          jsonDataServiceProvider.overrideWithValue(FakeJsonDataService({})),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(accountingDataProvider.future),
        throwsStateError,
      );
    });
  });
}
