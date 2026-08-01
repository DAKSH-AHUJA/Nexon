import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/supplier_model.dart';
import 'data_service.dart';

class SuppliersState {
  const SuppliersState({
    required this.suppliers,
    this.searchQuery = '',
    this.selectedId,
    this.isLoading = false,
  });

  final List<Supplier> suppliers;
  final String searchQuery;
  final String? selectedId;
  final bool isLoading;

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
    try {
      return suppliers.firstWhere((s) => s.id == selectedId);
    } catch (_) {
      return null;
    }
  }

  SuppliersState copyWith({
    List<Supplier>? suppliers,
    String? searchQuery,
    String? selectedId,
    bool? isLoading,
  }) {
    return SuppliersState(
      suppliers: suppliers ?? this.suppliers,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedId: selectedId ?? this.selectedId,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SuppliersNotifier extends StateNotifier<SuppliersState> {
  SuppliersNotifier(this._ref) : super(const SuppliersState(suppliers: [])) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    state = state.copyWith(isLoading: true);
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
