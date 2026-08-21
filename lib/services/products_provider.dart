import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    this.errorMessage,
  });

  final List<Product> products;
  final List<InventoryTransaction> transactions;
  final String searchQuery;
  final String? categoryFilter;
  final ProductFilter filter;
  final String? selectedId;
  final bool isLoading;
  final String? errorMessage;

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
      final q = searchQuery.toLowerCase();
      result = result
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                p.category.toLowerCase().contains(q),
          )
          .toList();
    }

    return result;
  }

  Product? get selected {
    if (selectedId == null) return null;
    return products.where((p) => p.id == selectedId).firstOrNull;
  }

  ProductsState copyWith({
    List<Product>? products,
    List<InventoryTransaction>? transactions,
    String? searchQuery,
    String? categoryFilter,
    ProductFilter? filter,
    String? selectedId,
    bool? isLoading,
    String? errorMessage,
    bool clearCategory = false,
    bool clearSelection = false,
    bool clearError = false,
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
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ProductsNotifier extends StateNotifier<ProductsState> {
  ProductsNotifier(this._ref)
      : super(const ProductsState(products: [], transactions: [])) {
    load();
  }

  final Ref _ref;
  int _txnCounter = 100;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final service = _ref.read(jsonDataServiceProvider);
      final productsJson = await service.loadJson('products.json');
      final inventoryJson = await service.loadJson('inventory.json');

      final products = (productsJson['products'] as List<dynamic>)
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
      final transactions = (inventoryJson['transactions'] as List<dynamic>)
          .map((e) => InventoryTransaction.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        products: products,
        transactions: transactions,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load inventory: $e',
      );
    }
  }

  void setSearch(String query) => state = state.copyWith(searchQuery: query);
  void setCategory(String? category) =>
      state = state.copyWith(categoryFilter: category, clearCategory: category == null);
  void setFilter(ProductFilter filter) => state = state.copyWith(filter: filter);
  void select(String? id) => state = state.copyWith(selectedId: id);

  void adjustStock({
    required String productId,
    required String type,
    required double quantity,
    required String note,
  }) {
    final productIndex =
        state.products.indexWhere((p) => p.id == productId);
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

    final updated = product.copyWith(currentStock: newStock.clamp(0, double.infinity));
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
