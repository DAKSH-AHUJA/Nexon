import 'package:decimal/decimal.dart';

import '../money.dart';
import 'sale_line.dart';

/// One truck arrival: a lot of a single item bought from a supplier, out of
/// which customer-wise sales are made.
class PurchaseLot {
  const PurchaseLot({
    required this.id,
    required this.srNo,
    required this.date,
    required this.partyName,
    required this.item,
    required this.bags,
    required this.totalCarets,
    required this.sales,
  });

  final String id;
  final int srNo;
  final DateTime date;
  final String partyName;
  final String item;
  final Decimal bags;
  final Decimal totalCarets;
  final List<SaleLine> sales;

  Decimal get soldBags =>
      sales.fold(Money.zero, (sum, sale) => sum + sale.bags);

  Decimal get balanceBags => bags - soldBags;

  /// Carets issued to customers. The prototype summed `sale.bags` here, so the
  /// caret column reported the bag count instead of the caret count.
  Decimal get soldCarets =>
      sales.fold(Money.zero, (sum, sale) => sum + sale.carets);

  Decimal get balanceCarets => totalCarets - soldCarets;

  Decimal get soldWeight =>
      sales.fold(Money.zero, (sum, sale) => sum + sale.weight);

  /// Total value sold out of this truck.
  Decimal get saleAmount => Money.roundCurrency(
        sales.fold(Money.zero, (sum, sale) => sum + sale.amount),
      );

  bool get isFullySold => balanceBags <= Money.zero;

  int get nextBillNo => sales.isEmpty
      ? 1
      : sales.map((s) => s.billNo).reduce((a, b) => a > b ? a : b) + 1;

  PurchaseLot copyWith({
    int? srNo,
    DateTime? date,
    String? partyName,
    String? item,
    Decimal? bags,
    Decimal? totalCarets,
    List<SaleLine>? sales,
  }) {
    return PurchaseLot(
      id: id,
      srNo: srNo ?? this.srNo,
      date: date ?? this.date,
      partyName: partyName ?? this.partyName,
      item: item ?? this.item,
      bags: bags ?? this.bags,
      totalCarets: totalCarets ?? this.totalCarets,
      sales: sales ?? this.sales,
    );
  }
}
