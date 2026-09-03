import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_context.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/page_header.dart';
import '../../domain/calculators/trading_calculator.dart';
import '../../domain/models/purchase_lot.dart';
import '../../domain/models/rate_unit.dart';
import '../../domain/models/sale_line.dart';
import '../../domain/money.dart';
import '../../services/purc_spat_provider.dart';

class PurcSpatPage extends ConsumerStatefulWidget {
  const PurcSpatPage({super.key});

  @override
  ConsumerState<PurcSpatPage> createState() => _PurcSpatPageState();
}

class _PurcSpatPageState extends ConsumerState<PurcSpatPage> {
  final _purchaseScroll = ScrollController();
  final _salesScroll = ScrollController();
  final _purchaseFocus = FocusNode(debugLabel: 'Purchase truck list');
  final _salesFocus = FocusNode(debugLabel: 'Customer sale list');

  int _selectedLotIndex = 0;
  int _selectedSaleIndex = 0;
  bool _salesAreaActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _purchaseFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _purchaseScroll.dispose();
    _salesScroll.dispose();
    _purchaseFocus.dispose();
    _salesFocus.dispose();
    super.dispose();
  }

  List<PurchaseLot> get _lots => ref.read(purcSpatProvider);

  PurchaseLot? get _selectedLot {
    final lots = _lots;
    if (lots.isEmpty) return null;
    return lots[_selectedLotIndex.clamp(0, lots.length - 1)];
  }

  void _move(int delta) {
    final lot = _selectedLot;
    if (lot == null) return;

    if (_salesAreaActive) {
      final sales = lot.sales;
      if (sales.isEmpty) {
        if (delta > 0) _addSale();
        return;
      }
      if (delta > 0 && _selectedSaleIndex >= sales.length - 1) {
        _addSale();
        return;
      }
      setState(() {
        _selectedSaleIndex =
            (_selectedSaleIndex + delta).clamp(0, sales.length - 1);
      });
      _scrollToSelected(_salesScroll, _selectedSaleIndex);
      return;
    }

    setState(() {
      _selectedLotIndex =
          (_selectedLotIndex + delta).clamp(0, _lots.length - 1);
      _selectedSaleIndex = 0;
    });
    _scrollToSelected(_purchaseScroll, _selectedLotIndex);
  }

  void _scrollToSelected(ScrollController controller, int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.hasClients) return;
      final target =
          (index * 42.0).clamp(0.0, controller.position.maxScrollExtent);
      controller.animateTo(
        target,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      );
    });
  }

  void _activateSalesArea() {
    setState(() => _salesAreaActive = true);
    _salesFocus.requestFocus();
  }

  void _activatePurchaseArea() {
    setState(() => _salesAreaActive = false);
    _purchaseFocus.requestFocus();
  }

  Future<void> _addPurchase() async {
    final notifier = ref.read(purcSpatProvider.notifier);
    final lot = await showDialog<PurchaseLot>(
      context: context,
      builder: (context) => _PurchaseDialog(nextSrNo: notifier.nextSrNo),
    );
    if (lot == null) return;

    notifier.addLot(lot);
    setState(() {
      _selectedLotIndex = _lots.length - 1;
      _selectedSaleIndex = 0;
      _salesAreaActive = false;
    });
    _purchaseFocus.requestFocus();
  }

  Future<void> _editSelectedPurchase() async {
    final lot = _selectedLot;
    if (lot == null) return;

    final updated = await showDialog<PurchaseLot>(
      context: context,
      builder: (context) =>
          _PurchaseDialog(nextSrNo: lot.srNo, initialLot: lot),
    );
    if (updated == null) return;

    ref.read(purcSpatProvider.notifier).replaceLot(updated);
    _purchaseFocus.requestFocus();
  }

  Future<void> _addSale() async {
    final lot = _selectedLot;
    if (lot == null) return;

    if (lot.balanceBags <= Money.zero) {
      _showMessage('Truck ${lot.srNo} is fully sold — no bags remaining.');
      return;
    }

    final sale = await showDialog<SaleLine>(
      context: context,
      builder: (context) => _SaleDialog(lot: lot),
    );
    if (sale == null) return;

    final result = ref.read(purcSpatProvider.notifier).addSale(lot.id, sale);
    if (!result.isValid) {
      _showMessage(result.summary);
      return;
    }

    setState(() {
      _selectedSaleIndex = (_selectedLot?.sales.length ?? 1) - 1;
      _salesAreaActive = true;
    });
    _salesFocus.requestFocus();
  }

  Future<void> _editSelectedSale() async {
    final lot = _selectedLot;
    if (lot == null || lot.sales.isEmpty) return;

    final index = _selectedSaleIndex.clamp(0, lot.sales.length - 1);
    final existing = lot.sales[index];
    final sale = await showDialog<SaleLine>(
      context: context,
      builder: (context) => _SaleDialog(lot: lot, initialSale: existing),
    );
    if (sale == null) return;

    final result =
        ref.read(purcSpatProvider.notifier).replaceSale(lot.id, sale);
    if (!result.isValid) _showMessage(result.summary);
  }

  void _onEnter() {
    if (_salesAreaActive) {
      _editSelectedSale();
    } else {
      _editSelectedPurchase();
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final lots = ref.watch(purcSpatProvider);
    final responsive = Responsive(context);
    final isDark = context.isDarkMode;
    final selectedIndex =
        lots.isEmpty ? 0 : _selectedLotIndex.clamp(0, lots.length - 1);
    final selectedLot = lots.isEmpty ? null : lots[selectedIndex];
    final totals = TradingCalculator.totalsFor(lots);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowDown): () => _move(1),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () => _move(-1),
        const SingleActivator(LogicalKeyboardKey.arrowRight):
            _activateSalesArea,
        const SingleActivator(LogicalKeyboardKey.arrowLeft):
            _activatePurchaseArea,
        const SingleActivator(LogicalKeyboardKey.enter): _onEnter,
        const SingleActivator(LogicalKeyboardKey.numpadEnter): _onEnter,
        const SingleActivator(LogicalKeyboardKey.f5): _addSale,
        const SingleActivator(LogicalKeyboardKey.f6): _addPurchase,
      },
      child: Focus(
        autofocus: true,
        child: Container(
          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          child: Padding(
            padding: EdgeInsets.all(responsive.contentPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  title: 'Purchase / Sale Entry Module',
                  subtitle:
                      'Truck-wise vegetable purchase and customer-wise sale details',
                  actions: [
                    OutlinedButton.icon(
                      onPressed: _editSelectedPurchase,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit Truck'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _addSale,
                      icon:
                          const Icon(Icons.person_add_alt_1_outlined, size: 18),
                      label: const Text('Add Customer'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _TotalsStrip(totals: totals),
                const SizedBox(height: 12),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Focus(
                          focusNode: _purchaseFocus,
                          child: _PurchaseTable(
                            lots: lots,
                            selectedIndex: selectedIndex,
                            active: !_salesAreaActive,
                            scrollController: _purchaseScroll,
                            onSelected: (index) => setState(() {
                              _selectedLotIndex = index;
                              _selectedSaleIndex = 0;
                              _salesAreaActive = false;
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        flex: 4,
                        child: Focus(
                          focusNode: _salesFocus,
                          child: _SalesTable(
                            sales: selectedLot?.sales ?? const [],
                            selectedIndex: _selectedSaleIndex,
                            active: _salesAreaActive,
                            scrollController: _salesScroll,
                            onSelected: (index) => setState(() {
                              _selectedSaleIndex = index;
                              _salesAreaActive = true;
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _CaretBalanceSummary(lot: selectedLot),
                const SizedBox(height: 10),
                const _ShortcutBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TotalsStrip extends StatelessWidget {
  const _TotalsStrip({required this.totals});

  final LotTotals totals;

  @override
  Widget build(BuildContext context) {
    final entries = <(String, String)>[
      ('Bags', Money.formatQuantity(totals.bags)),
      ('Sold', Money.formatQuantity(totals.soldBags)),
      ('Balance', Money.formatQuantity(totals.balanceBags)),
      (
        'Caret',
        '${Money.formatQuantity(totals.soldCarets)} / '
            '${Money.formatQuantity(totals.carets)}'
      ),
      ('Sale Amount', Money.formatCurrency(totals.saleAmount)),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        for (final (label, value) in entries)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.emerald600.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$label: $value',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }
}

class _PurchaseTable extends StatelessWidget {
  const _PurchaseTable({
    required this.lots,
    required this.selectedIndex,
    required this.active,
    required this.scrollController,
    required this.onSelected,
  });

  final List<PurchaseLot> lots;
  final int selectedIndex;
  final bool active;
  final ScrollController scrollController;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    if (lots.isEmpty) {
      return const _TableShell(
        active: true,
        child: Center(child: Text('No trucks entered yet. Press F6 to add.')),
      );
    }

    return _TableShell(
      active: active,
      child: _ScrollableTable(
        scrollController: scrollController,
        table: DataTable(
          columnSpacing: 28,
          headingRowColor: WidgetStateProperty.all(AppColors.emerald600),
          headingTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
          dataRowMinHeight: 38,
          dataRowMaxHeight: 42,
          columns: const [
            DataColumn(label: Text('Sr. No.')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Name of the Party')),
            DataColumn(label: Text('Item')),
            DataColumn(label: Text('Bags')),
            DataColumn(label: Text('Sale')),
            DataColumn(label: Text('Balance')),
            DataColumn(label: Text('Caret')),
            DataColumn(label: Text('Sale Amount')),
          ],
          rows: [
            for (var i = 0; i < lots.length; i++)
              DataRow(
                selected: i == selectedIndex,
                color: WidgetStateProperty.resolveWith(
                  (states) => _rowColor(i, selectedIndex, active),
                ),
                cells: [
                  DataCell(Text('${lots[i].srNo}'), onTap: () => onSelected(i)),
                  DataCell(Text(Formatters.numericDate(lots[i].date)),
                      onTap: () => onSelected(i)),
                  DataCell(Text(lots[i].partyName), onTap: () => onSelected(i)),
                  DataCell(Text(lots[i].item), onTap: () => onSelected(i)),
                  DataCell(Text(Formatters.quantity(lots[i].bags.toDouble())),
                      onTap: () => onSelected(i)),
                  DataCell(Text(Formatters.quantity(lots[i].soldBags.toDouble())),
                      onTap: () => onSelected(i)),
                  DataCell(Text(Formatters.quantity(lots[i].balanceBags.toDouble())),
                      onTap: () => onSelected(i)),
                  DataCell(
                    Text(
                        '${Formatters.quantity(lots[i].soldCarets.toDouble())} / ${Formatters.quantity(lots[i].totalCarets.toDouble())}'),
                    onTap: () => onSelected(i),
                  ),
                  DataCell(Text(Formatters.amount(lots[i].saleAmount.toDouble())),
                      onTap: () => onSelected(i)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _SalesTable extends StatelessWidget {
  const _SalesTable({
    required this.sales,
    required this.selectedIndex,
    required this.active,
    required this.scrollController,
    required this.onSelected,
  });

  final List<SaleLine> sales;
  final int selectedIndex;
  final bool active;
  final ScrollController scrollController;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    if (sales.isEmpty) {
      return _TableShell(
        active: active,
        child: const Center(
          child: Text('No customer sales entered for this truck yet.'),
        ),
      );
    }

    final selected = selectedIndex.clamp(0, sales.length - 1);

    return _TableShell(
      active: active,
      child: _ScrollableTable(
        scrollController: scrollController,
        table: DataTable(
          columnSpacing: 28,
          headingRowColor: WidgetStateProperty.all(AppColors.emerald700),
          headingTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
          dataRowMinHeight: 38,
          dataRowMaxHeight: 42,
          columns: const [
            DataColumn(label: Text('Bill No')),
            DataColumn(label: Text('Bill Date')),
            DataColumn(label: Text('Party Name')),
            DataColumn(label: Text('Mark')),
            DataColumn(label: Text('Bags')),
            DataColumn(label: Text('Caret')),
            DataColumn(label: Text('Weight')),
            DataColumn(label: Text('Rate')),
            DataColumn(label: Text('Unit')),
            DataColumn(label: Text('Amount')),
          ],
          rows: [
            for (var i = 0; i < sales.length; i++)
              DataRow(
                selected: i == selected,
                color: WidgetStateProperty.resolveWith(
                  (states) => _rowColor(i, selected, active),
                ),
                cells: [
                  DataCell(Text('${sales[i].billNo}'),
                      onTap: () => onSelected(i)),
                  DataCell(Text(Formatters.numericDate(sales[i].date)),
                      onTap: () => onSelected(i)),
                  DataCell(Text(sales[i].partyName),
                      onTap: () => onSelected(i)),
                  DataCell(Text(sales[i].mark ?? '-'),
                      onTap: () => onSelected(i)),
                  DataCell(Text(Formatters.quantity(sales[i].bags.toDouble())),
                      onTap: () => onSelected(i)),
                  DataCell(Text(Formatters.quantity(sales[i].carets.toDouble())),
                      onTap: () => onSelected(i)),
                  DataCell(Text(Formatters.quantity(sales[i].weight.toDouble())),
                      onTap: () => onSelected(i)),
                  DataCell(Text(Formatters.quantity(sales[i].rate.toDouble())),
                      onTap: () => onSelected(i)),
                  DataCell(Text(sales[i].unit.label),
                      onTap: () => onSelected(i)),
                  DataCell(Text(Formatters.amount(sales[i].amount.toDouble())),
                      onTap: () => onSelected(i)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

Color _rowColor(int index, int selectedIndex, bool active) {
  if (index == selectedIndex) {
    return active
        ? AppColors.emerald600.withValues(alpha: 0.18)
        : AppColors.blue500.withValues(alpha: 0.10);
  }
  return index.isEven
      ? Colors.transparent
      : Colors.black.withValues(alpha: 0.03);
}

class _ScrollableTable extends StatelessWidget {
  const _ScrollableTable({required this.scrollController, required this.table});

  final ScrollController scrollController;
  final DataTable table;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scrollbar(
          controller: scrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: scrollController,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: table,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TableShell extends StatelessWidget {
  const _TableShell({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active
              ? AppColors.emerald500
              : isDark
                  ? AppColors.darkBorder
                  : AppColors.lightBorder,
          width: active ? 1.6 : 1,
        ),
      ),
      child: child,
    );
  }
}

class _ShortcutBar extends StatelessWidget {
  const _ShortcutBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.emerald800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Enter Edit    F5 Add Customer    F6 Add Truck    Down in Sales Adds Next Customer    Esc Back',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _PurchaseDialog extends StatefulWidget {
  const _PurchaseDialog({required this.nextSrNo, this.initialLot});

  final int nextSrNo;
  final PurchaseLot? initialLot;

  @override
  State<_PurchaseDialog> createState() => _PurchaseDialogState();
}

class _PurchaseDialogState extends State<_PurchaseDialog> {
  late final TextEditingController _party;
  late final TextEditingController _item;
  late final TextEditingController _bags;
  late final TextEditingController _carets;

  ValidationResult _validation = const ValidationResult.valid();

  bool get _isEditing => widget.initialLot != null;

  @override
  void initState() {
    super.initState();
    final lot = widget.initialLot;
    _party = TextEditingController(text: lot?.partyName ?? '');
    _item = TextEditingController(text: lot?.item ?? '');
    _bags = TextEditingController(
        text: lot == null ? '' : Formatters.quantity(lot.bags.toDouble()),
    );
    _carets = TextEditingController(
      text: lot == null ? '0' : Formatters.quantity(lot.totalCarets.toDouble()),
    );
  }

  @override
  void dispose() {
    _party.dispose();
    _item.dispose();
    _bags.dispose();
    _carets.dispose();
    super.dispose();
  }

  void _save() {
    final bags = Money.parseOrZero(_bags.text);
    final carets = Money.parseOrZero(_carets.text);
    final result = TradingCalculator.validatePurchase(
      partyName: _party.text,
      item: _item.text,
      bags: bags,
      carets: carets,
      existing: widget.initialLot,
    );

    if (!result.isValid) {
      setState(() => _validation = result);
      return;
    }

    final existing = widget.initialLot;
    Navigator.pop(
      context,
      PurchaseLot(
        id: existing?.id ?? 'lot-${DateTime.now().microsecondsSinceEpoch}',
        srNo: widget.nextSrNo,
        date: existing?.date ?? DateTime.now(),
        partyName: _party.text.trim().toUpperCase(),
        item: _item.text.trim().toUpperCase(),
        bags: bags,
        totalCarets: carets,
        sales: existing?.sales ?? const [],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Purchase Truck' : 'Add Purchase Truck'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _party,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Name of the Party',
                  errorText: _validation.messageFor('partyName'),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _item,
                decoration: InputDecoration(
                  labelText: 'Item',
                  errorText: _validation.messageFor('item'),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _bags,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Bags',
                        errorText: _validation.messageFor('bags'),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _carets,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Caret',
                        errorText: _validation.messageFor('carets'),
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _save(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

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

  static const List<String> _markOptions = ['SVC', 'ARC', 'OTHER'];

  ValidationResult _validation = const ValidationResult.valid();

  @override
  void initState() {
    super.initState();
    final sale = widget.initialSale;
    _party = TextEditingController(text: sale?.partyName ?? '');
    _bags = TextEditingController(
      text: sale == null ? '' : Money.formatQuantity(sale.bags),
    );
    _carets = TextEditingController(
      text: sale == null ? '0' : Money.formatQuantity(sale.carets),
    );
    _weight = TextEditingController(
      text: sale == null ? '' : Money.formatQuantity(sale.weight),
    );
    _rate = TextEditingController(
      text: sale == null ? '' : Money.formatQuantity(sale.rate),
    );
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
    super.dispose();
  }

  Decimal get _liveAmount => _unit.amount(
        weight: Money.parseOrZero(_weight.text),
        bags: Money.parseOrZero(_bags.text),
        carets: Money.parseOrZero(_carets.text),
        rate: Money.parseOrZero(_rate.text),
      );

  void _save() {
    final bags = Money.parseOrZero(_bags.text);
    final carets = Money.parseOrZero(_carets.text);
    final weight = Money.parseOrZero(_weight.text);
    final rate = Money.parseOrZero(_rate.text);

    final result = TradingCalculator.validateSale(
      lot: widget.lot,
      partyName: _party.text,
      bags: bags,
      carets: carets,
      weight: weight,
      rate: rate,
      replacing: widget.initialSale,
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
        bags: bags,
        carets: carets,
        weight: weight,
        rate: rate,
        unit: _unit,
        mark: _selectedMark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lot = widget.lot;
    final availableBags =
        lot.balanceBags + (widget.initialSale?.bags ?? Money.zero);

    return AlertDialog(
      title: Text(
        widget.initialSale == null ? 'Add Customer Sale' : 'Edit Customer Sale',
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Truck ${lot.srNo} — ${lot.item} — '
                '${Money.formatQuantity(availableBags)} bags available',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _party,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Party Name',
                  errorText: _validation.messageFor('partyName'),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedMark,
                decoration: const InputDecoration(labelText: 'Mark'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('-'),
                  ),
                  for (final mark in _markOptions)
                    DropdownMenuItem(
                      value: mark,
                      child: Text(mark),
                    ),
                ],
                onChanged: (value) =>
                    setState(() => _selectedMark = value),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _bags,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Bags',
                        errorText: _validation.messageFor('bags'),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _carets,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Caret',
                        errorText: _validation.messageFor('carets'),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _weight,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Weight',
                        errorText: _validation.messageFor('weight'),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _rate,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Rate',
                        errorText: _validation.messageFor('rate'),
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _save(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue:
                          RateUnit.presets.any((u) => u.label == _unit.label)
                              ? _unit.label
                              : RateUnit.perKg.label,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      items: [
                        for (final unit in RateUnit.presets)
                          DropdownMenuItem(
                            value: unit.label,
                            child: Text(unit.label),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => _unit = RateUnit.parse(value)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Amount: ${Money.formatCurrency(_liveAmount)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

/// Shows caret balance per customer for the selected lot.
class _CaretBalanceSummary extends StatelessWidget {
  const _CaretBalanceSummary({this.lot});

  final PurchaseLot? lot;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lot = this.lot;

    if (lot == null || lot.sales.isEmpty) {
      return const SizedBox.shrink();
    }

    final caretBalances = lot.caretBalanceByCustomer;
    if (caretBalances.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Caret Balance — Who owes carets back',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              for (final entry in caretBalances.entries)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: entry.value > Money.zero
                        ? AppColors.orange500.withValues(alpha: 0.15)
                        : AppColors.emerald600.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${entry.key}: ${Money.formatQuantity(entry.value)} carets',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: entry.value > Money.zero
                              ? AppColors.orange500
                              : AppColors.emerald600,
                        ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
