import 'package:decimal/decimal.dart';

import '../models/purchase_lot.dart';
import '../models/sale_line.dart';
import '../money.dart';

/// A single validation failure, keyed by the form field it belongs to so the
/// UI can highlight the offending input instead of showing a generic error.
class ValidationError {
  const ValidationError(this.field, this.message);

  final String field;
  final String message;

  @override
  String toString() => '$field: $message';
}

class ValidationResult {
  const ValidationResult(this.errors);

  const ValidationResult.valid() : errors = const [];

  final List<ValidationError> errors;

  bool get isValid => errors.isEmpty;

  String? messageFor(String field) {
    for (final error in errors) {
      if (error.field == field) return error.message;
    }
    return null;
  }

  String get summary => errors.map((e) => e.message).join('\n');
}

/// Totals for a set of truck lots, used by the header strip and by reports.
class LotTotals {
  const LotTotals({
    required this.bags,
    required this.soldBags,
    required this.balanceBags,
    required this.carets,
    required this.soldCarets,
    required this.balanceCarets,
    required this.saleAmount,
  });

  final Decimal bags;
  final Decimal soldBags;
  final Decimal balanceBags;
  final Decimal carets;
  final Decimal soldCarets;
  final Decimal balanceCarets;
  final Decimal saleAmount;
}

/// The single source of truth for Purc/SPAT arithmetic and validation.
///
/// Pure Dart: no Flutter imports, no I/O. The same rules are intended to be
/// mirrored by the backend so a locally previewed amount always equals the
/// amount that is finally posted.
abstract final class TradingCalculator {
  /// Validates a truck purchase before it is saved.
  ///
  /// [existing] is the lot being edited, if any — its already-recorded sales
  /// constrain how far the bag count may be reduced.
  static ValidationResult validatePurchase({
    required String partyName,
    required String item,
    required Decimal bags,
    required Decimal carets,
    PurchaseLot? existing,
  }) {
    final errors = <ValidationError>[];

    if (partyName.trim().isEmpty) {
      errors.add(const ValidationError('partyName', 'Party name is required.'));
    }
    if (item.trim().isEmpty) {
      errors.add(const ValidationError('item', 'Item is required.'));
    }
    if (bags <= Money.zero) {
      errors.add(
        const ValidationError('bags', 'Bags must be greater than zero.'),
      );
    }
    if (carets < Money.zero) {
      errors.add(const ValidationError('carets', 'Caret cannot be negative.'));
    }

    if (existing != null) {
      final sold = existing.soldBags;
      if (bags > Money.zero && bags < sold) {
        errors.add(
          ValidationError(
            'bags',
            'Bags cannot be less than ${Money.formatQuantity(sold)} already '
                'sold from this truck.',
          ),
        );
      }
      final soldCarets = existing.soldCarets;
      if (carets >= Money.zero && carets < soldCarets) {
        errors.add(
          ValidationError(
            'carets',
            'Caret cannot be less than ${Money.formatQuantity(soldCarets)} '
                'already issued.',
          ),
        );
      }
    }

    return ValidationResult(errors);
  }

  /// Validates a customer sale against the remaining stock of [lot].
  ///
  /// [replacing] is the sale line being edited, whose quantities are added
  /// back to the available balance before the check.
  static ValidationResult validateSale({
    required PurchaseLot lot,
    required String partyName,
    required Decimal bags,
    required Decimal carets,
    required Decimal weight,
    required Decimal rate,
    SaleLine? replacing,
  }) {
    final errors = <ValidationError>[];

    if (partyName.trim().isEmpty) {
      errors.add(const ValidationError('partyName', 'Party name is required.'));
    }
    if (bags <= Money.zero) {
      errors.add(
        const ValidationError('bags', 'Bags must be greater than zero.'),
      );
    }
    if (weight <= Money.zero) {
      errors.add(
        const ValidationError('weight', 'Weight must be greater than zero.'),
      );
    }
    if (rate <= Money.zero) {
      errors.add(
        const ValidationError('rate', 'Rate must be greater than zero.'),
      );
    }
    if (carets < Money.zero) {
      errors.add(const ValidationError('carets', 'Caret cannot be negative.'));
    }

    final availableBags = lot.balanceBags + (replacing?.bags ?? Money.zero);
    if (bags > Money.zero && bags > availableBags) {
      errors.add(
        ValidationError(
          'bags',
          'Only ${Money.formatQuantity(availableBags)} bags remain on truck '
              '${lot.srNo}.',
        ),
      );
    }

    final availableCarets =
        lot.balanceCarets + (replacing?.carets ?? Money.zero);
    if (carets > Money.zero && carets > availableCarets) {
      errors.add(
        ValidationError(
          'carets',
          'Only ${Money.formatQuantity(availableCarets)} carets remain on '
              'truck ${lot.srNo}.',
        ),
      );
    }

    return ValidationResult(errors);
  }

  /// Rolls up a set of lots. Amounts are rounded once, at the end.
  static LotTotals totalsFor(Iterable<PurchaseLot> lots) {
    var bags = Money.zero;
    var soldBags = Money.zero;
    var carets = Money.zero;
    var soldCarets = Money.zero;
    var amount = Money.zero;

    for (final lot in lots) {
      bags += lot.bags;
      soldBags += lot.soldBags;
      carets += lot.totalCarets;
      soldCarets += lot.soldCarets;
      amount += lot.saleAmount;
    }

    return LotTotals(
      bags: bags,
      soldBags: soldBags,
      balanceBags: bags - soldBags,
      carets: carets,
      soldCarets: soldCarets,
      balanceCarets: carets - soldCarets,
      saleAmount: Money.roundCurrency(amount),
    );
  }

  /// Total value sold to one customer across every truck.
  static Decimal customerTotal(Iterable<PurchaseLot> lots, String partyName) {
    final target = partyName.trim().toUpperCase();
    var total = Money.zero;
    for (final lot in lots) {
      for (final sale in lot.sales) {
        if (sale.partyName.trim().toUpperCase() == target) {
          total += sale.amount;
        }
      }
    }
    return Money.roundCurrency(total);
  }
}
