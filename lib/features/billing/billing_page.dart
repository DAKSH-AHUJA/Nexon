import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/nexon_card.dart';
import '../../core/widgets/page_header.dart';
import '../../models/customer_model.dart';
import '../../models/invoice_model.dart';
import '../../models/product_model.dart';
import '../../services/billing_provider.dart';
import '../../services/customers_provider.dart';
import '../../services/products_provider.dart';
import 'widgets/invoice_preview_dialog.dart';

class BillingPage extends ConsumerWidget {
  const BillingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(billingProvider);
    final customers = ref.watch(customersProvider).customers;
    final products = ref.watch(productsProvider).products;
    final responsive = Responsive(context);

    return Padding(
      padding: EdgeInsets.all(responsive.contentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Billing',
            subtitle: 'Create and manage invoices',
            actions: [
              if (draft.items.isNotEmpty)
                OutlinedButton(
                  onPressed: () {
                    ref.read(billingProvider.notifier).clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Draft cleared')),
                    );
                  },
                  child: const Text('Clear'),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: responsive.isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _InvoiceBuilder(
                          draft: draft,
                          customers: customers,
                          products: products,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _InvoiceSummary(draft: draft),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        _InvoiceBuilder(
                          draft: draft,
                          customers: customers,
                          products: products,
                        ),
                        const SizedBox(height: 16),
                        _InvoiceSummary(draft: draft),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceBuilder extends ConsumerWidget {
  const _InvoiceBuilder({
    required this.draft,
    required this.customers,
    required this.products,
  });

  final InvoiceDraft draft;
  final List<Customer> customers;
  final List<Product> products;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NexonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New Invoice', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          DropdownButtonFormField<Customer>(
            initialValue: draft.customer,
            decoration: const InputDecoration(
              labelText: 'Select Customer *',
              isDense: true,
            ),
            items: customers
                .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                .toList(),
            onChanged: (c) =>
                ref.read(billingProvider.notifier).selectCustomer(c),
          ),
          const SizedBox(height: 16),
          _ProductSearch(products: products),
          const SizedBox(height: 16),
          if (draft.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Add products to the invoice')),
            )
          else
            ...draft.items.asMap().entries.map((entry) {
              return _LineItemRow(
                index: entry.key,
                item: entry.value,
              );
            }),
        ],
      ),
    );
  }
}

class _ProductSearch extends ConsumerStatefulWidget {
  const _ProductSearch({required this.products});

  final List<Product> products;

  @override
  ConsumerState<_ProductSearch> createState() => _ProductSearchState();
}

class _ProductSearchState extends ConsumerState<_ProductSearch> {
  final _searchCtrl = TextEditingController();
  bool _showResults = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Product> get _filtered {
    final q = _searchCtrl.text.toLowerCase();
    if (q.isEmpty) return [];
    return widget.products
        .where((p) => p.name.toLowerCase().contains(q))
        .take(5)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchCtrl,
          decoration: const InputDecoration(
            labelText: 'Search Product',
            prefixIcon: Icon(Icons.search, size: 20),
            isDense: true,
          ),
          onChanged: (_) => setState(() => _showResults = true),
          onTap: () => setState(() => _showResults = true),
        ),
        if (_showResults && _filtered.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.lightBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: _filtered.map((p) {
                return ListTile(
                  dense: true,
                  title: Text(p.name),
                  subtitle: Text(
                    '${Formatters.currency(p.sellingPrice)}/${p.unit} · Stock: ${p.currentStock}',
                  ),
                  onTap: () {
                    ref.read(billingProvider.notifier).addItem(p);
                    _searchCtrl.clear();
                    setState(() => _showResults = false);
                  },
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _LineItemRow extends ConsumerWidget {
  const _LineItemRow({required this.index, required this.item});

  final int index;
  final InvoiceLineItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(item.product.name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          SizedBox(
            width: 70,
            child: TextFormField(
              initialValue: item.quantity.toString(),
              decoration:
                  const InputDecoration(labelText: 'Qty', isDense: true),
              keyboardType: TextInputType.number,
              onChanged: (v) {
                final q = double.tryParse(v);
                if (q != null && q > 0) {
                  ref.read(billingProvider.notifier).updateItem(
                        index,
                        item.copyWith(quantity: q),
                      );
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: TextFormField(
              initialValue: item.price.toString(),
              decoration:
                  const InputDecoration(labelText: 'Price', isDense: true),
              keyboardType: TextInputType.number,
              onChanged: (v) {
                final p = double.tryParse(v);
                if (p != null && p > 0) {
                  ref.read(billingProvider.notifier).updateItem(
                        index,
                        item.copyWith(price: p),
                      );
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: TextFormField(
              initialValue: item.discount.toString(),
              decoration:
                  const InputDecoration(labelText: 'Disc%', isDense: true),
              keyboardType: TextInputType.number,
              onChanged: (v) {
                final d = double.tryParse(v) ?? 0;
                ref.read(billingProvider.notifier).updateItem(
                      index,
                      item.copyWith(discount: d.clamp(0, 100)),
                    );
              },
            ),
          ),
          const SizedBox(width: 12),
          Text(Formatters.currency(item.total)),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () =>
                ref.read(billingProvider.notifier).removeItem(index),
          ),
        ],
      ),
    );
  }
}

class _InvoiceSummary extends ConsumerWidget {
  const _InvoiceSummary({required this.draft});

  final InvoiceDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NexonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Summary', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          _SummaryRow(
              label: 'Subtotal', value: Formatters.currency(draft.subtotal)),
          _SummaryRow(label: 'GST', value: Formatters.currency(draft.totalGst)),
          const Divider(height: 24),
          _SummaryRow(
            label: 'Grand Total',
            value: Formatters.currency(draft.grandTotal),
            bold: true,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: draft.isValid
                  ? () {
                      final updated =
                          ref.read(billingProvider.notifier).finalize();
                      showDialog<void>(
                        context: context,
                        builder: (_) => InvoicePreviewDialog(draft: updated),
                      );
                    }
                  : null,
              child: const Text('Generate Invoice'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: draft.isValid
                  ? () => showDialog<void>(
                        context: context,
                        builder: (_) => InvoicePreviewDialog(draft: draft),
                      )
                  : null,
              child: const Text('Preview Invoice'),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: draft.isValid
                      ? () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'WhatsApp share simulated — invoice sent!'),
                            ),
                          )
                      : null,
                  icon: const Icon(Icons.chat, size: 18),
                  label: const Text('WhatsApp'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: draft.isValid
                      ? () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'PDF download simulated — saved to Downloads'),
                            ),
                          )
                      : null,
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('PDF'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontWeight: bold ? FontWeight.w700 : null)),
          Text(value,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w600)),
        ],
      ),
    );
  }
}
