import 'package:equatable/equatable.dart';

/// Dashboard KPI statistics.
class DashboardStats extends Equatable {
  const DashboardStats({
    required this.todaySales,
    required this.todayProfit,
    required this.todayCash,
    required this.outstandingAmount,
    required this.inventoryValue,
    required this.todayOrders,
    required this.lowStockAlerts,
  });

  final double todaySales;
  final double todayProfit;
  final double todayCash;
  final double outstandingAmount;
  final double inventoryValue;
  final int todayOrders;
  final int lowStockAlerts;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      todaySales: (json['todaySales'] as num).toDouble(),
      todayProfit: (json['todayProfit'] as num).toDouble(),
      todayCash: (json['todayCash'] as num).toDouble(),
      outstandingAmount: (json['outstandingAmount'] as num).toDouble(),
      inventoryValue: (json['inventoryValue'] as num).toDouble(),
      todayOrders: json['todayOrders'] as int,
      lowStockAlerts: json['lowStockAlerts'] as int,
    );
  }

  @override
  List<Object?> get props => [
        todaySales,
        todayProfit,
        todayCash,
        outstandingAmount,
        inventoryValue,
        todayOrders,
        lowStockAlerts,
      ];
}

class MonthlySalesData extends Equatable {
  const MonthlySalesData({
    required this.month,
    required this.sales,
    required this.profit,
  });

  final String month;
  final double sales;
  final double profit;

  factory MonthlySalesData.fromJson(Map<String, dynamic> json) {
    return MonthlySalesData(
      month: json['month'] as String,
      sales: (json['sales'] as num).toDouble(),
      profit: (json['profit'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [month, sales, profit];
}

class InventoryCategoryData extends Equatable {
  const InventoryCategoryData({
    required this.category,
    required this.value,
    required this.percentage,
  });

  final String category;
  final double value;
  final double percentage;

  factory InventoryCategoryData.fromJson(Map<String, dynamic> json) {
    return InventoryCategoryData(
      category: json['category'] as String,
      value: (json['value'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [category, value, percentage];
}

class RecentActivity extends Equatable {
  const RecentActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.icon,
  });

  final String id;
  final String type;
  final String title;
  final String description;
  final DateTime timestamp;
  final String icon;

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      icon: json['icon'] as String,
    );
  }

  @override
  List<Object?> get props => [id, type, title, description, timestamp, icon];
}

class TopCustomer extends Equatable {
  const TopCustomer({
    required this.id,
    required this.name,
    required this.totalPurchases,
    required this.outstanding,
    required this.orders,
  });

  final String id;
  final String name;
  final double totalPurchases;
  final double outstanding;
  final int orders;

  factory TopCustomer.fromJson(Map<String, dynamic> json) {
    return TopCustomer(
      id: json['id'] as String,
      name: json['name'] as String,
      totalPurchases: (json['totalPurchases'] as num).toDouble(),
      outstanding: (json['outstanding'] as num).toDouble(),
      orders: json['orders'] as int,
    );
  }

  @override
  List<Object?> get props => [id, name, totalPurchases, outstanding, orders];
}

class RecentBill extends Equatable {
  const RecentBill({
    required this.id,
    required this.invoiceNumber,
    required this.customerName,
    required this.amount,
    required this.status,
    required this.date,
  });

  final String id;
  final String invoiceNumber;
  final String customerName;
  final double amount;
  final String status;
  final DateTime date;

  factory RecentBill.fromJson(Map<String, dynamic> json) {
    return RecentBill(
      id: json['id'] as String,
      invoiceNumber: json['invoiceNumber'] as String,
      customerName: json['customerName'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }

  @override
  List<Object?> get props =>
      [id, invoiceNumber, customerName, amount, status, date];
}

class RecentPayment extends Equatable {
  const RecentPayment({
    required this.id,
    required this.reference,
    required this.customerName,
    required this.amount,
    required this.mode,
    required this.date,
  });

  final String id;
  final String reference;
  final String customerName;
  final double amount;
  final String mode;
  final DateTime date;

  factory RecentPayment.fromJson(Map<String, dynamic> json) {
    return RecentPayment(
      id: json['id'] as String,
      reference: json['reference'] as String,
      customerName: json['customerName'] as String,
      amount: (json['amount'] as num).toDouble(),
      mode: json['mode'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }

  @override
  List<Object?> get props =>
      [id, reference, customerName, amount, mode, date];
}

/// Complete dashboard data aggregate.
class DashboardData extends Equatable {
  const DashboardData({
    required this.stats,
    required this.monthlySales,
    required this.inventoryByCategory,
    required this.recentActivity,
    required this.topCustomers,
    required this.recentBills,
    required this.recentPayments,
  });

  final DashboardStats stats;
  final List<MonthlySalesData> monthlySales;
  final List<InventoryCategoryData> inventoryByCategory;
  final List<RecentActivity> recentActivity;
  final List<TopCustomer> topCustomers;
  final List<RecentBill> recentBills;
  final List<RecentPayment> recentPayments;

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      stats: DashboardStats.fromJson(json['stats'] as Map<String, dynamic>),
      monthlySales: (json['monthlySales'] as List)
          .map((e) => MonthlySalesData.fromJson(e as Map<String, dynamic>))
          .toList(),
      inventoryByCategory: (json['inventoryByCategory'] as List)
          .map((e) => InventoryCategoryData.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentActivity: (json['recentActivity'] as List)
          .map((e) => RecentActivity.fromJson(e as Map<String, dynamic>))
          .toList(),
      topCustomers: (json['topCustomers'] as List)
          .map((e) => TopCustomer.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentBills: (json['recentBills'] as List)
          .map((e) => RecentBill.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentPayments: (json['recentPayments'] as List)
          .map((e) => RecentPayment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        stats,
        monthlySales,
        inventoryByCategory,
        recentActivity,
        topCustomers,
        recentBills,
        recentPayments,
      ];
}
