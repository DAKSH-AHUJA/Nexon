import 'package:decimal/decimal.dart';

/// Decimal-safe helpers for every financial value in the ERP.
///
/// Binary floating point (`double`) must never be used for currency,
/// weights or quantities: `0.1 + 0.2 != 0.3` silently corrupts day-end
/// totals once thousands of lines are summed. All amounts are [Decimal]
/// and are rounded exactly once, at the point of display or storage.
abstract final class Money {
  static final Decimal zero = Decimal.zero;

  /// Scale used for stored currency amounts.
  static const int currencyScale = 2;

  /// Scale used for weights (kg with gram precision).
  static const int weightScale = 3;

  /// Parses user input, tolerating blanks, spaces and thousands separators.
  /// Returns `null` when the text is not a valid number.
  static Decimal? tryParse(String? input) {
    if (input == null) return null;
    final cleaned = input.trim().replaceAll(',', '').replaceAll(' ', '');
    if (cleaned.isEmpty) return null;
    return Decimal.tryParse(cleaned);
  }

  /// Parses user input, falling back to zero.
  static Decimal parseOrZero(String? input) => tryParse(input) ?? zero;

  /// Rounds half-up to [scale] decimal places.
  static Decimal round(Decimal value, int scale) => value.round(scale: scale);

  /// Rounds a currency amount to two decimal places.
  static Decimal roundCurrency(Decimal value) => round(value, currencyScale);

  /// Formats a currency amount with a fixed two decimal places.
  static String formatCurrency(Decimal value) =>
      roundCurrency(value).toStringAsFixed(currencyScale);

  /// Formats a quantity, dropping the decimal part when it is a whole number.
  static String formatQuantity(Decimal value) {
    final rounded = round(value, weightScale);
    if (rounded.isInteger) return rounded.toBigInt().toString();
    return rounded
        .toStringAsFixed(weightScale)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}

/// Convenience constructor used throughout the domain layer and tests.
Decimal dec(String value) => Decimal.parse(value);

/// Convenience constructor for whole numbers.
Decimal decInt(int value) => Decimal.fromInt(value);
