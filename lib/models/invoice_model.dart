import 'package:equatable/equatable.dart';

import 'customer_model.dart';
import 'product_model.dart';

class InvoiceLineItem extends Equatable {
  const InvoiceLineItem({
    required this.product,
    required this.quantity,
    required this.price,
    this.discount = 0,
    this.gstRate = 5,
  });

  final Product product;
  final double quantity;
  final double price;
  final double discount;
  final double gstRate;

  double get subtotal => quantity * price;
  double get discountAmount => subtotal * (discount / 100);
  double get taxable => subtotal - discountAmount;
  double get gstAmount => taxable * (gstRate / 100);
  double get total => taxable + gstAmount;

  InvoiceLineItem copyWith({
    Product? product,
    double? quantity,
    double? price,
    double? discount,
    double? gstRate,
  }) {
    return InvoiceLineItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      discount: discount ?? this.discount,
      gstRate: gstRate ?? this.gstRate,
    );
  }

  @override
  List<Object?> get props => [product.id, quantity, price, discount];
}

class InvoiceDraft extends Equatable {
  const InvoiceDraft({
    this.customer,
    this.items = const [],
    this.invoiceNo,
  });

  final Customer? customer;
  final List<InvoiceLineItem> items;
  final String? invoiceNo;

  double get subtotal => items.fold(0, (sum, i) => sum + i.taxable);
  double get totalGst => items.fold(0, (sum, i) => sum + i.gstAmount);
  double get grandTotal => items.fold(0, (sum, i) => sum + i.total);

  bool get isValid => customer != null && items.isNotEmpty;

  InvoiceDraft copyWith({
    Customer? customer,
    List<InvoiceLineItem>? items,
    String? invoiceNo,
  }) {
    return InvoiceDraft(
      customer: customer ?? this.customer,
      items: items ?? this.items,
      invoiceNo: invoiceNo ?? this.invoiceNo,
    );
  }

  @override
  List<Object?> get props => [customer?.id, items, invoiceNo];
}
