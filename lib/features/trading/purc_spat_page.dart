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
  final _truckScroll = ScrollController();
  final _saleScroll = ScrollController();
  final _pageFocus = FocusNode(debugLabel: 'Purc/SPAT module');

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
  bool _showingTruckDetail = false;

  _PurchaseLot get _selectedLot => _lots[_selectedLotIndex];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _pageFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _truckScroll.dispose();
    _saleScroll.dispose();
    _pageFocus.dispose();
    super.dispose();
  }

  void _move(int delta) {
    if (_showingTruckDetail) {
      final sales = _selectedLot.sales;
      if (sales.isEmpty) return;
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
      _scrollToSelected(_saleScroll, _selectedSaleIndex);
      return;
    }

    setState(() {
      _selectedLotIndex =
          (_selectedLotIndex + delta).clamp(0, _lots.length - 1);
      _selectedSaleIndex = 0;
    });
    _scrollToSelected(_truckScroll, _selectedLotIndex);
  }

  void _scrollToSelected(ScrollController controller, int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.hasClients) return;
      final target = (index * 58.0).clamp(
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

  void _openTruckDetail() {
    setState(() {
      _showingTruckDetail = true;
      _selectedSaleIndex = 0;
    });
    _pageFocus.requestFocus();
  }

  void _backToTruckList() {
    setState(() => _showingTruckDetail = false);
    _pageFocus.requestFocus();
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
      _showingTruckDetail = false;
    });
    _scrollToSelected(_truckScroll, _selectedLotIndex);
    _pageFocus.requestFocus();
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
    _pageFocus.requestFocus();
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
      _showingTruckDetail = true;
    });
    _scrollToSelected(_saleScroll, _selectedSaleIndex);
    _pageFocus.requestFocus();
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
        const SingleActivator(LogicalKeyboardKey.enter): _openTruckDetail,
        const SingleActivator(LogicalKeyboardKey.numpadEnter): _openTruckDetail,
        const SingleActivator(LogicalKeyboardKey.arrowRight): _openTruckDetail,
        const SingleActivator(LogicalKeyboardKey.f2): _editSelectedPurchase,
        const SingleActivator(LogicalKeyboardKey.f5): _addSale,
        const SingleActivator(LogicalKeyboardKey.f6): _addPurchase,
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (_showingTruckDetail) _backToTruckList();
        },
      },
      child: Focus(
        focusNode: _pageFocus,
        autofocus: true,
        child: Container(
          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          child: Padding(
            padding: EdgeInsets.all(responsive.contentPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  title: _showingTruckDetail
                      ? 'Customer Sales From Truck ${_selectedLot.srNo}'
                      : 'Purchase / Sale Entry Module',
                  subtitle: _showingTruckDetail
                      ? '${_selectedLot.partyName} - ${_selectedLot.item}'
                      : 'Select a truck, then press Enter or click to enter customer sales',
                  actions: _showingTruckDetail
                      ? [
                          OutlinedButton.icon(
                            onPressed: _backToTruckList,
                            icon:
                                const Icon(Icons.arrow_back_rounded, size: 18),
                            label: const Text('Truck List'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _editSelectedPurchase,
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('F2 Edit Truck'),
                          ),
                          ElevatedButton.icon(
                            onPressed: _addSale,
                            icon: const Icon(
                              Icons.person_add_alt_1_outlined,
                              size: 18,
                            ),
                            label: const Text('Add Customer'),
                          ),
                        ]
                      : [
                          OutlinedButton.icon(
                            onPressed: _addPurchase,
                            icon: const Icon(
                              Icons.local_shipping_outlined,
                              size: 18,
                            ),
                            label: const Text('Add Truck'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _editSelectedPurchase,
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('F2 Edit'),
                          ),
                        ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: _showingTruckDetail
                        ? _TruckDetailView(
                            key: ValueKey(_selectedLot.srNo),
                            lot: _selectedLot,
                            selectedSaleIndex: _selectedSaleIndex,
                            scrollController: _saleScroll,
                            onSelectedSale: (index) {
                              setState(() => _selectedSaleIndex = index);
                            },
                          )
                        : _TruckListView(
                            key: const ValueKey('truck-list'),
                            lots: _lots,
                            selectedIndex: _selectedLotIndex,
                            scrollController: _truckScroll,
                            onSelected: (index) {
                              setState(() {
                                _selectedLotIndex = index;
                                _selectedSaleIndex = 0;
                              });
                            },
                            onOpen: _openTruckDetail,
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                _ShortcutBar(showingTruckDetail: _showingTruckDetail),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TruckListView extends StatelessWidget {
  const _TruckListView({
    super.key,
    required this.lots,
    required this.selectedIndex,
    required this.scrollController,
    required this.onSelected,
    required this.onOpen,
  });

  final List<_PurchaseLot> lots;
  final int selectedIndex;
  final ScrollController scrollController;
  final ValueChanged<int> onSelected;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return _TableShell(
      active: true,
      child: _RecordTable(
        scrollController: scrollController,
        minWidth: 980,
        header: const [
          _CellSpec('Sr. No.', 86),
          _CellSpec('Date', 126),
          _CellSpec('Name of the Party', 280),
          _CellSpec('Item', 180),
          _CellSpec('Bags', 82),
          _CellSpec('Sale', 82),
          _CellSpec('Balance', 96),
          _CellSpec('Caret', 96),
        ],
        rows: [
          for (var i = 0; i < lots.length; i++)
            _RecordRow(
              selected: i == selectedIndex,
              values: [
                '${lots[i].srNo}',
                _formatDate(lots[i].date),
                lots[i].partyName,
                lots[i].item,
                _number(lots[i].bags),
                _number(lots[i].soldBags),
                _number(lots[i].balanceBags),
                '${_number(lots[i].soldCarets)} / ${_number(lots[i].totalCarets)}',
              ],
              onTap: () => onSelected(i),
              onDoubleTap: () {
                onSelected(i);
                onOpen();
              },
            ),
        ],
      ),
    );
  }
}

class _TruckDetailView extends StatelessWidget {
  const _TruckDetailView({
    super.key,
    required this.lot,
    required this.selectedSaleIndex,
    required this.scrollController,
    required this.onSelectedSale,
  });

  final _PurchaseLot lot;
  final int selectedSaleIndex;
  final ScrollController scrollController;
  final ValueChanged<int> onSelectedSale;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TruckSummary(lot: lot),
        const SizedBox(height: 12),
        Expanded(
          child: lot.sales.isEmpty
              ? const _TableShell(
                  active: true,
                  child: Center(
                    child:
                        Text('No customer sales entered for this truck yet.'),
                  ),
                )
              : _TableShell(
                  active: true,
                  child: _RecordTable(
                    scrollController: scrollController,
                    minWidth: 940,
                    header: const [
                      _CellSpec('Bill No', 86),
                      _CellSpec('Bill Date', 126),
                      _CellSpec('Party Name', 300),
                      _CellSpec('Bags', 82),
                      _CellSpec('Weight', 96),
                      _CellSpec('Rate', 82),
                      _CellSpec('Unit', 76),
                      _CellSpec('Amount', 116),
                    ],
                    rows: [
                      for (var i = 0; i < lot.sales.length; i++)
                        _RecordRow(
                          selected: i == selectedSaleIndex,
                          values: [
                            '${lot.sales[i].billNo}',
                            _formatDate(lot.sales[i].date),
                            lot.sales[i].partyName,
                            _number(lot.sales[i].bags),
                            _number(lot.sales[i].weight),
                            _number(lot.sales[i].rate),
                            lot.sales[i].unit,
                            _money(lot.sales[i].amount),
                          ],
                          onTap: () => onSelectedSale(i),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _TruckSummary extends StatelessWidget {
  const _TruckSummary({required this.lot});

  final _PurchaseLot lot;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 8,
        children: [
          _SummaryText(label: 'Truck', value: '${lot.srNo}'),
          _SummaryText(label: 'Party', value: lot.partyName),
          _SummaryText(label: 'Item', value: lot.item),
          _SummaryText(label: 'Bags', value: _number(lot.bags)),
          _SummaryText(label: 'Sold', value: _number(lot.soldBags)),
          _SummaryText(label: 'Balance', value: _number(lot.balanceBags)),
          _SummaryText(
            label: 'Caret',
            value: '${_number(lot.soldCarets)} / ${_number(lot.totalCarets)}',
          ),
        ],
      ),
    );
  }
}

class _SummaryText extends StatelessWidget {
  const _SummaryText({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _RecordTable extends StatelessWidget {
  const _RecordTable({
    required this.scrollController,
    required this.minWidth,
    required this.header,
    required this.rows,
  });

  final ScrollController scrollController;
  final double minWidth;
  final List<_CellSpec> header;
  final List<_RecordRow> rows;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth =
            constraints.maxWidth > minWidth ? constraints.maxWidth : minWidth;
        return Scrollbar(
          controller: scrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: scrollController,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeaderRow(cells: header),
                    ...rows,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.cells});

  final List<_CellSpec> cells;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      color: AppColors.emerald700,
      child: Row(
        children: [
          for (final cell in cells)
            Expanded(
              flex: cell.flex,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    cell.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({
    required this.selected,
    required this.values,
    required this.onTap,
    this.onDoubleTap,
  });

  final bool selected;
  final List<String> values;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final specs = values.length == 8
        ? const [86, 126, 280, 180, 82, 82, 96, 96]
        : const [86, 126, 300, 82, 96, 82, 76, 116];

    return InkWell(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.emerald600.withValues(alpha: 0.18)
              : isDark
                  ? AppColors.darkSurface
                  : AppColors.lightSurface,
          border: Border(
            bottom: BorderSide(
              color:
                  isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder,
            ),
          ),
        ),
        child: Row(
          children: [
            for (var i = 0; i < values.length; i++)
              Expanded(
                flex: specs[i],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Align(
                    alignment:
                        i >= 4 ? Alignment.centerRight : Alignment.centerLeft,
                    child: Text(
                      values[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w600,
                          ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CellSpec {
  const _CellSpec(this.label, this.flex);

  final String label;
  final int flex;
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
  const _ShortcutBar({required this.showingTruckDetail});

  final bool showingTruckDetail;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.emerald800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        showingTruckDetail
            ? 'Esc Truck List    F2 Edit Truck    F5 Add Customer    Down on Last Customer Adds Next'
            : 'Arrow Keys Select Truck    Enter Open Truck    F2 Edit Truck    F6 Add Truck    Esc Back',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
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
