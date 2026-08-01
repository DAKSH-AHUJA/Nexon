import 'package:equatable/equatable.dart';

enum StockStatus { inStock, lowStock, outOfStock }

class Product extends Equatable {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.currentStock,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.minimumStock,
    required this.description,
  });

  final String id;
  final String name;
  final String category;
  final String unit;
  final double currentStock;
  final double purchasePrice;
  final double sellingPrice;
  final double minimumStock;
  final String description;

  StockStatus get stockStatus {
    if (currentStock <= 0) return StockStatus.outOfStock;
    if (currentStock <= minimumStock) return StockStatus.lowStock;
    return StockStatus.inStock;
  }

  double get stockValue => currentStock * purchasePrice;

  Product copyWith({
    String? id,
    String? name,
    String? category,
    String? unit,
    double? currentStock,
    double? purchasePrice,
    double? sellingPrice,
    double? minimumStock,
    String? description,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      currentStock: currentStock ?? this.currentStock,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      minimumStock: minimumStock ?? this.minimumStock,
      description: description ?? this.description,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      unit: json['unit'] as String,
      currentStock: (json['currentStock'] as num).toDouble(),
      purchasePrice: (json['purchasePrice'] as num).toDouble(),
      sellingPrice: (json['sellingPrice'] as num).toDouble(),
      minimumStock: (json['minimumStock'] as num).toDouble(),
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'unit': unit,
        'currentStock': currentStock,
        'purchasePrice': purchasePrice,
        'sellingPrice': sellingPrice,
        'minimumStock': minimumStock,
        'description': description,
      };

  @override
  List<Object?> get props => [id, name, currentStock];
}

class InventoryTransaction extends Equatable {
  const InventoryTransaction({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.date,
    required this.note,
    required this.user,
  });

  final String id;
  final String productId;
  final String productName;
  final String type;
  final double quantity;
  final DateTime date;
  final String note;
  final String user;

  factory InventoryTransaction.fromJson(Map<String, dynamic> json) {
    return InventoryTransaction(
      id: json['id'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      type: json['type'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String? ?? '',
      user: json['user'] as String? ?? 'Admin',
    );
  }

  @override
  List<Object?> get props => [id, productId, type, date];
}
