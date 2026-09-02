import 'package:flutter_test/flutter_test.dart';
import 'package:nexon_erp/models/invoice_model.dart';

import '../helpers/fixtures.dart';

void main() {
  group('InvoiceLineItem', () {
    test('computes subtotal, discount, taxable, gst and total', () {
      final item = InvoiceLineItem(
        product: buildProduct(),
        quantity: 10,
        price: 100,
        discount: 10,
        gstRate: 5,
      );

      expect(item.subtotal, 1000);
      expect(item.discountAmount, 100);
      expect(item.taxable, 900);
      expect(item.gstAmount, 45);
      expect(item.total, 945);
    });

    test('defaults to no discount and 5% gst', () {
      final item = InvoiceLineItem(
        product: buildProduct(),
        quantity: 2,
        price: 50,
      );

      expect(item.discount, 0);
      expect(item.gstRate, 5);
      expect(item.discountAmount, 0);
      expect(item.taxable, 100);
      expect(item.gstAmount, 5);
      expect(item.total, 105);
    });

    test('handles a zero gst rate and a full discount', () {
      final zeroGst = InvoiceLineItem(
        product: buildProduct(),
        quantity: 4,
        price: 25,
        gstRate: 0,
      );
      expect(zeroGst.gstAmount, 0);
      expect(zeroGst.total, 100);

      final fullDiscount = zeroGst.copyWith(discount: 100);
      expect(fullDiscount.taxable, 0);
      expect(fullDiscount.total, 0);
    });

    test('copyWith overrides only the provided fields', () {
      final item = InvoiceLineItem(
        product: buildProduct(),
        quantity: 1,
        price: 100,
      );
      final updated = item.copyWith(quantity: 3, discount: 5);

      expect(updated.quantity, 3);
      expect(updated.discount, 5);
      expect(updated.price, 100);
      expect(updated.gstRate, item.gstRate);
      expect(updated.product, item.product);
      expect(item.copyWith(), item);
    });

    test('equality compares product id, quantity, price and discount', () {
      final item = InvoiceLineItem(
        product: buildProduct(),
        quantity: 1,
        price: 100,
      );

      expect(item, item.copyWith(gstRate: 18));
      expect(item == item.copyWith(quantity: 2), isFalse);
      expect(
        item == item.copyWith(product: buildProduct(id: 'prod_002')),
        isFalse,
      );
    });
  });

  group('InvoiceDraft', () {
    InvoiceLineItem lineItem(String id, double qty, double price) {
      return InvoiceLineItem(
        product: buildProduct(id: id),
        quantity: qty,
        price: price,
        gstRate: 5,
      );
    }

    test('empty draft has zero totals and is invalid', () {
      const draft = InvoiceDraft();

      expect(draft.items, isEmpty);
      expect(draft.subtotal, 0);
      expect(draft.totalGst, 0);
      expect(draft.grandTotal, 0);
      expect(draft.isValid, isFalse);
    });

    test('aggregates totals across line items', () {
      final draft = InvoiceDraft(
        customer: buildCustomer(),
        items: [lineItem('prod_001', 10, 100), lineItem('prod_002', 2, 50)],
      );

      expect(draft.subtotal, 1100);
      expect(draft.totalGst, 55);
      expect(draft.grandTotal, 1155);
      expect(draft.grandTotal, draft.subtotal + draft.totalGst);
    });

    test('is valid only with a customer and at least one item', () {
      final items = [lineItem('prod_001', 1, 10)];

      expect(InvoiceDraft(items: items).isValid, isFalse);
      expect(InvoiceDraft(customer: buildCustomer()).isValid, isFalse);
      expect(
        InvoiceDraft(customer: buildCustomer(), items: items).isValid,
        isTrue,
      );
    });

    test('copyWith overrides only the provided fields', () {
      final draft = InvoiceDraft(
        customer: buildCustomer(),
        items: [lineItem('prod_001', 1, 10)],
      );
      final updated = draft.copyWith(invoiceNo: 'INV-1');

      expect(updated.invoiceNo, 'INV-1');
      expect(updated.customer, draft.customer);
      expect(updated.items, draft.items);
    });

    test('equality compares customer id, items and invoice number', () {
      final draft = InvoiceDraft(
        customer: buildCustomer(),
        items: [lineItem('prod_001', 1, 10)],
      );

      expect(
        draft,
        InvoiceDraft(
          customer: buildCustomer(),
          items: [lineItem('prod_001', 1, 10)],
        ),
      );
      expect(draft == draft.copyWith(invoiceNo: 'INV-9'), isFalse);
    });
  });
}
