import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_context.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../domain/calculators/trading_calculator.dart';
import '../../domain/models/purchase_lot.dart';
import '../../domain/models/rate_unit.dart';
import '../../domain/models/sale_line.dart';
import '../../domain/money.dart';
import '../../services/purc_spat_provider.dart';

class PurcSpatDetailPage extends ConsumerStatefulWidget {
  const PurcSpatDetailPage({super.key, required this.lotId});
  final String lotId;

  @override
  ConsumerState<PurcSpatDetailPage> createState() => _PurcSpatDetailPageState();
}

class _PurcSpatDetailPageState extends ConsumerState<PurcSpatDetailPage> {
  final _salesScroll = ScrollController();

  @override
  void dispose() {
    _salesScroll.dispose();
    super.dispose();
  }

  PurchaseLot? get _lot {
    final lots = ref.read(purcSpatProvider);
    return lots.where((l) => l.id == widget.lotId).firstOrNull;
  }

  void _addSale() async {
    final lot = _lot;
    if (lot == null) return;
    if (lot.balanceBags <= Money.zero) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Truck ${lot.srNo} is fully sold.')));
      return;
    }
    final sale = await showDialog<SaleLine>(
      context: context,
      builder: (context) => _SaleDialog(lot: lot),
    );
    if (sale == null) return;
    final result = ref.read(purcSpatProvider.notifier).addSale(lot.id, sale);
    if (!result.isValid) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(result.summary)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lot = _lot;
    final responsive = Responsive(context);
    final isDark = context.isDarkMode;

    if (lot == null) {
      return Container(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        child: const Center(child: Text('Truck not found')),
      );
    }

    return Container(
      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(responsive.contentPadding),
            child: Row(
              children: [
                IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded)),
                Expanded(child: Text('Truck ${lot.srNo} — ${lot.item}', style: Theme.of(context).textTheme.headlineMedium)),
                ElevatedButton.icon(onPressed: _addSale, icon: const Icon(Icons.person_add_alt_1_outlined, size: 18), label: const Text('Add Customer')),
              ],
            ),
          ),
          _TruckDetailsCard(lot: lot, isDark: isDark),
          const SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: responsive.contentPadding),
            child: Text('Customers (${lot.sales.length})', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: lot.sales.isEmpty
                ? Center(child: Text('No customers added yet.', style: Theme.of(context).textTheme.bodyLarge))
                : ListView.builder(
                    controller: _salesScroll,
                    padding: EdgeInsets.symmetric(horizontal: responsive.contentPadding),
                    itemCount: lot.sales.length,
                    itemBuilder: (context, index) {
                      final sale = lot.sales[index];
                      return _CustomerCard(sale: sale, isDark: isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

class _TruckDetailsCard extends StatelessWidget {
  const _TruckDetailsCard({required this.lot, required this.isDark});
  final PurchaseLot lot;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          _DetailItem(label: 'Party', value: lot.partyName, isDark: isDark),
          _DetailItem(label: 'Bags', value: Money.formatQuantity(lot.bags), isDark: isDark),
          if (lot.totalCarets > Money.zero)
            _DetailItem(label: 'Carets', value: Money.formatQuantity(lot.totalCarets), isDark: isDark),
          _DetailItem(label: 'Sold', value: Money.formatQuantity(lot.soldBags), isDark: isDark),
          _DetailItem(label: 'Balance', value: Money.formatQuantity(lot.balanceBags), isDark: isDark),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({required this.label, required this.value, required this.isDark});
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.sale, required this.isDark});
  final SaleLine sale;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AppColors.blue500.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text('${sale.billNo}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.blue500))),
            ),
            const SizedBox(width: 12),
            Expanded(

class _SaleDialog extends StatefulWidget {
  const _SaleDialog({required this.lot, this.initialSale});
  final PurchaseLot lot;
  final SaleLine? initialSale;

  @override
  State<_SaleDialog> createState() => _SaleDialogState();
}

class _SaleDialogState extends State<_SaleDialog> {
  late final TextEditingController _party;
  late final TextEditingController _bags;
  late final TextEditingController _carets;
  late final TextEditingController _weight;
  late final TextEditingController _rate;
  late RateUnit _unit;
  String? _selectedMark;

  final _partyFocus = FocusNode();
  final _bagsFocus = FocusNode();
  final _caretsFocus = FocusNode();
  final _weightFocus = FocusNode();
  final _rateFocus = FocusNode();

  ValidationResult _validation = const ValidationResult.valid();

  @override
  void initState() {
    super.initState();
    final sale = widget.initialSale;
    _party = TextEditingController(text: sale?.partyName ?? '');
    _bags = TextEditingController(text: sale == null ? '' : Money.formatQuantity(sale.bags));
    _carets = TextEditingController(text: sale == null ? '0' : Money.formatQuantity(sale.carets));
    _weight = TextEditingController(text: sale == null ? '' : Money.formatQuantity(sale.weight));
    _rate = TextEditingController(text: sale == null ? '' : Money.formatQuantity(sale.rate));
    _unit = sale?.unit ?? RateUnit.perKg;
    _selectedMark = sale?.mark;
    for (final controller in [_bags, _carets, _weight, _rate]) {
      controller.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _party.dispose();
    _bags.dispose();
    _carets.dispose();
    _weight.dispose();
    _rate.dispose();
    _partyFocus.dispose();
    _bagsFocus.dispose();
    _caretsFocus.dispose();
    _weightFocus.dispose();
    _rateFocus.dispose();
    super.dispose();
  }

  Decimal? get _parsedBags => Decimal.tryParse(_bags.text.trim());
  Decimal? get _parsedCarets => Decimal.tryParse(_carets.text.trim());
  Decimal? get _parsedWeight => Decimal.tryParse(_weight.text.trim());
  Decimal? get _parsedRate => Decimal.tryParse(_rate.text.trim());

  Decimal get _liveAmount {
    final weight = _parsedWeight ?? Money.zero;
    final bags = _parsedBags ?? Money.zero;
    final carets = _parsedCarets ?? Money.zero;
    final rate = _parsedRate ?? Money.zero;
    return _unit.amount(weight: weight, bags: bags, carets: carets, rate: rate);
  }

  void _save() {
    final bags = _parsedBags;
    final carets = _parsedCarets;
    final weight = _parsedWeight;
    final rate = _parsedRate;
    if (bags == null || weight == null || rate == null) {
      setState(() { _validation = const ValidationResult(['Please enter valid numbers']); });
      return;
    }
    final result = TradingCalculator.validateSale(
      lot: widget.lot,
      partyName: _party.text.trim(),
      bags: bags,
      carets: carets ?? Money.zero,
      weight: weight,
      rate: rate,
    );
    if (!result.isValid) {
      setState(() => _validation = result);
      return;
    }
    final existing = widget.initialSale;
    Navigator.pop(
      context,
      SaleLine(
        id: existing?.id ?? 'sale-${DateTime.now().microsecondsSinceEpoch}',
        billNo: existing?.billNo ?? widget.lot.nextBillNo,
        date: existing?.date ?? DateTime.now(),
        partyName: _party.text.trim().toUpperCase(),

  @override
  Widget build(BuildContext context) {
    final availableBags = widget.lot.balanceBags;
    return AlertDialog(
      title: Text('Add Customer — Truck ${widget.lot.srNo}'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Available: ${Money.formatQuantity(availableBags)} bags', style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: (event) {
                  if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    _bagsFocus.requestFocus();
                  }
                },
                child: TextField(
                  controller: _party,
                  focusNode: _partyFocus,
                  autofocus: true,
                  decoration: InputDecoration(labelText: 'Party Name', errorText: _validation.messageFor('partyName')),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedMark,
                decoration: const InputDecoration(labelText: 'Mark'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('-')),
                  for (final mark in ['SVC', 'ARC', 'OTHER']) DropdownMenuItem(value: mark, child: Text(mark)),
                ],
                onChanged: (value) => setState(() => _selectedMark = value),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (event) {
                        if (event is KeyDownEvent) {
                          if (event.logicalKey == LogicalKeyboardKey.arrowDown) { _caretsFocus.requestFocus(); }
                          else if (event.logicalKey == LogicalKeyboardKey.arrowUp) { _partyFocus.requestFocus(); }
                        }
                      },
                      child: TextField(
                        controller: _bags,
                        focusNode: _bagsFocus,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: 'Bags', errorText: _validation.messageFor('bags')),
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (event) {
                        if (event is KeyDownEvent) {
                          if (event.logicalKey == LogicalKeyboardKey.arrowDown) { _weightFocus.requestFocus(); }
                          else if (event.logicalKey == LogicalKeyboardKey.arrowUp) { _bagsFocus.requestFocus(); }
                        }
                      },
                      child: TextField(
                        controller: _carets,
                        focusNode: _caretsFocus,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: 'Caret', errorText: _validation.messageFor('carets')),
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                  ),
                ],
              ),
        bags: bags,
        carets: carets ?? Money.zero,
        weight: weight,
        rate: rate,
        unit: _unit,
        mark: _selectedMark,
      ),
    );

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (event) {
                        if (event is KeyDownEvent) {
                          if (event.logicalKey == LogicalKeyboardKey.arrowDown) { _rateFocus.requestFocus(); }
                          else if (event.logicalKey == LogicalKeyboardKey.arrowUp) { _caretsFocus.requestFocus(); }
                        }
                      },
                      child: TextField(
                        controller: _weight,
                        focusNode: _weightFocus,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: 'Weight', errorText: _validation.messageFor('weight')),
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (event) {
                        if (event is KeyDownEvent) {
                          if (event.logicalKey == LogicalKeyboardKey.arrowUp) { _weightFocus.requestFocus(); }
                        }
                      },
                      child: TextField(
                        controller: _rate,
                        focusNode: _rateFocus,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: 'Rate', errorText: _validation.messageFor('rate')),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _save(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: RateUnit.presets.any((u) => u.label == _unit.label) ? _unit.label : RateUnit.perKg.label,
                decoration: const InputDecoration(labelText: 'Unit'),
                items: [for (final unit in RateUnit.presets) DropdownMenuItem(value: unit.label, child: Text(unit.label))],
                onChanged: (value) => setState(() => _unit = RateUnit.parse(value)),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: Text('Amount: ${Money.formatCurrency(_liveAmount)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
  }
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sale.partyName, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  if (sale.mark != null) ...[
                    const SizedBox(height: 2),
                    Text('Mark: ${sale.mark}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.emerald500)),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${Money.formatQuantity(sale.bags)} bags', style: Theme.of(context).textTheme.bodySmall),
                if (sale.carets > Money.zero)
                  Text('${Money.formatQuantity(sale.carets)} carets', style: Theme.of(context).textTheme.bodySmall),
                Text(Money.formatCurrency(sale.amount), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
} 
