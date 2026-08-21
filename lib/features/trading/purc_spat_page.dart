import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/page_header.dart';

class PurcSpatPage extends StatefulWidget {
  const PurcSpatPage({super.key});

  @override
  State<PurcSpatPage> createState() => _PurcSpatPageState();
}

class _PurcSpatPageState extends State<PurcSpatPage> {
  final _purchaseScroll = ScrollController();
  final _salesScroll = ScrollController();
  final _purchaseFocus = FocusNode(debugLabel: 'Purchase truck list');
  final _salesFocus = FocusNode(debugLabel: 'Customer sale list');

  final List<_PurchaseLot> _lots = [
    _PurchaseLot(
      srNo: 1075,
      date: DateTime(2026, 8, 6),
      partyName: 'ABDULLA SETH RAIPUR',
      item: 'MUNGNA FALLI',
      bags: 10,
      totalCarets: 10,
      sales: [
        _SaleLine(
          billNo: 1,
          date: DateTime(2026, 8, 6),
          partyName: 'KOMAL BALLU GANJ GONDIA',
          bags: 1,
          weight: 46,
          rate: 50,
          unit: '1KG',
        ),
        _SaleLine(
          billNo: 2,
          date: DateTime(2026, 8, 6),
          partyName: 'BABA SOHAN GONDIA',
          bags: 3,
          weight: 142,
          rate: 50,
          unit: '1KG',
        ),
        _SaleLine(
          billNo: 3,
          date: DateTime(2026, 8, 6),
          partyName: 'SOHAN BAHE KATI 9421247',
          bags: 5,
          weight: 238,
          rate: 45,
          unit: '1KG',
        ),
        _SaleLine(
          billNo: 4,
          date: DateTime(2026, 8, 6),
          partyName: 'LAKHAN RKS GANJ 8888450',
          bags: 1,
          weight: 48,
          rate: 47,
          unit: '1KG',
        ),
      ],
    ),
    _PurchaseLot(
      srNo: 1076,
      date: DateTime(2026, 8, 6),
      partyName: 'ABDULLA SETH RAIPUR',
      item: 'PATTAGOBHI',
      bags: 25,
      totalCarets: 0,
      sales: const [],
    ),
    _PurchaseLot(
      srNo: 1077,
      date: DateTime(2026, 8, 6),
      partyName: 'ABDULLA SETH RAIPUR',
      item: 'KATWAL',
      bags: 40,
      totalCarets: 0,
      sales: const [],
    ),
    _PurchaseLot(
      srNo: 1078,
      date: DateTime(2026, 8, 6),
      partyName: 'ABDULLA SETH RAIPUR',
      item: 'SHIMLA MIRCHI',
      bags: 10,
      totalCarets: 0,
      sales: const [],
    ),
    _PurchaseLot(
      srNo: 1079,
      date: DateTime(2026, 8, 6),
      partyName: 'VICKY NANDU ND',
      item: 'FOOL GOBHI',
      bags: 20,
      totalCarets: 10,
      sales: const [],
    ),
  ];

  int _selectedLotIndex = 0;
  int _selectedSaleIndex = 0;
  bool _salesAreaActive = false;

  _PurchaseLot get _selectedLot => _lots[_selectedLotIndex];

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

  void _move(int delta) {
    if (_salesAreaActive) {
      final sales = _selectedLot.sales;
      if (sales.isEmpty) {
        if (delta > 0) _addSale();
        return;
      }
      if (delta > 0 && _selectedSaleIndex == sales.length - 1) {
        _addSale();
        return;
      }
      setState(() {
        _selectedSaleIndex = (_selectedSaleIndex + delta).clamp(
          0,
          sales.length - 1,
        );
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
      final target = (index * 42.0).clamp(
        0.0,
        controller.position.maxScrollExtent,
      );
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
    final lot = await showDialog<_PurchaseLot>(
      context: context,
      builder: (context) => _PurchaseDialog(nextSrNo: _nextSrNo),
    );
    if (lot == null) return;
    setState(() {
      _lots.add(lot);
      _selectedLotIndex = _lots.length - 1;
      _selectedSaleIndex = 0;
      _salesAreaActive = false;
    });
    _purchaseFocus.requestFocus();
  }

  Future<void> _editSelectedPurchase() async {
    final updatedLot = await showDialog<_PurchaseLot>(
      context: context,
      builder: (context) => _PurchaseDialog(
        nextSrNo: _selectedLot.srNo,
        initialLot: _selectedLot,
      ),
    );
    if (updatedLot == null) return;
    setState(() => _lots[_selectedLotIndex] = updatedLot);
    _purchaseFocus.requestFocus();
  }

  Future<void> _addSale() async {
    final sale = await showDialog<_SaleLine>(
      context: context,
      builder: (context) =>
          _SaleDialog(nextBillNo: _selectedLot.sales.length + 1),
    );
    if (sale == null) return;
    setState(() {
      final lot = _selectedLot;
      final updatedSales = [...lot.sales, sale];
      _lots[_selectedLotIndex] = lot.copyWith(sales: updatedSales);
      _selectedSaleIndex = updatedSales.length - 1;
      _salesAreaActive = true;
    });
    _salesFocus.requestFocus();
  }

  int get _nextSrNo {
    if (_lots.isEmpty) return 1;
    return _lots.map((lot) => lot.srNo).reduce((a, b) => a > b ? a : b) + 1;
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowDown): () => _move(1),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () => _move(-1),
        const SingleActivator(LogicalKeyboardKey.arrowRight):
            _activateSalesArea,
        const SingleActivator(LogicalKeyboardKey.arrowLeft):
            _activatePurchaseArea,
        const SingleActivator(LogicalKeyboardKey.enter): _editSelectedPurchase,
        const SingleActivator(LogicalKeyboardKey.numpadEnter):
            _editSelectedPurchase,
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
                const SizedBox(height: 14),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Focus(
                          focusNode: _purchaseFocus,
                          child: _PurchaseTable(
                            lots: _lots,
                            selectedIndex: _selectedLotIndex,
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
                            sales: _selectedLot.sales,
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
                const _ShortcutBar(),
              ],
            ),
          ),
        ),
      ),
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

  final List<_PurchaseLot> lots;
  final int selectedIndex;
  final bool active;
  final ScrollController scrollController;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
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
          ],
          rows: [
            for (var i = 0; i < lots.length; i++)
              DataRow(
                selected: i == selectedIndex,
                color: WidgetStateProperty.resolveWith((states) {
                  if (i == selectedIndex) {
                    return active
                        ? AppColors.emerald600.withValues(alpha: 0.18)
                        : AppColors.blue500.withValues(alpha: 0.10);
                  }
                  return i.isEven
                      ? Colors.transparent
                      : Colors.black.withValues(alpha: 0.03);
                }),
                cells: [
                  DataCell(Text('${lots[i].srNo}'), onTap: () => onSelected(i)),
                  DataCell(Text(_formatDate(lots[i].date)),
                      onTap: () => onSelected(i)),
                  DataCell(Text(lots[i].partyName), onTap: () => onSelected(i)),
                  DataCell(Text(lots[i].item), onTap: () => onSelected(i)),
                  DataCell(Text(_number(lots[i].bags)),
                      onTap: () => onSelected(i)),
                  DataCell(Text(_number(lots[i].soldBags)),
                      onTap: () => onSelected(i)),
                  DataCell(Text(_number(lots[i].balanceBags)),
                      onTap: () => onSelected(i)),
                  DataCell(
                    Text(
                        '${_number(lots[i].soldCarets)} / ${_number(lots[i].totalCarets)}'),
                    onTap: () => onSelected(i),
                  ),
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

  final List<_SaleLine> sales;
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
            DataColumn(label: Text('Bags')),
            DataColumn(label: Text('Weight')),
            DataColumn(label: Text('Rate')),
            DataColumn(label: Text('Unit')),
            DataColumn(label: Text('Amount')),
          ],
          rows: [
            for (var i = 0; i < sales.length; i++)
              DataRow(
                selected: i == selectedIndex,
                color: WidgetStateProperty.resolveWith((states) {
                  if (i == selectedIndex) {
                    return active
                        ? AppColors.emerald600.withValues(alpha: 0.18)
                        : AppColors.blue500.withValues(alpha: 0.10);
                  }
                  return i.isEven
                      ? Colors.transparent
                      : Colors.black.withValues(alpha: 0.03);
                }),
                cells: [
                  DataCell(Text('${sales[i].billNo}'),
                      onTap: () => onSelected(i)),
                  DataCell(Text(_formatDate(sales[i].date)),
                      onTap: () => onSelected(i)),
                  DataCell(Text(sales[i].partyName),
                      onTap: () => onSelected(i)),
                  DataCell(Text(_number(sales[i].bags)),
                      onTap: () => onSelected(i)),
                  DataCell(Text(_number(sales[i].weight)),
                      onTap: () => onSelected(i)),
                  DataCell(Text(_number(sales[i].rate)),
                      onTap: () => onSelected(i)),
                  DataCell(Text(sales[i].unit), onTap: () => onSelected(i)),
                  DataCell(Text(_money(sales[i].amount)),
                      onTap: () => onSelected(i)),
                ],
              ),
          ],
        ),
      ),
    );
  }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
      decoration: BoxDecoration(
        color: AppColors.emerald800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Enter Edit Truck    F5 Add Customer    F6 Add Truck    Down in Sales Adds Next Customer    Esc Back',
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
  final _PurchaseLot? initialLot;

  @override
  State<_PurchaseDialog> createState() => _PurchaseDialogState();
}

class _PurchaseDialogState extends State<_PurchaseDialog> {
  late final TextEditingController _party;
  late final TextEditingController _item;
  late final TextEditingController _bags;
  late final TextEditingController _carets;

  bool get _isEditing => widget.initialLot != null;

  @override
  void initState() {
    super.initState();
    final lot = widget.initialLot;
    _party = TextEditingController(text: lot?.partyName ?? '');
    _item = TextEditingController(text: lot?.item ?? '');
    _bags = TextEditingController(text: lot == null ? '' : _number(lot.bags));
    _carets = TextEditingController(
      text: lot == null ? '0' : _number(lot.totalCarets),
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Purchase Truck' : 'Add Purchase Truck'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _party,
              decoration: const InputDecoration(labelText: 'Name of the Party'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _item,
              decoration: const InputDecoration(labelText: 'Item'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _bags,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Bags'),
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _carets,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Caret'),
                    textInputAction: TextInputAction.done,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final bags = double.tryParse(_bags.text.trim()) ?? 0;
            if (_party.text.trim().isEmpty ||
                _item.text.trim().isEmpty ||
                bags <= 0) {
              return;
            }
            Navigator.pop(
              context,
              _PurchaseLot(
                srNo: widget.nextSrNo,
                date: widget.initialLot?.date ?? DateTime.now(),
                partyName: _party.text.trim().toUpperCase(),
                item: _item.text.trim().toUpperCase(),
                bags: bags,
                totalCarets: double.tryParse(_carets.text.trim()) ?? 0,
                sales: widget.initialLot?.sales ?? const [],
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _SaleDialog extends StatefulWidget {
  const _SaleDialog({required this.nextBillNo});

  final int nextBillNo;

  @override
  State<_SaleDialog> createState() => _SaleDialogState();
}

class _SaleDialogState extends State<_SaleDialog> {
  final _party = TextEditingController();
  final _bags = TextEditingController();
  final _weight = TextEditingController();
  final _rate = TextEditingController();
  final _unit = TextEditingController(text: '1KG');

  @override
  void dispose() {
    _party.dispose();
    _bags.dispose();
    _weight.dispose();
    _rate.dispose();
    _unit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Customer Sale'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _party,
              decoration: const InputDecoration(labelText: 'Party Name'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _bags,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Bags'),
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _weight,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Weight'),
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _rate,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Rate'),
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _unit,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    textInputAction: TextInputAction.done,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final bags = double.tryParse(_bags.text.trim()) ?? 0;
            final weight = double.tryParse(_weight.text.trim()) ?? 0;
            final rate = double.tryParse(_rate.text.trim()) ?? 0;
            if (_party.text.trim().isEmpty ||
                bags <= 0 ||
                weight <= 0 ||
                rate <= 0) {
              return;
            }
            Navigator.pop(
              context,
              _SaleLine(
                billNo: widget.nextBillNo,
                date: DateTime.now(),
                partyName: _party.text.trim().toUpperCase(),
                bags: bags,
                weight: weight,
                rate: rate,
                unit: _unit.text.trim().isEmpty
                    ? '1KG'
                    : _unit.text.trim().toUpperCase(),
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _PurchaseLot {
  const _PurchaseLot({
    required this.srNo,
    required this.date,
    required this.partyName,
    required this.item,
    required this.bags,
    required this.totalCarets,
    required this.sales,
  });

  final int srNo;
  final DateTime date;
  final String partyName;
  final String item;
  final double bags;
  final double totalCarets;
  final List<_SaleLine> sales;

  double get soldBags => sales.fold(0, (sum, sale) => sum + sale.bags);
  double get balanceBags => bags - soldBags;
  double get soldCarets => sales.fold(0, (sum, sale) => sum + sale.bags);

  _PurchaseLot copyWith({List<_SaleLine>? sales}) {
    return _PurchaseLot(
      srNo: srNo,
      date: date,
      partyName: partyName,
      item: item,
      bags: bags,
      totalCarets: totalCarets,
      sales: sales ?? this.sales,
    );
  }
}

class _SaleLine {
  const _SaleLine({
    required this.billNo,
    required this.date,
    required this.partyName,
    required this.bags,
    required this.weight,
    required this.rate,
    required this.unit,
  });

  final int billNo;
  final DateTime date;
  final String partyName;
  final double bags;
  final double weight;
  final double rate;
  final String unit;

  double get amount => weight * rate;
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String _number(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(2);
}

String _money(double value) => value.toStringAsFixed(2);
