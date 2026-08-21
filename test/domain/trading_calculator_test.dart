import 'package:flutter_test/flutter_test.dart';
import 'package:nexon_erp/domain/calculators/trading_calculator.dart';
import 'package:nexon_erp/domain/models/purchase_lot.dart';
import 'package:nexon_erp/domain/models/rate_unit.dart';
import 'package:nexon_erp/domain/models/sale_line.dart';
import 'package:nexon_erp/domain/money.dart';

SaleLine sale({
  String id = 'sale',
  int billNo = 1,
  String party = 'CUSTOMER',
  String bags = '1',
  String carets = '0',
  String weight = '0',
  String rate = '0',
  RateUnit? unit,
}) {
  return SaleLine(
    id: id,
    billNo: billNo,
    date: DateTime(2026, 8, 6),
    partyName: party,
    bags: dec(bags),
    carets: dec(carets),
    weight: dec(weight),
    rate: dec(rate),
    unit: unit ?? RateUnit.perKg,
  );
}

PurchaseLot lot({
  String bags = '10',
  String carets = '10',
  List<SaleLine> sales = const [],
}) {
  return PurchaseLot(
    id: 'lot',
    srNo: 1075,
    date: DateTime(2026, 8, 6),
    partyName: 'ABDULLA SETH RAIPUR',
    item: 'MUNGNA FALLI',
    bags: dec(bags),
    totalCarets: dec(carets),
    sales: sales,
  );
}

void main() {
  group('line amount by unit', () {
    test('per-kg rate multiplies weight (legacy behaviour preserved)', () {
      expect(
        sale(weight: '46', rate: '50').amount,
        dec('2300.00'),
      );
    });

    test('per-bag rate multiplies bags, not weight', () {
      expect(
        sale(bags: '3', weight: '142', rate: '500', unit: RateUnit.perBag)
            .amount,
        dec('1500.00'),
      );
    });

    test('per-caret rate multiplies carets', () {
      expect(
        sale(carets: '4', weight: '80', rate: '120', unit: RateUnit.perCaret)
            .amount,
        dec('480.00'),
      );
    });

    test('N-kg rate divides the weight by the quoted quantity', () {
      expect(
        sale(weight: '46', rate: '250', unit: RateUnit.parse('5KG')).amount,
        dec('2300.00'),
      );
    });

    test('unknown or blank unit falls back to per-kg', () {
      expect(RateUnit.parse(''), RateUnit.perKg);
      expect(RateUnit.parse('  1 kg '), RateUnit.perKg);
      expect(RateUnit.parse('bags'), RateUnit.perBag);
      expect(RateUnit.parse('CRATE'), RateUnit.perCaret);
    });

    test('amount is decimal-exact where double arithmetic drifts', () {
      // 0.1 * 3 == 0.30000000000000004 in binary floating point.
      final line = sale(weight: '0.1', rate: '3');
      expect(line.amount, dec('0.30'));

      var total = Money.zero;
      for (var i = 0; i < 10; i++) {
        total += sale(weight: '0.1', rate: '1').amount;
      }
      expect(total, dec('1.00'));
    });

    test('rounds half-up to two decimals exactly once', () {
      expect(sale(weight: '1.005', rate: '1').amount, dec('1.01'));
      expect(sale(weight: '2.5', rate: '1.111').amount, dec('2.78'));
    });
  });

  group('truck totals', () {
    final truck = lot(
      bags: '10',
      carets: '10',
      sales: [
        sale(
            id: 'a',
            billNo: 1,
            bags: '1',
            carets: '1',
            weight: '46',
            rate: '50'),
        sale(
            id: 'b',
            billNo: 2,
            bags: '3',
            carets: '3',
            weight: '142',
            rate: '50'),
        sale(
            id: 'c',
            billNo: 3,
            bags: '5',
            carets: '5',
            weight: '238',
            rate: '45'),
      ],
    );

    test('sold and balance bags', () {
      expect(truck.soldBags, dec('9'));
      expect(truck.balanceBags, dec('1'));
    });

    test('sold carets count carets, not bags', () {
      // The prototype summed sale.bags into the caret column.
      expect(truck.soldCarets, dec('9'));
      expect(truck.balanceCarets, dec('1'));
    });

    test('sale amount rolls up line amounts', () {
      // 2300 + 7100 + 10710
      expect(truck.saleAmount, dec('20110.00'));
    });

    test('totals across trucks', () {
      final totals =
          TradingCalculator.totalsFor([truck, lot(bags: '25', carets: '0')]);
      expect(totals.bags, dec('35'));
      expect(totals.soldBags, dec('9'));
      expect(totals.balanceBags, dec('26'));
      expect(totals.carets, dec('10'));
      expect(totals.balanceCarets, dec('1'));
      expect(totals.saleAmount, dec('20110.00'));
    });

    test('customer-wise total spans trucks', () {
      final other = lot(
        bags: '20',
        sales: [
          sale(id: 'd', party: 'BABA SOHAN GONDIA', weight: '10', rate: '10'),
          sale(id: 'e', party: 'OTHER PARTY', weight: '10', rate: '10'),
        ],
      );
      final second = lot(
        bags: '20',
        sales: [
          sale(id: 'f', party: 'Baba Sohan Gondia', weight: '4', rate: '25'),
        ],
      );
      expect(
        TradingCalculator.customerTotal(
          [truck, other, second],
          'baba sohan gondia',
        ),
        dec('200.00'),
      );
    });
  });

  group('sale validation', () {
    test('rejects selling more bags than remain', () {
      final truck =
          lot(bags: '10', sales: [sale(bags: '9', weight: '1', rate: '1')]);
      final result = TradingCalculator.validateSale(
        lot: truck,
        partyName: 'CUSTOMER',
        bags: dec('2'),
        carets: Money.zero,
        weight: dec('50'),
        rate: dec('40'),
      );
      expect(result.isValid, isFalse);
      expect(result.messageFor('bags'), contains('Only 1 bags remain'));
    });

    test('allows selling exactly the remaining bags', () {
      final truck =
          lot(bags: '10', sales: [sale(bags: '9', weight: '1', rate: '1')]);
      final result = TradingCalculator.validateSale(
        lot: truck,
        partyName: 'CUSTOMER',
        bags: dec('1'),
        carets: Money.zero,
        weight: dec('50'),
        rate: dec('40'),
      );
      expect(result.isValid, isTrue);
    });

    test('editing a line adds its own bags back to the available balance', () {
      final existing = sale(id: 'x', bags: '9', weight: '400', rate: '40');
      final truck = lot(bags: '10', sales: [existing]);
      final result = TradingCalculator.validateSale(
        lot: truck,
        partyName: 'CUSTOMER',
        bags: dec('10'),
        carets: Money.zero,
        weight: dec('450'),
        rate: dec('40'),
        replacing: existing,
      );
      expect(result.isValid, isTrue);
    });

    test('rejects issuing more carets than the truck brought', () {
      final result = TradingCalculator.validateSale(
        lot: lot(bags: '10', carets: '2'),
        partyName: 'CUSTOMER',
        bags: dec('1'),
        carets: dec('3'),
        weight: dec('50'),
        rate: dec('40'),
      );
      expect(result.messageFor('carets'), contains('Only 2 carets remain'));
    });

    test('rejects blank party, zero bags, weight and rate', () {
      final result = TradingCalculator.validateSale(
        lot: lot(),
        partyName: '   ',
        bags: Money.zero,
        carets: Money.zero,
        weight: Money.zero,
        rate: Money.zero,
      );
      expect(result.errors.length, 4);
      expect(result.messageFor('partyName'), isNotNull);
      expect(result.messageFor('bags'), isNotNull);
      expect(result.messageFor('weight'), isNotNull);
      expect(result.messageFor('rate'), isNotNull);
    });
  });

  group('purchase validation', () {
    test('rejects empty party, item and non-positive bags', () {
      final result = TradingCalculator.validatePurchase(
        partyName: '',
        item: '',
        bags: Money.zero,
        carets: Money.zero,
      );
      expect(result.errors.length, 3);
    });

    test('cannot reduce bags below what is already sold', () {
      final truck =
          lot(bags: '10', sales: [sale(bags: '6', weight: '1', rate: '1')]);
      final result = TradingCalculator.validatePurchase(
        partyName: 'SUPPLIER',
        item: 'TAMATAR',
        bags: dec('5'),
        carets: dec('10'),
        existing: truck,
      );
      expect(result.messageFor('bags'), contains('already sold'));
    });

    test('cannot reduce carets below what is already issued', () {
      final truck = lot(
        bags: '10',
        carets: '10',
        sales: [sale(bags: '6', carets: '6', weight: '1', rate: '1')],
      );
      final result = TradingCalculator.validatePurchase(
        partyName: 'SUPPLIER',
        item: 'TAMATAR',
        bags: dec('10'),
        carets: dec('4'),
        existing: truck,
      );
      expect(result.messageFor('carets'), contains('already issued'));
    });
  });

  group('money formatting', () {
    test('quantities drop trailing zeros, currency keeps two decimals', () {
      expect(Money.formatQuantity(dec('10.000')), '10');
      expect(Money.formatQuantity(dec('10.500')), '10.5');
      expect(Money.formatCurrency(dec('10.5')), '10.50');
    });

    test('tolerates thousands separators and blanks in input', () {
      expect(Money.tryParse('1,250.75'), dec('1250.75'));
      expect(Money.tryParse('  '), isNull);
      expect(Money.tryParse('abc'), isNull);
      expect(Money.parseOrZero(null), Money.zero);
    });
  });
}
