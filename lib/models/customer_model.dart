import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.gst,
    required this.address,
    required this.city,
    required this.outstandingBalance,
    required this.totalPurchases,
    required this.status,
    required this.createdAt,
    this.ledger = const [],
    this.purchaseHistory = const [],
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final String gst;
  final String address;
  final String city;
  final double outstandingBalance;
  final double totalPurchases;
  final String status;
  final DateTime createdAt;
  final List<LedgerEntry> ledger;
  final List<PurchaseRecord> purchaseHistory;

  bool get hasOutstanding => outstandingBalance > 0;

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? gst,
    String? address,
    String? city,
    double? outstandingBalance,
    double? totalPurchases,
    String? status,
    DateTime? createdAt,
    List<LedgerEntry>? ledger,
    List<PurchaseRecord>? purchaseHistory,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      gst: gst ?? this.gst,
      address: address ?? this.address,
      city: city ?? this.city,
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      ledger: ledger ?? this.ledger,
      purchaseHistory: purchaseHistory ?? this.purchaseHistory,
    );
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String? ?? '',
      gst: json['gst'] as String? ?? '',
      address: json['address'] as String,
      city: json['city'] as String,
      outstandingBalance: (json['outstandingBalance'] as num).toDouble(),
      totalPurchases: (json['totalPurchases'] as num).toDouble(),
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['createdAt'] as String),
      ledger: (json['ledger'] as List<dynamic>? ?? [])
          .map((e) => LedgerEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      purchaseHistory: (json['purchaseHistory'] as List<dynamic>? ?? [])
          .map((e) => PurchaseRecord.fromJson(e as Map<String, dynamic>))
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
        'outstandingBalance': outstandingBalance,
        'totalPurchases': totalPurchases,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'ledger': ledger.map((e) => e.toJson()).toList(),
        'purchaseHistory': purchaseHistory.map((e) => e.toJson()).toList(),
      };

  @override
  List<Object?> get props => [id, name, phone, outstandingBalance, status];
}

class LedgerEntry extends Equatable {
  const LedgerEntry({
    required this.date,
    required this.description,
    required this.debit,
    required this.credit,
    required this.balance,
  });

  final DateTime date;
  final String description;
  final double debit;
  final double credit;
  final double balance;

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    return LedgerEntry(
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String,
      debit: (json['debit'] as num).toDouble(),
      credit: (json['credit'] as num).toDouble(),
      balance: (json['balance'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'description': description,
        'debit': debit,
        'credit': credit,
        'balance': balance,
      };

  @override
  List<Object?> get props => [date, description, debit, credit];
}

class PurchaseRecord extends Equatable {
  const PurchaseRecord({
    required this.invoiceNo,
    required this.date,
    required this.amount,
    required this.status,
  });

  final String invoiceNo;
  final DateTime date;
  final double amount;
  final String status;

  factory PurchaseRecord.fromJson(Map<String, dynamic> json) {
    return PurchaseRecord(
      invoiceNo: json['invoiceNo'] as String,
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'invoiceNo': invoiceNo,
        'date': date.toIso8601String(),
        'amount': amount,
        'status': status,
      };

  @override
  List<Object?> get props => [invoiceNo, date, amount];
}
