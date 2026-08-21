import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/collection_utils.dart';
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
      result = result
          .where((c) => matchesQuery(searchQuery, [c.name, c.phone, c.city]))
          .toList();
    }

    return result;
  }

  Customer? get selected =>
      customers.firstWhereOrNull((c) => c.id == selectedId);

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
    final list = await service.loadList(
      'customers.json',
      'customers',
      Customer.fromJson,
    );
    state = state.copyWith(
      customers: list,
      isLoading: false,
      selectedId: list.isNotEmpty ? list.first.id : null,
    );
  }

  void setSearch(String query) => state = state.copyWith(searchQuery: query);

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
    final remaining = state.customers.where((c) => c.id != id).toList();
    final wasSelected = state.selectedId == id;
    state = state.copyWith(
      customers: remaining,
      clearSelection: wasSelected && remaining.isEmpty,
      selectedId: wasSelected && remaining.isNotEmpty
          ? remaining.first.id
          : state.selectedId,
    );
  }

  Customer? applyCashPayment({
    required String customerId,
    required double amount,
    required String mode,
    required DateTime receivedAt,
    String? reference,
    String? notes,
  }) {
    if (amount <= 0) return null;

    final index = state.customers.indexWhere((c) => c.id == customerId);
    if (index == -1) return null;

    final customer = state.customers[index];
    final appliedAmount = amount > customer.outstandingBalance
        ? customer.outstandingBalance
        : amount;
    final newBalance = customer.outstandingBalance - appliedAmount;
    final descriptionParts = [
      'Cash received',
      mode,
      if (reference != null && reference.trim().isNotEmpty)
        'Ref: ${reference.trim()}',
      if (notes != null && notes.trim().isNotEmpty) notes.trim(),
    ];

    final entry = LedgerEntry(
      date: receivedAt,
      description: descriptionParts.join(' - '),
      debit: 0,
      credit: appliedAmount,
      balance: newBalance,
    );

    final updated = customer.copyWith(
      outstandingBalance: newBalance,
      ledger: [entry, ...customer.ledger],
    );

    final customers = [...state.customers];
    customers[index] = updated;
    state = state.copyWith(customers: customers, selectedId: updated.id);
    return updated;
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
