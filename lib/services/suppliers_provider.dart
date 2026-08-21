import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/supplier_model.dart';
import 'data_service.dart';

class SuppliersState {
  const SuppliersState({
    required this.suppliers,
    this.searchQuery = '',
    this.selectedId,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<Supplier> suppliers;
  final String searchQuery;
  final String? selectedId;
  final bool isLoading;
  final String? errorMessage;

  List<Supplier> get filtered {
    if (searchQuery.isEmpty) return suppliers;
    final q = searchQuery.toLowerCase();
    return suppliers
        .where(
          (s) =>
              s.name.toLowerCase().contains(q) ||
              s.phone.contains(q) ||
              s.city.toLowerCase().contains(q),
        )
        .toList();
  }

  Supplier? get selected {
    if (selectedId == null) return null;
    return suppliers.where((s) => s.id == selectedId).firstOrNull;
  }

  SuppliersState copyWith({
    List<Supplier>? suppliers,
    String? searchQuery,
    String? selectedId,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SuppliersState(
      suppliers: suppliers ?? this.suppliers,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedId: selectedId ?? this.selectedId,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class SuppliersNotifier extends StateNotifier<SuppliersState> {
  SuppliersNotifier(this._ref) : super(const SuppliersState(suppliers: [])) {
    load();
  }

  final Ref _ref;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final service = _ref.read(jsonDataServiceProvider);
      final json = await service.loadJson('suppliers.json');
      final list = (json['suppliers'] as List<dynamic>)
          .map((e) => Supplier.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        suppliers: list,
        isLoading: false,
        selectedId: list.isNotEmpty ? list.first.id : null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load suppliers: $e',
      );
    }
  }

  void setSearch(String query) => state = state.copyWith(searchQuery: query);
  void select(String? id) => state = state.copyWith(selectedId: id);
}

final suppliersProvider =
    StateNotifierProvider<SuppliersNotifier, SuppliersState>((ref) {
  return SuppliersNotifier(ref);
});

final accountingDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(jsonDataServiceProvider);
  return service.loadJson('expenses.json');
});

final reportsDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(jsonDataServiceProvider);
  return service.loadJson('reports.json');
});
