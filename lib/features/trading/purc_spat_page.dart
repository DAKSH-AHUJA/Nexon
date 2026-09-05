import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme_context.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/keyboard_nav.dart';
import '../../core/widgets/page_header.dart';
import '../../domain/calculators/trading_calculator.dart';
import '../../domain/models/purchase_lot.dart';
import '../../domain/money.dart';
import '../../services/purc_spat_provider.dart';

/// Page 1 of Purc/SPAT: the truck list.
///
/// Every purchased truck is a full-width card; tapping one opens the truck's
/// customer-wise sale page. This screen intentionally shows only trucks —
/// customer accounting lives on the detail page and in reports.
class PurcSpatPage extends ConsumerStatefulWidget {
  const PurcSpatPage({super.key});

  @override
  ConsumerState<PurcSpatPage> createState() => _PurcSpatPageState();
}

class _PurcSpatPageState extends ConsumerState<PurcSpatPage> {
  void _openTruck(PurchaseLot lot) {
    context.go('/data-entry/purc-spat/${lot.id}');
  }

  Future<void> _addTruck() async {
    final notifier = ref.read(purcSpatProvider.notifier);
    final lot = await showDialog<PurchaseLot>(
      context: context,
      builder: (context) => const _TruckDialog(),
    );
    if (lot != null) {
      notifier.addLot(lot);
      _openTruck(lot);
    }
  }

  Future<void> _editTruck(PurchaseLot lot) async {
    final notifier = ref.read(purcSpatProvider.notifier);
    final updated = await showDialog<PurchaseLot>(
      context: context,
      builder: (context) => _TruckDialog(existing: lot),
    );
    if (updated != null) {
      notifier.replaceLot(updated);
    }
  }

  void _deleteTruck(PurchaseLot lot) {
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete truck?'),
        content: Text(
          'Truck ${lot.srNo} (${lot.item}) and all its customer sales will be '
          'removed. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((ok) {
      if (ok != true) return;
      final notifier = ref.read(purcSpatProvider.notifier);
      notifier.removeLot(lot.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lots = ref.watch(purcSpatProvider);
    final responsive = Responsive(context);
    final totals = TradingCalculator.totalsFor(lots);

    return Padding(
      padding: EdgeInsets.all(responsive.contentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Purc / SPAT',
            subtitle: 'Purchased trucks — tap a truck to record customer sales',
            actions: [
              FilledButton.icon(
                onPressed: _addTruck,
                icon: const Icon(Icons.local_shipping_outlined),
                label: const Text('Add Truck'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _TotalChip(
                  label: 'Bags', value: Money.formatQuantity(totals.bags)),
              _TotalChip(
                label: 'Balance',
                value: Money.formatQuantity(totals.balanceBags),
              ),
              _TotalChip(
                label: 'Carets',
                value: Money.formatQuantity(totals.carets),
              ),
              _TotalChip(
                label: 'Carets Out',
                value: Money.formatQuantity(totals.soldCarets),
              ),
              _TotalChip(
                label: 'Sale Amount',
                value: Money.formatCurrency(totals.saleAmount),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: lots.isEmpty
                ? _EmptyState(onAdd: _addTruck)
                : ListView.separated(
                    itemCount: lots.length,
                    separatorBuilder: (context, _) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final lot = lots[index];
                      return _TruckCard(
                        lot: lot,
                        onTap: () => _openTruck(lot),
                        onEdit: () => _editTruck(lot),
                        onDelete: () => _deleteTruck(lot),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TotalChip extends StatelessWidget {
  const _TotalChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: context.mutedText),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping_outlined,
              size: 56, color: context.subtleText),
          const SizedBox(height: 12),
          Text('No trucks yet', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Record the first purchase lot to start selling.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: context.mutedText),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Truck'),
          ),
        ],
      ),
    );
  }
}

class _TruckCard extends StatelessWidget {
  const _TruckCard({
    required this.lot,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final PurchaseLot lot;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final soldOut = lot.isFullySold;

    return Container(
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _SrNoBadge(srNo: lot.srNo),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              lot.item,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (soldOut)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .error
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'SOLD',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.error,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lot.partyName,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: context.mutedText),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 20,
                        runSpacing: 8,
                        children: [
                          _Stat(
                              label: 'Bags',
                              value: Money.formatQuantity(lot.bags)),
                          _Stat(
                            label: 'Sold',
                            value: Money.formatQuantity(lot.soldBags),
                          ),
                          _Stat(
                            label: 'Balance',
                            value: Money.formatQuantity(lot.balanceBags),
                          ),
                          _Stat(
                            label: 'Carets In',
                            value: Money.formatQuantity(lot.totalCarets),
                          ),
                          _Stat(
                            label: 'Carets Out',
                            value: Money.formatQuantity(lot.soldCarets),
                          ),
                          _Stat(
                            label: 'Customers',
                            value: '${lot.sales.length}',
                          ),
                          _Stat(
                            label: 'Sale',
                            value: Money.formatCurrency(lot.saleAmount),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Edit truck',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                ),
                IconButton(
                  tooltip: 'Delete truck',
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                Icon(Icons.chevron_right, color: context.subtleText),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SrNoBadge extends StatelessWidget {
  const _SrNoBadge({required this.srNo});

  final int srNo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$srNo',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: context.subtleText,
                letterSpacing: 0.4,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _TruckDialog extends ConsumerStatefulWidget {
  const _TruckDialog({this.existing});

  final PurchaseLot? existing;

  @override
  ConsumerState<_TruckDialog> createState() => _TruckDialogState();
}

class _TruckDialogState extends ConsumerState<_TruckDialog> {
  late final TextEditingController _party =
      TextEditingController(text: widget.existing?.partyName ?? '');
  late final TextEditingController _item =
      TextEditingController(text: widget.existing?.item ?? '');
  late final TextEditingController _bags = TextEditingController(
    text: widget.existing == null
        ? ''
        : Money.formatQuantity(widget.existing!.bags),
  );
  late final TextEditingController _carets = TextEditingController(
    text: widget.existing == null
        ? ''
        : Money.formatQuantity(widget.existing!.totalCarets),
  );

  final _partyFocus = FocusNode();
  final _itemFocus = FocusNode();
  final _bagsFocus = FocusNode();
  final _caretsFocus = FocusNode();

  String? _partyError;
  String? _itemError;
  String? _bagsError;
  String? _caretsError;

  @override
  void dispose() {
    _party.dispose();
    _item.dispose();
    _bags.dispose();
    _carets.dispose();
    _partyFocus.dispose();
    _itemFocus.dispose();
    _bagsFocus.dispose();
    _caretsFocus.dispose();
    super.dispose();
  }

  void _save() {
    final party = _party.text.trim();
    final item = _item.text.trim();
    final bags = Money.tryParse(_bags.text.trim());
    final carets = Money.tryParse(_carets.text.trim());

    final result = TradingCalculator.validatePurchase(
      partyName: party,
      item: item,
      bags: bags ?? Money.zero,
      carets: carets ?? Money.zero,
      existing: widget.existing,
    );

    setState(() {
      _partyError = result.messageFor('partyName');
      _itemError = result.messageFor('item');
      _bagsError = result.messageFor('bags');
      _caretsError = result.messageFor('carets');
    });

    if (!result.isValid) return;

    final existing = widget.existing;
    final notifier = ref.read(purcSpatProvider.notifier);
    if (existing == null) {
      notifier.addLot(
        PurchaseLot(
          id: 'lot-${DateTime.now().millisecondsSinceEpoch}',
          srNo: notifier.nextSrNo,
          date: DateTime.now(),
          partyName: party,
          item: item,
          bags: bags!,
          totalCarets: carets ?? Money.zero,
          sales: const [],
        ),
      );
    } else {
      notifier.replaceLot(
        existing.copyWith(
          partyName: party,
          item: item,
          bags: bags!,
          totalCarets: carets ?? existing.totalCarets,
        ),
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add Truck' : 'Edit Truck'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ArrowKeyNav(
              next: _itemFocus,
              child: TextField(
                controller: _party,
                focusNode: _partyFocus,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Party Name',
                  errorText: _partyError,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ArrowKeyNav(
              next: _bagsFocus,
              previous: _partyFocus,
              child: TextField(
                controller: _item,
                focusNode: _itemFocus,
                decoration: InputDecoration(
                  labelText: 'Item',
                  errorText: _itemError,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ArrowKeyNav(
              next: _caretsFocus,
              previous: _itemFocus,
              child: TextField(
                controller: _bags,
                focusNode: _bagsFocus,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Bags',
                  errorText: _bagsError,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ArrowKeyNav(
              previous: _bagsFocus,
              child: TextField(
                controller: _carets,
                focusNode: _caretsFocus,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Carets (optional)',
                  errorText: _caretsError,
                ),
                onSubmitted: (_) => _save(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
