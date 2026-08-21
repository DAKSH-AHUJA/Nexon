import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/collection_utils.dart';
import '../models/product_model.dart';
import 'data_service.dart';

enum ProductFilter { all, lowStock, outOfStock }

class ProductsState {
  const ProductsState({
    required this.products,
    required this.transactions,
    this.searchQuery = '',
    this.categoryFilter,
    this.filter = ProductFilter.all,
    this.selectedId,
    this.isLoading = false,
  });

  final List<Product> products;
  final List<InventoryTransaction> transactions;
  final String searchQuery;
  final String? categoryFilter;
  final ProductFilter filter;
  final String? selectedId;
  final bool isLoading;

  List<String> get categories =>
      products.map((p) => p.category).toSet().toList()..sort();

  List<Product> get filtered {
    var result = products;

    if (categoryFilter != null) {
      result = result.where((p) => p.category == categoryFilter).toList();
    }

    switch (filter) {
      case ProductFilter.lowStock:
        result =
            result.where((p) => p.stockStatus == StockStatus.lowStock).toList();
      case ProductFilter.outOfStock:
        result = result
            .where((p) => p.stockStatus == StockStatus.outOfStock)
            .toList();
      case ProductFilter.all:
        break;
    }

    if (searchQuery.isNotEmpty) {
      result = result
          .where((p) => matchesQuery(searchQuery, [p.name, p.category]))
          .toList();
    }

    return result;
  }

  Product? get selected => products.firstWhereOrNull((p) => p.id == selectedId);

  ProductsState copyWith({
    List<Product>? products,
    List<InventoryTransaction>? transactions,
    String? searchQuery,
    String? categoryFilter,
    ProductFilter? filter,
    String? selectedId,
    bool? isLoading,
    bool clearCategory = false,
    bool clearSelection = false,
  }) {
    return ProductsState(
      products: products ?? this.products,
      transactions: transactions ?? this.transactions,
      searchQuery: searchQuery ?? this.searchQuery,
      categoryFilter:
          clearCategory ? null : (categoryFilter ?? this.categoryFilter),
      filter: filter ?? this.filter,
      selectedId: clearSelection ? null : (selectedId ?? this.selectedId),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ProductsNotifier extends StateNotifier<ProductsState> {
  ProductsNotifier(this._ref)
      : super(const ProductsState(products: [], transactions: [])) {
    _load();
  }

  final Ref _ref;
  int _txnCounter = 100;

  Future<void> _load() async {
    state = state.copyWith(isLoading: true);
    final service = _ref.read(jsonDataServiceProvider);
    final products = await service.loadList(
      'products.json',
      'products',
      Product.fromJson,
    );
    final transactions = await service.loadList(
      'inventory.json',
      'transactions',
      InventoryTransaction.fromJson,
    );

    state = state.copyWith(
      products: products,
      transactions: transactions,
      isLoading: false,
    );
  }

  void setSearch(String query) => state = state.copyWith(searchQuery: query);
  void setCategory(String? category) => state =
      state.copyWith(categoryFilter: category, clearCategory: category == null);
  void setFilter(ProductFilter filter) =>
      state = state.copyWith(filter: filter);
  void select(String? id) => state = state.copyWith(selectedId: id);

  void adjustStock({
    required String productId,
    required String type,
    required double quantity,
    required String note,
  }) {
    final productIndex = state.products.indexWhere((p) => p.id == productId);
    if (productIndex == -1) return;

    final product = state.products[productIndex];
    double newStock = product.currentStock;

    if (type == 'stock_in') {
      newStock += quantity;
    } else if (type == 'stock_out') {
      newStock -= quantity;
    } else {
      newStock += quantity;
    }

    final updated =
        product.copyWith(currentStock: newStock.clamp(0, double.infinity));
    final products = [...state.products];
    products[productIndex] = updated;

    _txnCounter++;
    final txn = InventoryTransaction(
      id: 'txn_${_txnCounter.toString().padLeft(3, '0')}',
      productId: productId,
      productName: product.name,
      type: type,
      quantity: quantity.abs(),
      date: DateTime.now(),
      note: note,
      user: 'Admin',
    );

    state = state.copyWith(
      products: products,
      transactions: [txn, ...state.transactions],
    );
  }
}

final productsProvider =
    StateNotifierProvider<ProductsNotifier, ProductsState>((ref) {
  return ProductsNotifier(ref);
});
