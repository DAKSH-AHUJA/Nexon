import 'package:equatable/equatable.dart';

class Supplier extends Equatable {
  const Supplier({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.gst,
    required this.address,
    required this.city,
    required this.outstandingPayment,
    required this.totalPurchases,
    required this.status,
    this.purchaseHistory = const [],
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final String gst;
  final String address;
  final String city;
  final double outstandingPayment;
  final double totalPurchases;
  final String status;
  final List<SupplierPurchase> purchaseHistory;

  Supplier copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? gst,
    String? address,
    String? city,
    double? outstandingPayment,
    double? totalPurchases,
    String? status,
    List<SupplierPurchase>? purchaseHistory,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      gst: gst ?? this.gst,
      address: address ?? this.address,
      city: city ?? this.city,
      outstandingPayment: outstandingPayment ?? this.outstandingPayment,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      status: status ?? this.status,
      purchaseHistory: purchaseHistory ?? this.purchaseHistory,
    );
  }

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String? ?? '',
      gst: json['gst'] as String? ?? '',
      address: json['address'] as String,
      city: json['city'] as String,
      outstandingPayment: (json['outstandingPayment'] as num).toDouble(),
      totalPurchases: (json['totalPurchases'] as num).toDouble(),
      status: json['status'] as String? ?? 'active',
      purchaseHistory: (json['purchaseHistory'] as List<dynamic>? ?? [])
          .map((e) => SupplierPurchase.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'gst': gst,
        'address': address,
        'city': city,
        'outstandingPayment': outstandingPayment,
        'totalPurchases': totalPurchases,
        'status': status,
        'purchaseHistory': purchaseHistory.map((e) => e.toJson()).toList(),
      };

  @override
  List<Object?> get props => [id, name, outstandingPayment];
}

class SupplierPurchase extends Equatable {
  const SupplierPurchase({
    required this.poNo,
    required this.date,
    required this.amount,
    required this.status,
  });

  final String poNo;
  final DateTime date;
  final double amount;
  final String status;

  factory SupplierPurchase.fromJson(Map<String, dynamic> json) {
    return SupplierPurchase(
      poNo: json['poNo'] as String,
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'poNo': poNo,
        'date': date.toIso8601String(),
        'amount': amount,
        'status': status,
      };

  @override
  List<Object?> get props => [poNo, date, amount];
}
