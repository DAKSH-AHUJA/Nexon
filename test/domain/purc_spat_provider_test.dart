import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexon_erp/domain/models/rate_unit.dart';
import 'package:nexon_erp/domain/models/sale_line.dart';
import 'package:nexon_erp/domain/money.dart';
import 'package:nexon_erp/services/purc_spat_provider.dart';

SaleLine saleOf(String id, String bags) => SaleLine(
      id: id,
      billNo: 9,
      date: DateTime(2026, 8, 6),
      partyName: 'NEW CUSTOMER',
      bags: dec(bags),
      carets: Money.zero,
      weight: dec('40'),
      rate: dec('45'),
      unit: RateUnit.perKg,
    );

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  PurcSpatNotifier notifier() => container.read(purcSpatProvider.notifier);

  test('seed data keeps the prototype truck list', () {
    final lots = container.read(purcSpatProvider);
    expect(lots.length, 5);
    expect(lots.first.srNo, 1075);
    expect(lots.first.soldBags, dec('10'));
    expect(lots.first.balanceBags, Money.zero);
  });

  test('next Sr. No. continues from the highest existing truck', () {
    expect(notifier().nextSrNo, 1080);
  });

  test('rejects a sale that would oversell the truck', () {
    // Truck 1075 is fully sold in the seed data.
    final result = notifier().addSale('lot-1075', saleOf('new', '1'));
    expect(result.isValid, isFalse);
    expect(container.read(purcSpatProvider).first.sales.length, 4);
  });

  test('accepts a sale within the remaining balance', () {
    final result = notifier().addSale('lot-1076', saleOf('new', '5'));
    expect(result.isValid, isTrue);

    final lot =
        container.read(purcSpatProvider).firstWhere((l) => l.id == 'lot-1076');
    expect(lot.soldBags, dec('5'));
    expect(lot.balanceBags, dec('20'));
  });

  test('editing a sale is validated against the freed-up balance', () {
    notifier().addSale('lot-1076', saleOf('edit-me', '25'));
    final result = notifier().replaceSale('lot-1076', saleOf('edit-me', '20'));
    expect(result.isValid, isTrue);

    final lot =
        container.read(purcSpatProvider).firstWhere((l) => l.id == 'lot-1076');
    expect(lot.balanceBags, dec('5'));
  });

  test('entries survive across reads of the provider', () {
    notifier().addSale('lot-1077', saleOf('kept', '3'));
    final lots = container.read(purcSpatProvider);
    expect(lots.firstWhere((l) => l.id == 'lot-1077').sales.length, 1);
  });
}
