import 'package:flutter_test/flutter_test.dart';
import 'package:nexon_erp/models/customer_model.dart';

void main() {
  Map<String, dynamic> customerJson() => {
        'id': 'cust_001',
        'name': 'Rajesh Traders',
        'phone': '9876543210',
        'email': 'rajesh@example.com',
        'gst': '29AABCF1234Z1Z5',
        'address': '12 Market Road',
        'city': 'Bengaluru',
        'outstandingBalance': 1500,
        'totalPurchases': 42000.5,
        'status': 'active',
        'createdAt': '2024-01-15T10:30:00.000',
        'ledger': [
          {
            'date': '2024-02-01T00:00:00.000',
            'description': 'Invoice INV-1001',
            'debit': 2000,
            'credit': 0,
            'balance': 2000,
          },
        ],
        'purchaseHistory': [
          {
            'invoiceNo': 'INV-1001',
            'date': '2024-02-01T00:00:00.000',
            'amount': 2000,
            'status': 'paid',
          },
        ],
      };

  group('Customer.fromJson', () {
    test('parses all fields including nested lists', () {
      final customer = Customer.fromJson(customerJson());

      expect(customer.id, 'cust_001');
      expect(customer.name, 'Rajesh Traders');
      expect(customer.phone, '9876543210');
      expect(customer.email, 'rajesh@example.com');
      expect(customer.gst, '29AABCF1234Z1Z5');
      expect(customer.address, '12 Market Road');
      expect(customer.city, 'Bengaluru');
      expect(customer.outstandingBalance, 1500);
      expect(customer.totalPurchases, 42000.5);
      expect(customer.status, 'active');
      expect(customer.createdAt, DateTime.parse('2024-01-15T10:30:00.000'));
      expect(customer.ledger, hasLength(1));
      expect(customer.ledger.first.description, 'Invoice INV-1001');
      expect(customer.purchaseHistory, hasLength(1));
      expect(customer.purchaseHistory.first.invoiceNo, 'INV-1001');
    });

    test('applies defaults for optional fields', () {
      final json = customerJson()
        ..remove('email')
        ..remove('gst')
        ..remove('status')
        ..remove('ledger')
        ..remove('purchaseHistory');

      final customer = Customer.fromJson(json);

      expect(customer.email, '');
      expect(customer.gst, '');
      expect(customer.status, 'active');
      expect(customer.ledger, isEmpty);
      expect(customer.purchaseHistory, isEmpty);
    });

    test('converts integer amounts to double', () {
      final customer = Customer.fromJson(customerJson());

      expect(customer.outstandingBalance, isA<double>());
      expect(customer.totalPurchases, isA<double>());
    });
  });

  group('Customer.toJson', () {
    test('round-trips through fromJson', () {
      final customer = Customer.fromJson(customerJson());
      final restored = Customer.fromJson(customer.toJson());

      expect(restored, customer);
      expect(restored.ledger, customer.ledger);
      expect(restored.purchaseHistory, customer.purchaseHistory);
      expect(restored.createdAt, customer.createdAt);
      expect(restored.totalPurchases, customer.totalPurchases);
    });
  });

  group('Customer.hasOutstanding', () {
    test('is true only for a positive balance', () {
      final customer = Customer.fromJson(customerJson());

      expect(customer.hasOutstanding, isTrue);
      expect(customer.copyWith(outstandingBalance: 0).hasOutstanding, isFalse);
      expect(
        customer.copyWith(outstandingBalance: -10).hasOutstanding,
        isFalse,
      );
    });
  });

  group('Customer.copyWith', () {
    test('overrides only the provided fields', () {
      final customer = Customer.fromJson(customerJson());
      final updated = customer.copyWith(name: 'New Name', city: 'Mysuru');

      expect(updated.name, 'New Name');
      expect(updated.city, 'Mysuru');
      expect(updated.id, customer.id);
      expect(updated.phone, customer.phone);
      expect(updated.outstandingBalance, customer.outstandingBalance);
      expect(updated.ledger, customer.ledger);
    });

    test('returns an equal instance when no arguments are given', () {
      final customer = Customer.fromJson(customerJson());

      expect(customer.copyWith(), customer);
    });
  });

  group('equality', () {
    test('compares on id, name, phone, balance and status', () {
      final customer = Customer.fromJson(customerJson());

      expect(customer, Customer.fromJson(customerJson()));
      expect(customer == customer.copyWith(city: 'Elsewhere'), isTrue);
      expect(customer == customer.copyWith(status: 'inactive'), isFalse);
      expect(customer == customer.copyWith(outstandingBalance: 1), isFalse);
    });
  });

  group('LedgerEntry', () {
    test('parses and serializes', () {
      final json = {
        'date': '2024-03-05T08:00:00.000',
        'description': 'Cash received',
        'debit': 0,
        'credit': 500,
        'balance': 1500.75,
      };

      final entry = LedgerEntry.fromJson(json);

      expect(entry.date, DateTime.parse('2024-03-05T08:00:00.000'));
      expect(entry.description, 'Cash received');
      expect(entry.debit, 0);
      expect(entry.credit, 500);
      expect(entry.balance, 1500.75);
      expect(LedgerEntry.fromJson(entry.toJson()), entry);
    });

    test('equality ignores balance', () {
      final entry = LedgerEntry(
        date: DateTime(2024, 3, 5),
        description: 'Cash received',
        debit: 0,
        credit: 500,
        balance: 100,
      );
      final other = LedgerEntry(
        date: DateTime(2024, 3, 5),
        description: 'Cash received',
        debit: 0,
        credit: 500,
        balance: 999,
      );

      expect(entry, other);
    });
  });

  group('PurchaseRecord', () {
    test('parses and serializes', () {
      final record = PurchaseRecord.fromJson({
        'invoiceNo': 'INV-2001',
        'date': '2024-04-01T00:00:00.000',
        'amount': 1234,
        'status': 'pending',
      });

      expect(record.invoiceNo, 'INV-2001');
      expect(record.date, DateTime.parse('2024-04-01T00:00:00.000'));
      expect(record.amount, 1234);
      expect(record.status, 'pending');
      expect(PurchaseRecord.fromJson(record.toJson()), record);
    });
  });
}
