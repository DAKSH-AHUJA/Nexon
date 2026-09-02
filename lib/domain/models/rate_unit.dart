import 'package:decimal/decimal.dart';

import '../money.dart';

/// How a rate is applied to a line.
enum RateBasis { weight, bags, carets }

/// The unit a rate is quoted in, e.g. `1KG`, `5KG`, `BAG`, `CARET`.
///
/// The legacy prototype hard-coded `amount = weight * rate` and ignored the
/// unit column entirely, which produced wrong amounts as soon as a trader
/// quoted a rate per bag or per caret. [RateUnit] makes the unit meaningful
/// while keeping `1KG` behaving exactly as before.
class RateUnit {
  const RateUnit._(this.label, this.basis, this.perQuantity);

  /// The text shown and stored, e.g. `1KG`.
  final String label;

  /// Which quantity the rate multiplies.
  final RateBasis basis;

  /// How many units of [basis] one rate covers (`5KG` -> 5).
  final int perQuantity;

  static const RateUnit perKg = RateUnit._('1KG', RateBasis.weight, 1);
  static const RateUnit perBag = RateUnit._('BAG', RateBasis.bags, 1);
  static const RateUnit perCaret = RateUnit._('CARET', RateBasis.carets, 1);

  static const List<RateUnit> presets = [perKg, perBag, perCaret];

  static final RegExp _weightPattern = RegExp(r'^(\d+)\s*KGS?$');

  /// Parses a user-entered unit. Unknown or empty input falls back to [perKg],
  /// which preserves the behaviour of every existing entry.
  static RateUnit parse(String? input) {
    final text = (input ?? '').trim().toUpperCase().replaceAll(' ', '');
    if (text.isEmpty) return perKg;
    if (text == 'BAG' || text == 'BAGS') return perBag;
    if (text == 'CARET' || text == 'CARETS' || text == 'CRATE') return perCaret;

    final match = _weightPattern.firstMatch(text);
    if (match != null) {
      final per = int.parse(match.group(1)!);
      if (per <= 0) return perKg;
      return RateUnit._(text, RateBasis.weight, per);
    }
    if (text == 'KG') return perKg;
    return perKg;
  }

  /// The quantity this unit's rate is multiplied by.
  Decimal quantityFrom({
    required Decimal weight,
    required Decimal bags,
    required Decimal carets,
  }) {
    switch (basis) {
      case RateBasis.weight:
        return weight;
      case RateBasis.bags:
        return bags;
      case RateBasis.carets:
        return carets;
    }
  }

  /// Line amount, rounded to currency scale exactly once.
  Decimal amount({
    required Decimal weight,
    required Decimal bags,
    required Decimal carets,
    required Decimal rate,
  }) {
    final quantity = quantityFrom(weight: weight, bags: bags, carets: carets);
    final gross = quantity * rate;
    if (perQuantity == 1) return Money.roundCurrency(gross);
    return Money.roundCurrency(
      (gross / Decimal.fromInt(perQuantity))
          .toDecimal(scaleOnInfinitePrecision: 10),
    );
  }

  @override
  String toString() => label;

  @override
  bool operator ==(Object other) =>
      other is RateUnit &&
      other.label == label &&
      other.basis == basis &&
      other.perQuantity == perQuantity;

  @override
  int get hashCode => Object.hash(label, basis, perQuantity);
}
