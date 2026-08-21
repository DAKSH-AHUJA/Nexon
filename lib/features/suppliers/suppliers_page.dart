import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_context.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/info_item.dart';
import '../../core/widgets/nexon_card.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/search_field.dart';
import '../../core/widgets/status_chip.dart';
import '../../core/widgets/transaction_row.dart';
import '../../models/supplier_model.dart';
import '../../services/suppliers_provider.dart';

class SuppliersPage extends ConsumerWidget {
  const SuppliersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(suppliersProvider);
    final responsive = Responsive(context);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: EdgeInsets.all(responsive.contentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Suppliers',
            subtitle: '${state.suppliers.length} suppliers',
          ),
          const SizedBox(height: 20),
          SearchField(
            hintText: 'Search suppliers...',
            onChanged: (v) => ref.read(suppliersProvider.notifier).setSearch(v),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: responsive.isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _SupplierList(state: state),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: state.selected == null
                            ? const NexonCard(
                                child: EmptyState(
                                  icon: Icons.local_shipping_outlined,
                                  title: 'Select a supplier',
                                ),
                              )
                            : _SupplierDetail(supplier: state.selected!),
                      ),
                    ],
                  )
                : _SupplierList(state: state, mobile: true),
          ),
        ],
      ),
    );
  }
}

class _SupplierList extends ConsumerWidget {
  const _SupplierList({required this.state, this.mobile = false});

  final SuppliersState state;
  final bool mobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliers = state.filtered;

    if (suppliers.isEmpty) {
      return const NexonCard(
        child: EmptyState(
          icon: Icons.local_shipping_outlined,
          title: 'No suppliers found',
        ),
      );
    }

    return NexonCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        itemCount: suppliers.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final s = suppliers[index];
          final selected = s.id == state.selectedId;

          return ListTile(
            selected: selected,
            selectedTileColor: AppColors.emerald500.withValues(alpha: 0.06),
            onTap: () {
              ref.read(suppliersProvider.notifier).select(s.id);
              if (mobile) {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (ctx) => DraggableScrollableSheet(
                    expand: false,
                    initialChildSize: 0.7,
                    builder: (_, controller) => SingleChildScrollView(
                      controller: controller,
                      padding: const EdgeInsets.all(20),
                      child: _SupplierDetail(supplier: s),
                    ),
                  ),
                );
              }
            },
            title: Text(
              s.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('${s.city} · ${s.phone}'),
            trailing: s.outstandingPayment > 0
                ? StatusChip.warning(
                    Formatters.currencyCompact(s.outstandingPayment),
                  )
                : StatusChip.success('Paid up'),
          );
        },
      ),
    );
  }
}

class _SupplierDetail extends StatelessWidget {
  const _SupplierDetail({required this.supplier});

  final Supplier supplier;

  @override
  Widget build(BuildContext context) {
    final muted = context.mutedText;

    return NexonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(supplier.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(supplier.city, style: TextStyle(color: muted)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              InfoItem(label: 'Phone', value: supplier.phone),
              InfoItem(
                label: 'Email',
                value: supplier.email.isEmpty ? '—' : supplier.email,
              ),
              InfoItem(
                label: 'GST',
                value: supplier.gst.isEmpty ? '—' : supplier.gst,
              ),
              InfoItem(label: 'Address', value: supplier.address),
              InfoItem(
                label: 'Outstanding',
                value: Formatters.currency(supplier.outstandingPayment),
              ),
              InfoItem(
                label: 'Total Purchases',
                value: Formatters.currency(supplier.totalPurchases),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Purchase History',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (supplier.purchaseHistory.isEmpty)
            Text('No purchase orders', style: TextStyle(color: muted))
          else
            ...supplier.purchaseHistory.map((p) => TransactionRow(
                  reference: p.poNo,
                  date: p.date,
                  amount: p.amount,
                  status: p.status,
                )),
        ],
      ),
    );
  }
}
