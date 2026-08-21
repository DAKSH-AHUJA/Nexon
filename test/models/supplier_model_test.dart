import 'package:flutter_test/flutter_test.dart';
import 'package:nexon_erp/models/supplier_model.dart';

void main() {
  Map<String, dynamic> supplierJson() => {
        'id': 'sup_001',
        'name': 'Green Farms',
        'phone': '9812345670',
        'email': 'sales@greenfarms.com',
        'gst': '29AABCG1234Z1Z5',
        'address': 'Plot 8, APMC Yard',
        'city': 'Kolar',
        'outstandingPayment': 7500,
        'totalPurchases': 125000,
        'status': 'active',
        'purchaseHistory': [
          {
            'poNo': 'PO-3001',
            'date': '2024-03-10T00:00:00.000',
            'amount': 12000,
            'status': 'paid',
          },
        ],
      };

  group('Supplier.fromJson', () {
    test('parses all fields including purchase history', () {
      final supplier = Supplier.fromJson(supplierJson());

      expect(supplier.id, 'sup_001');
      expect(supplier.name, 'Green Farms');
      expect(supplier.phone, '9812345670');
      expect(supplier.email, 'sales@greenfarms.com');
      expect(supplier.gst, '29AABCG1234Z1Z5');
      expect(supplier.address, 'Plot 8, APMC Yard');
      expect(supplier.city, 'Kolar');
      expect(supplier.outstandingPayment, 7500);
      expect(supplier.totalPurchases, 125000);
      expect(supplier.status, 'active');
      expect(supplier.purchaseHistory, hasLength(1));
      expect(supplier.purchaseHistory.first.poNo, 'PO-3001');
    });

    test('applies defaults for optional fields', () {
      final json = supplierJson()
        ..remove('email')
        ..remove('gst')
        ..remove('status')
        ..remove('purchaseHistory');

      final supplier = Supplier.fromJson(json);

      expect(supplier.email, '');
      expect(supplier.gst, '');
      expect(supplier.status, 'active');
      expect(supplier.purchaseHistory, isEmpty);
    });

    test('round-trips through toJson', () {
      final supplier = Supplier.fromJson(supplierJson());
      final restored = Supplier.fromJson(supplier.toJson());

      expect(restored, supplier);
      expect(restored.city, supplier.city);
      expect(restored.totalPurchases, supplier.totalPurchases);
      expect(restored.purchaseHistory, supplier.purchaseHistory);
    });
  });

  group('Supplier.copyWith', () {
    test('overrides only the provided fields', () {
      final supplier = Supplier.fromJson(supplierJson());
      final updated =
          supplier.copyWith(outstandingPayment: 0, status: 'inactive');

      expect(updated.outstandingPayment, 0);
      expect(updated.status, 'inactive');
      expect(updated.name, supplier.name);
      expect(updated.purchaseHistory, supplier.purchaseHistory);
      expect(supplier.copyWith(), supplier);
    });
  });

  group('equality', () {
    test('compares on id, name and outstanding payment', () {
      final supplier = Supplier.fromJson(supplierJson());

      expect(supplier, Supplier.fromJson(supplierJson()));
      expect(supplier == supplier.copyWith(city: 'Hassan'), isTrue);
      expect(supplier == supplier.copyWith(outstandingPayment: 1), isFalse);
    });
  });

  group('SupplierPurchase', () {
    test('parses and serializes', () {
      final purchase = SupplierPurchase.fromJson({
        'poNo': 'PO-4001',
        'date': '2024-06-01T00:00:00.000',
        'amount': 900.25,
        'status': 'pending',
      });

      expect(purchase.poNo, 'PO-4001');
      expect(purchase.date, DateTime.parse('2024-06-01T00:00:00.000'));
      expect(purchase.amount, 900.25);
      expect(purchase.status, 'pending');
      expect(SupplierPurchase.fromJson(purchase.toJson()), purchase);
    });
  });
}
