import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme_context.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/keyboard_nav.dart';
import '../../domain/models/purchase_lot.dart';
import '../../domain/models/rate_unit.dart';
import '../../domain/models/sale_line.dart';
import '../../domain/money.dart';
import '../../domain/calculators/trading_calculator.dart';
import '../../services/purc_spat_provider.dart';

/// Page 2 of Purc/SPAT: one truck and its customer-wise sales.
///
/// The truck's purchase details (party, item, bags, carets) stay pinned at the
/// top so the operator can eyeball the balance while entering sales below.
class PurcSpatDetailPage extends ConsumerWidget {
  const PurcSpatDetailPage({super.key, required this.lotId});

  final String lotId;

  Future<void> _openSaleDialog(
    BuildContext context,
    WidgetRef ref,
    PurchaseLot lot,
    SaleLine? sale,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _SaleDialog(lot: lot, initialSale: sale),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    PurchaseLot lot,
    SaleLine sale,
  ) {
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove sale?'),
        content: Text(
          'Sale #${sale.billNo} to ${sale.partyName} will be removed and its '
          'bags/carets will return to the truck balance.',
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
            child: const Text('Remove'),
          ),
        ],
      ),
    ).then((ok) {
      if (ok != true) return;
      ref.read(purcSpatProvider.notifier).removeSale(lot.id, sale.id);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lots = ref.watch(purcSpatProvider);
    PurchaseLot? lot;
    for (final candidate in lots) {
      if (candidate.id == lotId) {
        lot = candidate;
        break;
      }
    }

    final responsive = Responsive(context);

    if (lot == null) {
      return Padding(
        padding: EdgeInsets.all(responsive.contentPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: () => context.go('/data-entry/purc-spat'),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to trucks'),
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Icon(Icons.local_shipping_outlined,
                      size: 48, color: context.mutedText),
                  const SizedBox(height: 12),
                  const Text('Truck not found'),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(responsive.contentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TruckHeader(lot: lot),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Customers sold',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(width: 8),
              Text(
                '${lot.sales.length}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: context.mutedText,
                    ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: lot.isFullySold
                    ? null
                    : () => _openSaleDialog(context, ref, lot!, null),
                icon: const Icon(Icons.person_add_alt_1, size: 18),
                label: const Text('Add Customer'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
              child: _SalesList(
                  lot: lot, onOpen: _openSaleDialog, onDelete: _confirmDelete)),
        ],
      ),
    );
  }
}

/// Pinned truck details — party, item, bags, carets, sold, balance.
class _TruckHeader extends StatelessWidget {
  const _TruckHeader({required this.lot});

  final PurchaseLot lot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appCard,
        border: Border.all(color: context.appBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: () => context.go('/data-entry/purc-spat'),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Trucks'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 36),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Truck #${lot.srNo} — ${lot.item}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeaderChip(label: 'Party', value: lot.partyName),
              _HeaderChip(label: 'Date', value: _date),
              _HeaderChip(label: 'Bags', value: Money.formatQuantity(lot.bags)),
              if (lot.totalCarets > Money.zero)
                _HeaderChip(
                    label: 'Carets',
                    value: Money.formatQuantity(lot.totalCarets)),
              _HeaderChip(
                  label: 'Sold',
                  value: '${Money.formatQuantity(lot.soldBags)} bags'),
              _HeaderChip(
                  label: 'Balance',
                  value: '${Money.formatQuantity(lot.balanceBags)} bags',
                  highlight: true),
              if (lot.totalCarets > Money.zero)
                _HeaderChip(
                  label: 'Carets out',
                  value: Money.formatQuantity(lot.soldCarets),
                ),
              if (lot.totalCarets > Money.zero)
                _HeaderChip(
                  label: 'Carets left',
                  value: Money.formatQuantity(lot.balanceCarets),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String get _date {
    final d = lot.date;
    return '${d.day}/${d.month}/${d.year}';
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlight
            ? Theme.of(context).colorScheme.primary.withOpacity(0.10)
            : context.appCardElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlight
              ? Theme.of(context).colorScheme.primary.withOpacity(0.4)
              : context.appBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.mutedText,
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color:
                      highlight ? Theme.of(context).colorScheme.primary : null,
                ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Customer sales list
// ---------------------------------------------------------------------------

/// Scrollable list of the bags/carets sold out of a truck.
///
/// [onOpen] / [onDelete] forward the current [BuildContext] and [WidgetRef]
/// so the [PurcSpatDetailPage] can drive the provider without this widget
/// needing to know about Riverpod at all.
class _SalesList extends ConsumerWidget {
  const _SalesList({
    required this.lot,
    required this.onOpen,
    required this.onDelete,
  });

  final PurchaseLot lot;
  final Future<void> Function(
          BuildContext context, WidgetRef ref, PurchaseLot lot, SaleLine? sale)
      onOpen;
  final void Function(
          BuildContext context, WidgetRef ref, PurchaseLot lot, SaleLine sale)
      onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sales = lot.sales;
    if (sales.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_outline,
              size: 48,
              color: context.subtleText,
            ),
            const SizedBox(height: 12),
            Text(
              'No customers sold yet — press "Add Customer".',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.mutedText,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: sales.length,
      separatorBuilder: (context, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final sale = sales[index];
        return _CustomerCard(
          sale: sale,
          onTap: () => onOpen(context, ref, lot, sale),
          onDelete: () => onDelete(context, ref, lot, sale),
        );
      },
    );
  }
}

/// A single customer sale card showing party, bill, bags, weight, rate & amount.
class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.sale,
    required this.onTap,
    required this.onDelete,
  });

  final SaleLine sale;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final amount = sale.amount;
    final hasCarets = sale.carets > Money.zero;
    final isDark = context.isDarkMode;

    return Card(
      color: context.appCard,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: context.appBorder.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Theme.of(context)
              .colorScheme
              .primary
              .withOpacity(isDark ? 0.22 : 0.08),
          child: Text(
            _initials(sale.partyName),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        title: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              sale.partyName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (sale.mark != null && sale.mark!.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .secondaryContainer
                      .withOpacity(0.30),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  sale.mark!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          'Bill #${sale.billNo}  •  ${Money.formatQuantity(sale.bags)} bags'
          '${hasCarets ? ' + ${Money.formatQuantity(sale.carets)} ctrs' : ''}'
          '  •  ${Money.formatQuantity(sale.weight)} ${sale.unit.label}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.mutedText,
              ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              Money.formatCurrency(amount),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
            ),
            const SizedBox(width: 8),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Remove sale',
              icon: const Icon(Icons.close, size: 18),
              color: isDark
                  ? Colors.redAccent.shade100
                  : Colors.redAccent.shade700,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// ---------------------------------------------------------------------------
// Sale (customer) dialog
// ---------------------------------------------------------------------------

/// Common mark identifiers shown in the dropdown.
const List<String> _kSaleMarks = ['', 'SVC', 'ARC', 'OTHER'];

/// Dialog for adding a new customer sale or editing an existing one.
///
/// Mirrors the field-by-field validation + arrow-key data-entry flow of
/// [_TruckDialog] on page 1, but validates the sale against the truck
/// balance via [TradingCalculator.validateSale].
class _SaleDialog extends ConsumerStatefulWidget {
  const _SaleDialog({
    required this.lot,
    this.initialSale,
  });

  final PurchaseLot lot;
  final SaleLine? initialSale;

  @override
  ConsumerState<_SaleDialog> createState() => _SaleDialogState();
}

class _SaleDialogState extends ConsumerState<_SaleDialog> {
  // --- input controllers --------------------------------------------------
  late final TextEditingController _party = TextEditingController(
    text: widget.initialSale?.partyName ?? '',
  );
  late final TextEditingController _bill = TextEditingController(
    text: widget.initialSale == null
        ? ''
        : widget.initialSale!.billNo.toStringAsFixed(0),
  );
  late final ValueNotifier<String> _mark =
      ValueNotifier<String>(widget.initialSale?.mark ?? '');
  late final TextEditingController _bags = TextEditingController(
    text: widget.initialSale == null
        ? ''
        : Money.formatQuantity(widget.initialSale!.bags),
  );
  late final TextEditingController _carets = TextEditingController(
    text: widget.initialSale == null
        ? ''
        : Money.formatQuantity(widget.initialSale!.carets),
  );
  late final TextEditingController _weight = TextEditingController(
    text: widget.initialSale == null
        ? ''
        : Money.formatQuantity(widget.initialSale!.weight),
  );
  late final TextEditingController _rate = TextEditingController(
    text: widget.initialSale == null
        ? ''
        : Money.formatCurrency(widget.initialSale!.rate),
  );
  late final ValueNotifier<RateUnit> _unit =
      ValueNotifier<RateUnit>(widget.initialSale?.unit ?? RateUnit.perKg);

  // --- focus chain --------------------------------------------------------
  final _partyFocus = FocusNode();
  final _billFocus = FocusNode();
  final _markFocus = FocusNode();
  final _bagsFocus = FocusNode();
  final _caretsFocus = FocusNode();
  final _weightFocus = FocusNode();
  final _rateFocus = FocusNode();
  final _unitFocus = FocusNode();

  // --- field errors -------------------------------------------------------
  String? _partyError;
  String? _bagsError;
  String? _caretsError;
  String? _weightError;
  String? _rateError;

  @override
  void dispose() {
    _party.dispose();
    _bill.dispose();
    _mark.dispose();
    _bags.dispose();
    _carets.dispose();
    _weight.dispose();
    _rate.dispose();
    _unit.dispose();
    _partyFocus.dispose();
    _billFocus.dispose();
    _markFocus.dispose();
    _bagsFocus.dispose();
    _caretsFocus.dispose();
    _weightFocus.dispose();
    _rateFocus.dispose();
    _unitFocus.dispose();
    super.dispose();
  }

  void _save() {
    final party = _party.text.trim();
    final mark = _mark.value.trim();
    final bags = Money.tryParse(_bags.text.trim());
    final carets = Money.tryParse(_carets.text.trim());
    final weight = Money.tryParse(_weight.text.trim());
    final rate = Money.tryParse(_rate.text.trim());
    final unit = _unit.value;

    final result = TradingCalculator.validateSale(
      lot: widget.lot,
      partyName: party,
      bags: bags ?? Money.zero,
      carets: carets ?? Money.zero,
      weight: weight ?? Money.zero,
      rate: rate ?? Money.zero,
      replacing: widget.initialSale,
    );

    setState(() {
      _partyError = result.messageFor('partyName');
      _bagsError = result.messageFor('bags');
      _caretsError = result.messageFor('carets');
      _weightError = result.messageFor('weight');
      _rateError = result.messageFor('rate');
    });

    if (!result.isValid) return;

    final sale = SaleLine(
      id: widget.initialSale?.id ??
          'sale-${widget.lot.id}-${DateTime.now().millisecondsSinceEpoch}',
      billNo: widget.initialSale?.billNo ?? widget.lot.nextBillNo,
      date: widget.initialSale?.date ?? DateTime.now(),
      partyName: party,
      bags: bags!,
      carets: carets ?? Money.zero,
      weight: weight!,
      rate: rate!,
      unit: unit,
      mark: mark.isEmpty ? null : mark,
    );

    final notifier = ref.read(purcSpatProvider.notifier);
    final saveResult = widget.initialSale == null
        ? notifier.addSale(widget.lot.id, sale)
        : notifier.replaceSale(widget.lot.id, sale);

    if (!saveResult.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(saveResult.summary)),
      );
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialSale != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Customer' : 'Add Customer'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ArrowKeyNav(
              next: _billFocus,
              child: TextField(
                controller: _party,
                focusNode: _partyFocus,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Party Name',
                  errorText: _partyError,
                  hintText: 'e.g. Komal Ballu Ganj',
                ),
                onSubmitted: (_) => _billFocus.requestFocus(),
              ),
            ),
            const SizedBox(height: 12),
            ArrowKeyNav(
              next: _markFocus,
              previous: _partyFocus,
              child: TextField(
                controller: _bill,
                focusNode: _billFocus,
                keyboardType:
                    const TextInputType.numberWithOptions(signed: false),
                decoration: InputDecoration(
                  labelText: 'Bill No',
                  helperText: 'Blank = next bill (${widget.lot.nextBillNo})',
                ),
              ),
            ),
            const SizedBox(height: 12),
            ArrowKeyNav(
              next: _bagsFocus,
              previous: _billFocus,
              child: DropdownButtonFormField<String>(
                focusNode: _markFocus,
                value: _mark.value.isEmpty ? '' : _mark.value,
                items: _kSaleMarks
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(m.isEmpty ? '— none —' : m),
                        ))
                    .toList(),
                onChanged: (v) {
                  _mark.value = v ?? '';
                  _bagsFocus.requestFocus();
                },
                decoration: InputDecoration(
                  labelText: 'Mark',
                  hintText: 'SVC / ARC / OTHER',
                ),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            ArrowKeyNav(
              next: _caretsFocus,
              previous: _markFocus,
              child: TextField(
                controller: _bags,
                focusNode: _bagsFocus,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Bags',
                  errorText: _bagsError,
                  hintText: 'Bags sold',
                  suffixText: 'bags',
                ),
                onSubmitted: (_) => _caretsFocus.requestFocus(),
              ),
            ),
            const SizedBox(height: 12),
            ArrowKeyNav(
              next: _weightFocus,
              previous: _bagsFocus,
              child: TextField(
                controller: _carets,
                focusNode: _caretsFocus,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Carets (optional)',
                  errorText: _caretsError,
                  hintText: 'Crates returned',
                  suffixText: 'ctrs',
                ),
                onSubmitted: (_) => _weightFocus.requestFocus(),
              ),
            ),
            const SizedBox(height: 12),
            ArrowKeyNav(
              next: _rateFocus,
              previous: _caretsFocus,
              child: TextField(
                controller: _weight,
                focusNode: _weightFocus,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Weight',
                  errorText: _weightError,
                  suffixText: 'kg',
                ),
                onSubmitted: (_) => _rateFocus.requestFocus(),
              ),
            ),
            const SizedBox(height: 12),
            ArrowKeyNav(
              next: _unitFocus,
              previous: _weightFocus,
              child: TextField(
                controller: _rate,
                focusNode: _rateFocus,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Rate',
                  errorText: _rateError,
                  suffixText: '/ ${_unit.value.label}',
                ),
                onSubmitted: (_) => _unitFocus.requestFocus(),
              ),
            ),
            const SizedBox(height: 12),
            ArrowKeyNav(
              previous: _rateFocus,
              child: DropdownButtonFormField<RateUnit>(
                focusNode: _unitFocus,
                value: _unit.value,
                items: RateUnit.presets
                    .map((u) => DropdownMenuItem(
                          value: u,
                          child: Text(u.label),
                        ))
                    .toList(),
                onChanged: (u) {
                  if (u != null) setState(() => _unit.value = u);
                },
                decoration: InputDecoration(
                  labelText: 'Unit',
                  helperText: 'Rate applies per ${RateUnit.perKg.label}',
                ),
                isDense: true,
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
