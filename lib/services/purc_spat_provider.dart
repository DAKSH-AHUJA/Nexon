import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/calculators/trading_calculator.dart';
import '../domain/models/purchase_lot.dart';
import '../domain/models/rate_unit.dart';
import '../domain/models/sale_line.dart';
import '../domain/money.dart';

/// In-memory store for Purc/SPAT truck lots.
///
/// The prototype kept the lots inside `_PurcSpatPageState`, so every entry was
/// discarded the moment the operator navigated away from the screen. Holding
/// them in a provider keeps the data alive for the session and gives the cloud
/// migration a single seam to replace with a repository backed by the API.
class PurcSpatNotifier extends StateNotifier<List<PurchaseLot>> {
  PurcSpatNotifier() : super(_seed());

  int get nextSrNo => state.isEmpty
      ? 1
      : state.map((lot) => lot.srNo).reduce((a, b) => a > b ? a : b) + 1;

  void addLot(PurchaseLot lot) => state = [...state, lot];

  void replaceLot(PurchaseLot lot) => state = [
        for (final existing in state) existing.id == lot.id ? lot : existing,
      ];

  /// Appends a sale to [lotId]. Rejected when it would oversell the truck, so
  /// the invariant holds even if a caller skips the form validation.
  ValidationResult addSale(String lotId, SaleLine sale) {
    final lot = state.firstWhere((l) => l.id == lotId);
    final result = TradingCalculator.validateSale(
      lot: lot,
      partyName: sale.partyName,
      bags: sale.bags,
      carets: sale.carets,
      weight: sale.weight,
      rate: sale.rate,
    );
    if (!result.isValid) return result;

    replaceLot(lot.copyWith(sales: [...lot.sales, sale]));
    return const ValidationResult.valid();
  }

  ValidationResult replaceSale(String lotId, SaleLine sale) {
    final lot = state.firstWhere((l) => l.id == lotId);
    final previous = lot.sales.firstWhere((s) => s.id == sale.id);
    final result = TradingCalculator.validateSale(
      lot: lot,
      partyName: sale.partyName,
      bags: sale.bags,
      carets: sale.carets,
      weight: sale.weight,
      rate: sale.rate,
      replacing: previous,
    );
    if (!result.isValid) return result;

    replaceLot(
      lot.copyWith(
        sales: [
          for (final existing in lot.sales)
            existing.id == sale.id ? sale : existing,
        ],
      ),
    );
    return const ValidationResult.valid();
  }
}

final purcSpatProvider =
    StateNotifierProvider<PurcSpatNotifier, List<PurchaseLot>>((ref) {
  return PurcSpatNotifier();
});

/// Demo data carried over unchanged from the prototype so the screen still
/// opens with the familiar Raipur truck list.
List<PurchaseLot> _seed() {
  final date = DateTime(2026, 8, 6);
  return [
    PurchaseLot(
      id: 'lot-1075',
      srNo: 1075,
      date: date,
      partyName: 'ABDULLA SETH RAIPUR',
      item: 'MUNGNA FALLI',
      bags: decInt(10),
      totalCarets: decInt(10),
      sales: [
        SaleLine(
          id: 'sale-1075-1',
          billNo: 1,
          date: date,
          partyName: 'KOMAL BALLU GANJ GONDIA',
          bags: decInt(1),
          carets: decInt(1),
          weight: decInt(46),
          rate: decInt(50),
          unit: RateUnit.perKg,
        ),
        SaleLine(
          id: 'sale-1075-2',
          billNo: 2,
          date: date,
          partyName: 'BABA SOHAN GONDIA',
          bags: decInt(3),
          carets: decInt(3),
          weight: decInt(142),
          rate: decInt(50),
          unit: RateUnit.perKg,
        ),
        SaleLine(
          id: 'sale-1075-3',
          billNo: 3,
          date: date,
          partyName: 'SOHAN BAHE KATI 9421247',
          bags: decInt(5),
          carets: decInt(5),
          weight: decInt(238),
          rate: decInt(45),
          unit: RateUnit.perKg,
        ),
        SaleLine(
          id: 'sale-1075-4',
          billNo: 4,
          date: date,
          partyName: 'LAKHAN RKS GANJ 8888450',
          bags: decInt(1),
          carets: Money.zero,
          weight: decInt(48),
          rate: decInt(47),
          unit: RateUnit.perKg,
        ),
      ],
    ),
    PurchaseLot(
      id: 'lot-1076',
      srNo: 1076,
      date: date,
      partyName: 'ABDULLA SETH RAIPUR',
      item: 'PATTAGOBHI',
      bags: decInt(25),
      totalCarets: Money.zero,
      sales: const [],
    ),
    PurchaseLot(
      id: 'lot-1077',
      srNo: 1077,
      date: date,
      partyName: 'ABDULLA SETH RAIPUR',
      item: 'KATWAL',
      bags: decInt(40),
      totalCarets: Money.zero,
      sales: const [],
    ),
    PurchaseLot(
      id: 'lot-1078',
      srNo: 1078,
      date: date,
      partyName: 'ABDULLA SETH RAIPUR',
      item: 'SHIMLA MIRCHI',
      bags: decInt(10),
      totalCarets: Money.zero,
      sales: const [],
    ),
    PurchaseLot(
      id: 'lot-1079',
      srNo: 1079,
      date: date,
      partyName: 'VICKY NANDU ND',
      item: 'FOOL GOBHI',
      bags: decInt(20),
      totalCarets: decInt(10),
      sales: const [],
    ),
  ];
}
