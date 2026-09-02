import 'package:nexon_erp/models/customer_model.dart';
import 'package:nexon_erp/models/product_model.dart';

Product buildProduct({
  String id = 'prod_001',
  String name = 'Tomato',
  String category = 'Vegetables',
  double currentStock = 100,
  double purchasePrice = 18,
  double sellingPrice = 25,
  double minimumStock = 20,
}) {
  return Product(
    id: id,
    name: name,
    category: category,
    unit: 'kg',
    currentStock: currentStock,
    purchasePrice: purchasePrice,
    sellingPrice: sellingPrice,
    minimumStock: minimumStock,
    description: '',
  );
}

Customer buildCustomer({
  String id = 'cust_001',
  String name = 'Rajesh Traders',
  String phone = '9876543210',
  String city = 'Bengaluru',
  double outstandingBalance = 1000,
  double totalPurchases = 5000,
  String status = 'active',
  List<LedgerEntry> ledger = const [],
}) {
  return Customer(
    id: id,
    name: name,
    phone: phone,
    email: '$id@example.com',
    gst: '',
    address: '12 Market Road',
    city: city,
    outstandingBalance: outstandingBalance,
    totalPurchases: totalPurchases,
    status: status,
    createdAt: DateTime(2024, 1, 1),
    ledger: ledger,
  );
}
