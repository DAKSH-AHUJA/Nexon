import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexon_erp/models/product_model.dart';
import 'package:nexon_erp/services/data_service.dart';
import 'package:nexon_erp/services/products_provider.dart';

import '../helpers/fake_data_service.dart';
import '../helpers/fixtures.dart';

void main() {
  final products = [
    buildProduct(id: 'p1', name: 'Tomato', category: 'Vegetables',
        currentStock: 100, minimumStock: 20),
    buildProduct(id: 'p2', name: 'Apple', category: 'Fruits',
        currentStock: 10, minimumStock: 20),
    buildProduct(id: 'p3', name: 'Banana', category: 'Fruits',
        currentStock: 0, minimumStock: 5),
  ];

  ProductsState state({
    String searchQuery = '',
    String? categoryFilter,
    ProductFilter filter = ProductFilter.all,
    String? selectedId,
  }) {
    return ProductsState(
      products: products,
      transactions: const [],
      searchQuery: searchQuery,
      categoryFilter: categoryFilter,
      filter: filter,
      selectedId: selectedId,
    );
  }

  group('ProductsState.categories', () {
    test('returns sorted unique categories', () {
      expect(state().categories, ['Fruits', 'Vegetables']);
    });

    test('is empty without products', () {
      const empty = ProductsState(products: [], transactions: []);

      expect(empty.categories, isEmpty);
      expect(empty.filtered, isEmpty);
    });
  });

  group('ProductsState.filtered', () {
    test('returns all products by default', () {
      expect(state().filtered, hasLength(3));
    });

    test('filters by category', () {
      expect(
        state(categoryFilter: 'Fruits').filtered.map((p) => p.id),
        ['p2', 'p3'],
      );
    });

    test('filters by low stock', () {
      expect(
        state(filter: ProductFilter.lowStock).filtered.map((p) => p.id),
        ['p2'],
      );
    });

    test('filters by out of stock', () {
      expect(
        state(filter: ProductFilter.outOfStock).filtered.map((p) => p.id),
        ['p3'],
      );
    });

    test('searches name and category case-insensitively', () {
      expect(state(searchQuery: 'toma').filtered.map((p) => p.id), ['p1']);
      expect(
        state(searchQuery: 'FRUITS').filtered.map((p) => p.id),
        ['p2', 'p3'],
      );
      expect(state(searchQuery: 'zzz').filtered, isEmpty);
    });

    test('combines category, stock filter and search', () {
      final filtered = state(
        categoryFilter: 'Fruits',
        filter: ProductFilter.outOfStock,
        searchQuery: 'banana',
      ).filtered;

      expect(filtered.map((p) => p.id), ['p3']);
    });
  });

  group('ProductsState.selected', () {
    test('resolves the selected product and tolerates unknown ids', () {
      expect(state(selectedId: 'p2').selected?.name, 'Apple');
      expect(state(selectedId: 'nope').selected, isNull);
      expect(state().selected, isNull);
    });
  });

  group('ProductsState.copyWith', () {
    test('keeps unspecified fields', () {
      final original = state(
        searchQuery: 'app',
        categoryFilter: 'Fruits',
        filter: ProductFilter.lowStock,
        selectedId: 'p2',
      );
      final copy = original.copyWith();

      expect(copy.searchQuery, 'app');
      expect(copy.categoryFilter, 'Fruits');
      expect(copy.filter, ProductFilter.lowStock);
      expect(copy.selectedId, 'p2');
    });

    test('clears the category and the selection on request', () {
      final original = state(categoryFilter: 'Fruits', selectedId: 'p2');

      expect(original.copyWith(clearCategory: true).categoryFilter, isNull);
      expect(original.copyWith(clearSelection: true).selectedId, isNull);
    });
  });

  group('ProductsNotifier', () {
    late FakeJsonDataService service;
    late ProviderContainer container;

    setUp(() {
      service = FakeJsonDataService({
        'products.json': productsFixture(),
        'inventory.json': inventoryFixture(),
      });
      container = ProviderContainer(
        overrides: [jsonDataServiceProvider.overrideWithValue(service)],
      );
    });

    tearDown(() => container.dispose());

    Future<ProductsNotifier> loadedNotifier() async {
      final notifier = container.read(productsProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      return notifier;
    }

    test('loads products and inventory transactions', () async {
      final notifier = await loadedNotifier();

      expect(service.requestedFiles, ['products.json', 'inventory.json']);
      expect(notifier.state.products, hasLength(2));
      expect(notifier.state.transactions, hasLength(1));
      expect(notifier.state.isLoading, isFalse);
    });

    test('setSearch, setFilter and select update the state', () async {
      final notifier = await loadedNotifier();

      notifier.setSearch('apple');
      expect(notifier.state.filtered.map((p) => p.id), ['prod_002']);

      notifier.setFilter(ProductFilter.lowStock);
      expect(notifier.state.filter, ProductFilter.lowStock);

      notifier.select('prod_001');
      expect(notifier.state.selected?.name, 'Tomato');
    });

    test('setCategory applies and clears the category filter', () async {
      final notifier = await loadedNotifier();

      notifier.setCategory('Fruits');
      expect(notifier.state.categoryFilter, 'Fruits');
      expect(notifier.state.filtered.map((p) => p.id), ['prod_002']);

      notifier.setCategory(null);
      expect(notifier.state.categoryFilter, isNull);
      expect(notifier.state.filtered, hasLength(2));
    });

    group('adjustStock', () {
      test('stock_in increases the stock and logs a transaction', () async {
        final notifier = await loadedNotifier();

        notifier.adjustStock(
          productId: 'prod_001',
          type: 'stock_in',
          quantity: 30,
          note: 'New arrival',
        );

        expect(notifier.state.products.first.currentStock, 150);
        expect(notifier.state.transactions, hasLength(2));

        final txn = notifier.state.transactions.first;
        expect(txn.id, 'txn_101');
        expect(txn.productId, 'prod_001');
        expect(txn.productName, 'Tomato');
        expect(txn.type, 'stock_in');
        expect(txn.quantity, 30);
        expect(txn.note, 'New arrival');
        expect(txn.user, 'Admin');
      });

      test('stock_out decreases the stock', () async {
        final notifier = await loadedNotifier();

        notifier.adjustStock(
          productId: 'prod_001',
          type: 'stock_out',
          quantity: 20,
          note: '',
        );

        expect(notifier.state.products.first.currentStock, 100);
      });

      test('never drives the stock below zero', () async {
        final notifier = await loadedNotifier();

        notifier.adjustStock(
          productId: 'prod_002',
          type: 'stock_out',
          quantity: 999,
          note: '',
        );

        expect(notifier.state.products.last.currentStock, 0);
        expect(
          notifier.state.products.last.stockStatus,
          StockStatus.outOfStock,
        );
      });

      test('an unknown type adds the signed quantity', () async {
        final notifier = await loadedNotifier();

        notifier.adjustStock(
          productId: 'prod_001',
          type: 'adjustment',
          quantity: -20,
          note: 'Spoilage',
        );

        expect(notifier.state.products.first.currentStock, 100);
        expect(notifier.state.transactions.first.quantity, 20);
      });

      test('ignores an unknown product', () async {
        final notifier = await loadedNotifier();

        notifier.adjustStock(
          productId: 'missing',
          type: 'stock_in',
          quantity: 5,
          note: '',
        );

        expect(notifier.state.transactions, hasLength(1));
        expect(notifier.state.products.first.currentStock, 120);
      });

      test('transaction ids stay sequential', () async {
        final notifier = await loadedNotifier();

        notifier
          ..adjustStock(
              productId: 'prod_001',
              type: 'stock_in',
              quantity: 1,
              note: '')
          ..adjustStock(
              productId: 'prod_001',
              type: 'stock_in',
              quantity: 1,
              note: '');

        expect(
          notifier.state.transactions.take(2).map((t) => t.id),
          ['txn_102', 'txn_101'],
        );
      });
    });
  });
}
