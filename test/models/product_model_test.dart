import 'package:flutter_test/flutter_test.dart';
import 'package:nexon_erp/models/product_model.dart';

void main() {
  Map<String, dynamic> productJson() => {
        'id': 'prod_001',
        'name': 'Tomato',
        'category': 'Vegetables',
        'unit': 'kg',
        'currentStock': 120,
        'purchasePrice': 18.5,
        'sellingPrice': 25,
        'minimumStock': 50,
        'description': 'Grade A tomatoes',
      };

  Product product({
    double currentStock = 120,
    double minimumStock = 50,
    double purchasePrice = 18.5,
  }) {
    return Product(
      id: 'prod_001',
      name: 'Tomato',
      category: 'Vegetables',
      unit: 'kg',
      currentStock: currentStock,
      purchasePrice: purchasePrice,
      sellingPrice: 25,
      minimumStock: minimumStock,
      description: '',
    );
  }

  group('Product.fromJson', () {
    test('parses all fields', () {
      final parsed = Product.fromJson(productJson());

      expect(parsed.id, 'prod_001');
      expect(parsed.name, 'Tomato');
      expect(parsed.category, 'Vegetables');
      expect(parsed.unit, 'kg');
      expect(parsed.currentStock, 120);
      expect(parsed.purchasePrice, 18.5);
      expect(parsed.sellingPrice, 25);
      expect(parsed.minimumStock, 50);
      expect(parsed.description, 'Grade A tomatoes');
    });

    test('defaults description to an empty string', () {
      final json = productJson()..remove('description');

      expect(Product.fromJson(json).description, '');
    });

    test('round-trips through toJson', () {
      final parsed = Product.fromJson(productJson());
      final restored = Product.fromJson(parsed.toJson());

      expect(restored, parsed);
      expect(restored.purchasePrice, parsed.purchasePrice);
      expect(restored.minimumStock, parsed.minimumStock);
      expect(restored.description, parsed.description);
    });
  });

  group('Product.stockStatus', () {
    test('is outOfStock at or below zero stock', () {
      expect(product(currentStock: 0).stockStatus, StockStatus.outOfStock);
      expect(product(currentStock: -5).stockStatus, StockStatus.outOfStock);
    });

    test('is lowStock at or below the minimum stock', () {
      expect(product(currentStock: 50).stockStatus, StockStatus.lowStock);
      expect(product(currentStock: 10).stockStatus, StockStatus.lowStock);
    });

    test('is inStock above the minimum stock', () {
      expect(product(currentStock: 51).stockStatus, StockStatus.inStock);
    });

    test('treats a zero minimum as lowStock only when empty', () {
      expect(product(currentStock: 1, minimumStock: 0).stockStatus,
          StockStatus.inStock);
      expect(product(currentStock: 0, minimumStock: 0).stockStatus,
          StockStatus.outOfStock);
    });
  });

  group('Product.stockValue', () {
    test('multiplies current stock by purchase price', () {
      expect(product(currentStock: 10, purchasePrice: 12.5).stockValue, 125);
      expect(product(currentStock: 0).stockValue, 0);
    });
  });

  group('Product.copyWith', () {
    test('overrides only the provided fields', () {
      final updated = product().copyWith(currentStock: 5, name: 'Onion');

      expect(updated.currentStock, 5);
      expect(updated.name, 'Onion');
      expect(updated.id, 'prod_001');
      expect(updated.sellingPrice, 25);
    });

    test('returns an equal instance when no arguments are given', () {
      final original = product();

      expect(original.copyWith(), original);
    });
  });

  group('equality', () {
    test('compares on id, name and current stock', () {
      expect(product(), product());
      expect(product() == product(purchasePrice: 99), isTrue);
      expect(product() == product(currentStock: 1), isFalse);
    });
  });

  group('InventoryTransaction', () {
    test('parses all fields', () {
      final txn = InventoryTransaction.fromJson({
        'id': 'txn_001',
        'productId': 'prod_001',
        'productName': 'Tomato',
        'type': 'stock_in',
        'quantity': 20,
        'date': '2024-05-01T09:15:00.000',
        'note': 'Fresh arrival',
        'user': 'Rajesh',
      });

      expect(txn.id, 'txn_001');
      expect(txn.productId, 'prod_001');
      expect(txn.productName, 'Tomato');
      expect(txn.type, 'stock_in');
      expect(txn.quantity, 20);
      expect(txn.date, DateTime.parse('2024-05-01T09:15:00.000'));
      expect(txn.note, 'Fresh arrival');
      expect(txn.user, 'Rajesh');
    });

    test('defaults note and user', () {
      final txn = InventoryTransaction.fromJson({
        'id': 'txn_002',
        'productId': 'prod_001',
        'productName': 'Tomato',
        'type': 'stock_out',
        'quantity': 5,
        'date': '2024-05-02T09:15:00.000',
      });

      expect(txn.note, '');
      expect(txn.user, 'Admin');
    });
  });
}
