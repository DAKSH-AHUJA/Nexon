import 'package:decimal/decimal.dart';

import '../money.dart';
import 'rate_unit.dart';

/// A customer-wise sale of bags out of a single truck lot.
///
/// Immutable and free of any Flutter dependency so the same type is reused by
/// the Windows client, the future tablet build, the sync layer and the tests.
class SaleLine {
  SaleLine({
    required this.id,
    required this.billNo,
    required this.date,
    required this.partyName,
    required this.bags,
    required this.weight,
    required this.rate,
    required this.unit,
    Decimal? carets,
  }) : carets = carets ?? Money.zero;

  final String id;
  final int billNo;
  final DateTime date;
  final String partyName;
  final Decimal bags;

  /// Carets handed over with this sale. Tracked separately from [bags]:
  /// a supplier may send goods loose in bags or packed in carets, and the
  /// caret balance is a physical asset that must come back.
  final Decimal carets;
  final Decimal weight;
  final Decimal rate;
  final RateUnit unit;

  /// Line amount. Always derived — never stored independently — so the UI,
  /// the truck totals and the reports cannot disagree.
  Decimal get amount => unit.amount(
        weight: weight,
        bags: bags,
        carets: carets,
        rate: rate,
      );

  SaleLine copyWith({
    int? billNo,
    DateTime? date,
    String? partyName,
    Decimal? bags,
    Decimal? carets,
    Decimal? weight,
    Decimal? rate,
    RateUnit? unit,
  }) {
    return SaleLine(
      id: id,
      billNo: billNo ?? this.billNo,
      date: date ?? this.date,
      partyName: partyName ?? this.partyName,
      bags: bags ?? this.bags,
      carets: carets ?? this.carets,
      weight: weight ?? this.weight,
      rate: rate ?? this.rate,
      unit: unit ?? this.unit,
    );
  }
}
