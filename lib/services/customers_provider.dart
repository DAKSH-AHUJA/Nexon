import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/customer_model.dart';
import 'data_service.dart';

enum CustomerFilter { all, active, outstanding }

class CustomersState {
  const CustomersState({
    required this.customers,
    this.searchQuery = '',
    this.filter = CustomerFilter.all,
    this.selectedId,
    this.isLoading = false,
  });

  final List<Customer> customers;
  final String searchQuery;
  final CustomerFilter filter;
  final String? selectedId;
  final bool isLoading;

  List<Customer> get filtered {
    var result = customers;

    switch (filter) {
      case CustomerFilter.active:
        result = result.where((c) => c.status == 'active').toList();
      case CustomerFilter.outstanding:
        result = result.where((c) => c.hasOutstanding).toList();
      case CustomerFilter.all:
        break;
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result
          .where(
            (c) =>
                c.name.toLowerCase().contains(q) ||
                c.phone.contains(q) ||
                c.city.toLowerCase().contains(q),
          )
          .toList();
    }

    return result;
  }

  Customer? get selected {
    if (selectedId == null) return null;
    try {
      return customers.firstWhere((c) => c.id == selectedId);
    } catch (_) {
      return null;
    }
  }

  CustomersState copyWith({
    List<Customer>? customers,
    String? searchQuery,
    CustomerFilter? filter,
    String? selectedId,
    bool? isLoading,
    bool clearSelection = false,
  }) {
    return CustomersState(
      customers: customers ?? this.customers,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
      selectedId: clearSelection ? null : (selectedId ?? this.selectedId),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class CustomersNotifier extends StateNotifier<CustomersState> {
  CustomersNotifier(this._ref) : super(const CustomersState(customers: [])) {
    _load();
  }

  final Ref _ref;
  int _idCounter = 100;

  Future<void> _load() async {
    state = state.copyWith(isLoading: true);
    final service = _ref.read(jsonDataServiceProvider);
    final json = await service.loadJson('customers.json');
    final list = (json['customers'] as List<dynamic>)
        .map((e) => Customer.fromJson(e as Map<String, dynamic>))
        .toList();
    state = state.copyWith(
      customers: list,
      isLoading: false,
      selectedId: list.isNotEmpty ? list.first.id : null,
    );
  }

  void setSearch(String query) =>
      state = state.copyWith(searchQuery: query);

  void setFilter(CustomerFilter filter) =>
      state = state.copyWith(filter: filter);

  void select(String? id) => state = state.copyWith(selectedId: id);

  void addCustomer(Customer customer) {
    state = state.copyWith(
      customers: [...state.customers, customer],
      selectedId: customer.id,
    );
  }

  void updateCustomer(Customer customer) {
    state = state.copyWith(
      customers: state.customers
          .map((c) => c.id == customer.id ? customer : c)
          .toList(),
    );
  }

  void deleteCustomer(String id) {
    final remaining =
        state.customers.where((c) => c.id != id).toList();
    state = state.copyWith(
      customers: remaining,
      clearSelection: state.selectedId == id,
      selectedId: state.selectedId == id && remaining.isNotEmpty
          ? remaining.first.id
          : state.selectedId,
    );
  }

  String nextId() {
    _idCounter++;
    return 'cust_${_idCounter.toString().padLeft(3, '0')}';
  }
}

final customersProvider =
    StateNotifierProvider<CustomersNotifier, CustomersState>((ref) {
  return CustomersNotifier(ref);
});
