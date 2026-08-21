import 'package:flutter_test/flutter_test.dart';
import 'package:nexon_erp/models/invoice_model.dart';
import 'package:nexon_erp/services/billing_provider.dart';

import '../helpers/fixtures.dart';

void main() {
  late BillingNotifier notifier;

  setUp(() => notifier = BillingNotifier());
  tearDown(() => notifier.dispose());

  test('starts with an empty draft', () {
    expect(notifier.state.customer, isNull);
    expect(notifier.state.items, isEmpty);
    expect(notifier.state.invoiceNo, isNull);
  });

  group('selectCustomer', () {
    test('sets the customer without touching the items', () {
      notifier.addItem(buildProduct());
      notifier.selectCustomer(buildCustomer());

      expect(notifier.state.customer?.id, 'cust_001');
      expect(notifier.state.items, hasLength(1));
      expect(notifier.state.isValid, isTrue);
    });
  });

  group('addItem', () {
    test('adds a line item priced at the selling price', () {
      notifier.addItem(buildProduct(sellingPrice: 30), quantity: 4);

      expect(notifier.state.items, hasLength(1));
      expect(notifier.state.items.first.price, 30);
      expect(notifier.state.items.first.quantity, 4);
    });

    test('defaults the quantity to one', () {
      notifier.addItem(buildProduct());

      expect(notifier.state.items.first.quantity, 1);
    });

    test('accumulates the quantity for a product already in the draft', () {
      final product = buildProduct();

      notifier.addItem(product, quantity: 2);
      notifier.addItem(product, quantity: 3);

      expect(notifier.state.items, hasLength(1));
      expect(notifier.state.items.first.quantity, 5);
    });

    test('keeps distinct products as separate line items', () {
      notifier.addItem(buildProduct(id: 'prod_001'));
      notifier.addItem(buildProduct(id: 'prod_002', name: 'Onion'));

      expect(notifier.state.items, hasLength(2));
      expect(
        notifier.state.items.map((i) => i.product.id),
        ['prod_001', 'prod_002'],
      );
    });
  });

  group('updateItem / removeItem', () {
    test('replaces the item at the given index', () {
      notifier.addItem(buildProduct(id: 'prod_001'));
      notifier.addItem(buildProduct(id: 'prod_002'));

      notifier.updateItem(
        1,
        notifier.state.items[1].copyWith(quantity: 7, discount: 10),
      );

      expect(notifier.state.items[1].quantity, 7);
      expect(notifier.state.items[1].discount, 10);
      expect(notifier.state.items[0].quantity, 1);
    });

    test('removes the item at the given index', () {
      notifier.addItem(buildProduct(id: 'prod_001'));
      notifier.addItem(buildProduct(id: 'prod_002'));

      notifier.removeItem(0);

      expect(notifier.state.items, hasLength(1));
      expect(notifier.state.items.single.product.id, 'prod_002');
    });

    test('throws for an out-of-range index', () {
      expect(() => notifier.removeItem(0), throwsRangeError);
    });
  });

  group('totals', () {
    test('reflect the current line items', () {
      notifier.addItem(buildProduct(sellingPrice: 100), quantity: 10);

      expect(notifier.state.subtotal, 1000);
      expect(notifier.state.totalGst, 50);
      expect(notifier.state.grandTotal, 1050);
    });
  });

  group('clear', () {
    test('resets the draft', () {
      notifier
        ..selectCustomer(buildCustomer())
        ..addItem(buildProduct())
        ..finalize();

      notifier.clear();

      expect(notifier.state, const InvoiceDraft());
      expect(notifier.state.invoiceNo, isNull);
      expect(notifier.state.isValid, isFalse);
    });
  });

  group('invoice numbering', () {
    test('generates sequential invoice numbers', () {
      expect(notifier.generateInvoiceNo(), 'INV-2849');
      expect(notifier.generateInvoiceNo(), 'INV-2850');
    });

    test('finalize stamps the draft with a new invoice number', () {
      notifier
        ..selectCustomer(buildCustomer())
        ..addItem(buildProduct());

      final finalized = notifier.finalize();

      expect(finalized.invoiceNo, 'INV-2849');
      expect(notifier.state.invoiceNo, 'INV-2849');
      expect(finalized.items, hasLength(1));
      expect(finalized.customer?.id, 'cust_001');
    });

    test('a fresh notifier restarts the counter', () {
      notifier.generateInvoiceNo();
      final other = BillingNotifier();

      expect(other.generateInvoiceNo(), 'INV-2849');
      other.dispose();
    });
  });
}
