import 'package:nexon_erp/services/data_service.dart';

/// In-memory [JsonDataService] so provider tests never touch asset bundles.
class FakeJsonDataService extends JsonDataService {
  FakeJsonDataService(this.files);

  final Map<String, Map<String, dynamic>> files;
  final List<String> requestedFiles = [];

  @override
  Future<Map<String, dynamic>> loadJson(String fileName) async {
    requestedFiles.add(fileName);
    final file = files[fileName];
    if (file == null) {
      throw StateError('No fake fixture registered for $fileName');
    }
    return file;
  }
}

Map<String, dynamic> customersFixture() => {
      'customers': [
        {
          'id': 'cust_001',
          'name': 'Rajesh Traders',
          'phone': '9876543210',
          'address': '12 Market Road',
          'city': 'Bengaluru',
          'outstandingBalance': 1500,
          'totalPurchases': 42000,
          'status': 'active',
          'createdAt': '2024-01-15T10:30:00.000',
        },
        {
          'id': 'cust_002',
          'name': 'Fresh Mart',
          'phone': '9812345678',
          'address': '4 MG Road',
          'city': 'Mysuru',
          'outstandingBalance': 0,
          'totalPurchases': 18000,
          'status': 'inactive',
          'createdAt': '2024-02-20T10:30:00.000',
        },
      ],
    };

Map<String, dynamic> productsFixture() => {
      'products': [
        {
          'id': 'prod_001',
          'name': 'Tomato',
          'category': 'Vegetables',
          'unit': 'kg',
          'currentStock': 120,
          'purchasePrice': 18,
          'sellingPrice': 25,
          'minimumStock': 50,
        },
        {
          'id': 'prod_002',
          'name': 'Apple',
          'category': 'Fruits',
          'unit': 'kg',
          'currentStock': 10,
          'purchasePrice': 90,
          'sellingPrice': 120,
          'minimumStock': 20,
        },
      ],
    };

Map<String, dynamic> inventoryFixture() => {
      'transactions': [
        {
          'id': 'txn_001',
          'productId': 'prod_001',
          'productName': 'Tomato',
          'type': 'stock_in',
          'quantity': 50,
          'date': '2024-05-01T09:15:00.000',
        },
      ],
    };

Map<String, dynamic> dashboardFixture() => {
      'stats': {
        'todaySales': 125000,
        'todayProfit': 18500,
        'todayCash': 42000,
        'outstandingAmount': 96000,
        'inventoryValue': 310000,
        'todayOrders': 24,
        'lowStockAlerts': 3,
      },
      'monthlySales': <dynamic>[],
      'inventoryByCategory': <dynamic>[],
      'recentActivity': <dynamic>[],
      'topCustomers': <dynamic>[],
      'recentBills': <dynamic>[],
      'recentPayments': <dynamic>[],
    };

Map<String, dynamic> suppliersFixture() => {
      'suppliers': [
        {
          'id': 'sup_001',
          'name': 'Green Farms',
          'phone': '9812345670',
          'address': 'APMC Yard',
          'city': 'Kolar',
          'outstandingPayment': 7500,
          'totalPurchases': 125000,
        },
        {
          'id': 'sup_002',
          'name': 'Hill Produce',
          'phone': '9800011122',
          'address': 'Station Road',
          'city': 'Hassan',
          'outstandingPayment': 0,
          'totalPurchases': 64000,
        },
      ],
    };
