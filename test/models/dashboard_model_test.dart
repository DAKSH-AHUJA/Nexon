import 'package:flutter_test/flutter_test.dart';
import 'package:nexon_erp/models/dashboard_model.dart';

void main() {
  Map<String, dynamic> dashboardJson() => {
        'stats': {
          'todaySales': 125000,
          'todayProfit': 18500.5,
          'todayCash': 42000,
          'outstandingAmount': 96000,
          'inventoryValue': 310000,
          'todayOrders': 24,
          'lowStockAlerts': 3,
        },
        'monthlySales': [
          {'month': 'Jan', 'sales': 100000, 'profit': 12000},
          {'month': 'Feb', 'sales': 115000, 'profit': 15500},
        ],
        'inventoryByCategory': [
          {'category': 'Vegetables', 'value': 200000, 'percentage': 64.5},
        ],
        'recentActivity': [
          {
            'id': 'act_001',
            'type': 'invoice',
            'title': 'Invoice created',
            'description': 'INV-2848 for Rajesh Traders',
            'timestamp': '2024-06-01T10:00:00.000',
            'icon': 'receipt',
          },
        ],
        'topCustomers': [
          {
            'id': 'cust_001',
            'name': 'Rajesh Traders',
            'totalPurchases': 42000,
            'outstanding': 1500,
            'orders': 12,
          },
        ],
        'recentBills': [
          {
            'id': 'bill_001',
            'invoiceNumber': 'INV-2848',
            'customerName': 'Rajesh Traders',
            'amount': 4500,
            'status': 'paid',
            'date': '2024-06-01T00:00:00.000',
          },
        ],
        'recentPayments': [
          {
            'id': 'pay_001',
            'reference': 'UPI-9911',
            'customerName': 'Rajesh Traders',
            'amount': 2500,
            'mode': 'UPI',
            'date': '2024-06-02T00:00:00.000',
          },
        ],
      };

  group('DashboardStats', () {
    test('parses numeric fields, widening ints to doubles', () {
      final stats = DashboardStats.fromJson(
        dashboardJson()['stats'] as Map<String, dynamic>,
      );

      expect(stats.todaySales, 125000);
      expect(stats.todaySales, isA<double>());
      expect(stats.todayProfit, 18500.5);
      expect(stats.todayCash, 42000);
      expect(stats.outstandingAmount, 96000);
      expect(stats.inventoryValue, 310000);
      expect(stats.todayOrders, 24);
      expect(stats.lowStockAlerts, 3);
    });

    test('equality compares every field', () {
      final json = dashboardJson()['stats'] as Map<String, dynamic>;
      final stats = DashboardStats.fromJson(json);

      expect(stats, DashboardStats.fromJson(dashboardJson()['stats'] as Map<String, dynamic>));
      expect(
        stats ==
            DashboardStats.fromJson({...json, 'todayOrders': 25}),
        isFalse,
      );
    });
  });

  group('chart data', () {
    test('MonthlySalesData parses month, sales and profit', () {
      final data = MonthlySalesData.fromJson(
        {'month': 'Mar', 'sales': 90000, 'profit': 8000.5},
      );

      expect(data.month, 'Mar');
      expect(data.sales, 90000);
      expect(data.profit, 8000.5);
    });

    test('InventoryCategoryData parses category, value and percentage', () {
      final data = InventoryCategoryData.fromJson(
        {'category': 'Fruits', 'value': 50000, 'percentage': 20},
      );

      expect(data.category, 'Fruits');
      expect(data.value, 50000);
      expect(data.percentage, 20);
    });
  });

  group('list item models', () {
    test('RecentActivity parses its timestamp', () {
      final activity = RecentActivity.fromJson(
        (dashboardJson()['recentActivity'] as List).first
            as Map<String, dynamic>,
      );

      expect(activity.id, 'act_001');
      expect(activity.type, 'invoice');
      expect(activity.title, 'Invoice created');
      expect(activity.description, 'INV-2848 for Rajesh Traders');
      expect(activity.timestamp, DateTime.parse('2024-06-01T10:00:00.000'));
      expect(activity.icon, 'receipt');
    });

    test('TopCustomer parses purchase and outstanding amounts', () {
      final customer = TopCustomer.fromJson(
        (dashboardJson()['topCustomers'] as List).first as Map<String, dynamic>,
      );

      expect(customer.id, 'cust_001');
      expect(customer.name, 'Rajesh Traders');
      expect(customer.totalPurchases, 42000);
      expect(customer.outstanding, 1500);
      expect(customer.orders, 12);
    });

    test('RecentBill parses invoice details', () {
      final bill = RecentBill.fromJson(
        (dashboardJson()['recentBills'] as List).first as Map<String, dynamic>,
      );

      expect(bill.id, 'bill_001');
      expect(bill.invoiceNumber, 'INV-2848');
      expect(bill.customerName, 'Rajesh Traders');
      expect(bill.amount, 4500);
      expect(bill.status, 'paid');
      expect(bill.date, DateTime.parse('2024-06-01T00:00:00.000'));
    });

    test('RecentPayment parses payment mode and reference', () {
      final payment = RecentPayment.fromJson(
        (dashboardJson()['recentPayments'] as List).first
            as Map<String, dynamic>,
      );

      expect(payment.id, 'pay_001');
      expect(payment.reference, 'UPI-9911');
      expect(payment.customerName, 'Rajesh Traders');
      expect(payment.amount, 2500);
      expect(payment.mode, 'UPI');
      expect(payment.date, DateTime.parse('2024-06-02T00:00:00.000'));
    });
  });

  group('DashboardData', () {
    test('parses the full aggregate', () {
      final data = DashboardData.fromJson(dashboardJson());

      expect(data.stats.todayOrders, 24);
      expect(data.monthlySales, hasLength(2));
      expect(data.monthlySales.last.month, 'Feb');
      expect(data.inventoryByCategory, hasLength(1));
      expect(data.recentActivity, hasLength(1));
      expect(data.topCustomers, hasLength(1));
      expect(data.recentBills, hasLength(1));
      expect(data.recentPayments, hasLength(1));
    });

    test('handles empty collections', () {
      final json = dashboardJson()
        ..['monthlySales'] = <dynamic>[]
        ..['inventoryByCategory'] = <dynamic>[]
        ..['recentActivity'] = <dynamic>[]
        ..['topCustomers'] = <dynamic>[]
        ..['recentBills'] = <dynamic>[]
        ..['recentPayments'] = <dynamic>[];

      final data = DashboardData.fromJson(json);

      expect(data.monthlySales, isEmpty);
      expect(data.recentPayments, isEmpty);
    });

    test('equality compares nested collections', () {
      expect(
        DashboardData.fromJson(dashboardJson()),
        DashboardData.fromJson(dashboardJson()),
      );
    });

    test('throws when a required section is missing', () {
      final json = dashboardJson()..remove('stats');

      expect(() => DashboardData.fromJson(json), throwsA(anything));
    });
  });
}
