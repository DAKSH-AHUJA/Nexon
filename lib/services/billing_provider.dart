import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/customer_model.dart';
import '../models/invoice_model.dart';
import '../models/product_model.dart';

class BillingNotifier extends StateNotifier<InvoiceDraft> {
  BillingNotifier() : super(const InvoiceDraft());

  int _invoiceCounter = 2848;

  void selectCustomer(Customer? customer) {
    state = state.copyWith(customer: customer);
  }

  void addItem(Product product, {double quantity = 1}) {
    final existing = state.items.indexWhere((i) => i.product.id == product.id);
    if (existing >= 0) {
      final item = state.items[existing];
      final updated = item.copyWith(quantity: item.quantity + quantity);
      final items = [...state.items];
      items[existing] = updated;
      state = state.copyWith(items: items);
    } else {
      state = state.copyWith(
        items: [
          ...state.items,
          InvoiceLineItem(
            product: product,
            quantity: quantity,
            price: product.sellingPrice,
          ),
        ],
      );
    }
  }

  void updateItem(int index, InvoiceLineItem item) {
    final items = [...state.items];
    items[index] = item;
    state = state.copyWith(items: items);
  }

  void removeItem(int index) {
    final items = [...state.items]..removeAt(index);
    state = state.copyWith(items: items);
  }

  void clear() {
    state = const InvoiceDraft();
  }

  String generateInvoiceNo() {
    _invoiceCounter++;
    return 'INV-$_invoiceCounter';
  }

  InvoiceDraft finalize() {
    final no = generateInvoiceNo();
    state = state.copyWith(invoiceNo: no);
    return state;
  }
}

final billingProvider =
    StateNotifierProvider<BillingNotifier, InvoiceDraft>((ref) {
  return BillingNotifier();
});
