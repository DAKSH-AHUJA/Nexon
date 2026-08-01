import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/nexon_card.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/status_chip.dart';
import '../../models/customer_model.dart';
import '../../services/customers_provider.dart';
import 'widgets/customer_form_dialog.dart';

class CustomersPage extends ConsumerWidget {
  const CustomersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(customersProvider);
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
            title: 'Customers',
            subtitle: '${state.customers.length} total customers',
            actions: [
              ElevatedButton.icon(
                onPressed: () => _showForm(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Customer'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Toolbar(ref: ref, state: state),
          const SizedBox(height: 16),
          Expanded(
            child: responsive.isDesktop || responsive.isTablet
                ? _MasterDetailLayout(state: state, ref: ref)
                : _CustomerList(
                    customers: state.filtered,
                    selectedId: state.selectedId,
                    onSelect: (id) =>
                        ref.read(customersProvider.notifier).select(id),
                    onEdit: (c) => _showForm(context, ref, customer: c),
                    onDelete: (c) => _confirmDelete(context, ref, c),
                    showDetailOnTap: true,
                  ),
          ),
        ],
      ),
    );
  }

  void _showForm(BuildContext context, WidgetRef ref, {Customer? customer}) {
    showDialog<void>(
      context: context,
      builder: (_) => CustomerFormDialog(customer: customer),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Customer customer,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Remove "${customer.name}" from your customer list?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(customersProvider.notifier).deleteCustomer(customer.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${customer.name} deleted')),
        );
      }
    }
  }
}

class _Toolbar extends ConsumerWidget {
  const _Toolbar({required this.ref, required this.state});

  final WidgetRef ref;
  final CustomersState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search by name, phone, or city...',
              prefixIcon: Icon(Icons.search, size: 20),
              isDense: true,
            ),
            onChanged: (v) =>
                ref.read(customersProvider.notifier).setSearch(v),
          ),
        ),
        const SizedBox(width: 12),
        ...CustomerFilter.values.map((f) {
          final selected = state.filter == f;
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: FilterChip(
              label: Text(_filterLabel(f)),
              selected: selected,
              onSelected: (_) =>
                  ref.read(customersProvider.notifier).setFilter(f),
            ),
          );
        }),
      ],
    );
  }

  String _filterLabel(CustomerFilter f) => switch (f) {
        CustomerFilter.all => 'All',
        CustomerFilter.active => 'Active',
        CustomerFilter.outstanding => 'Outstanding',
      };
}

class _MasterDetailLayout extends ConsumerWidget {
  const _MasterDetailLayout({required this.state, required this.ref});

  final CustomersState state;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = state.selected;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _CustomerList(
            customers: state.filtered,
            selectedId: state.selectedId,
            onSelect: (id) => ref.read(customersProvider.notifier).select(id),
            onEdit: (c) {
              showDialog<void>(
                context: context,
                builder: (_) => CustomerFormDialog(customer: c),
              );
            },
            onDelete: (c) async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Customer'),
                  content: Text('Remove "${c.name}"?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                ref.read(customersProvider.notifier).deleteCustomer(c.id);
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: selected == null
              ? const NexonCard(
                  child: EmptyState(
                    icon: Icons.person_outline,
                    title: 'Select a customer',
                    subtitle: 'Choose from the list to view details',
                  ),
                )
              : _CustomerDetail(
                  customer: selected,
                  onEdit: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => CustomerFormDialog(customer: selected),
                    );
                  },
                  onDelete: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Customer'),
                        content: Text('Remove "${selected.name}"?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      ref.read(customersProvider.notifier).deleteCustomer(selected.id);
                    }
                  },
                ),
        ),
      ],
    );
  }
}

class _CustomerList extends StatelessWidget {
  const _CustomerList({
    required this.customers,
    required this.selectedId,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
    this.showDetailOnTap = false,
  });

  final List<Customer> customers;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final ValueChanged<Customer> onEdit;
  final ValueChanged<Customer> onDelete;
  final bool showDetailOnTap;

  @override
  Widget build(BuildContext context) {
    if (customers.isEmpty) {
      return const NexonCard(
        child: EmptyState(
          icon: Icons.people_outline,
          title: 'No customers found',
          subtitle: 'Try adjusting your search or filters',
        ),
      );
    }

    return NexonCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        itemCount: customers.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final c = customers[index];
          final selected = c.id == selectedId;

          return ListTile(
            selected: selected,
            selectedTileColor: AppColors.emerald500.withValues(alpha: 0.06),
            onTap: () {
              onSelect(c.id);
              if (showDetailOnTap) {
                _showMobileDetail(context, c, onEdit, onDelete);
              }
            },
            title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${c.city} · ${c.phone}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (c.hasOutstanding)
                  StatusChip.warning(Formatters.currencyCompact(c.outstandingBalance)),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  onSelected: (v) {
                    if (v == 'edit') onEdit(c);
                    if (v == 'delete') onDelete(c);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showMobileDetail(
    BuildContext context,
    Customer c,
    ValueChanged<Customer> onEdit,
    ValueChanged<Customer> onDelete,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          child: _CustomerDetail(
            customer: c,
            onEdit: () {
              Navigator.pop(ctx);
              onEdit(c);
            },
            onDelete: () {
              Navigator.pop(ctx);
              onDelete(c);
            },
          ),
        ),
      ),
    );
  }
}

class _CustomerDetail extends StatelessWidget {
  const _CustomerDetail({
    required this.customer,
    required this.onEdit,
    required this.onDelete,
  });

  final Customer customer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return NexonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.emerald500.withValues(alpha: 0.12),
                child: Text(
                  customer.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.emerald600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.name, style: Theme.of(context).textTheme.titleLarge),
                    Text(customer.city, style: TextStyle(color: muted)),
                  ],
                ),
              ),
              OutlinedButton(onPressed: onEdit, child: const Text('Edit')),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _InfoItem(label: 'Phone', value: customer.phone),
              _InfoItem(label: 'Email', value: customer.email.isEmpty ? '—' : customer.email),
              _InfoItem(label: 'GST', value: customer.gst.isEmpty ? '—' : customer.gst),
              _InfoItem(label: 'Address', value: customer.address),
              _InfoItem(
                label: 'Outstanding',
                value: Formatters.currency(customer.outstandingBalance),
                highlight: customer.hasOutstanding,
              ),
              _InfoItem(
                label: 'Total Purchases',
                value: Formatters.currency(customer.totalPurchases),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Purchase History', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (customer.purchaseHistory.isEmpty)
            Text('No purchases yet', style: TextStyle(color: muted))
          else
            ...customer.purchaseHistory.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(p.invoiceNo)),
                      Text(Formatters.date(p.date)),
                      const SizedBox(width: 16),
                      Text(Formatters.currency(p.amount)),
                      const SizedBox(width: 12),
                      StatusChip(
                        label: p.status,
                        color: p.status == 'paid' ? AppColors.success : AppColors.warning,
                      ),
                    ],
                  ),
                )),
          if (customer.ledger.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Ledger', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...customer.ledger.map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(l.description, overflow: TextOverflow.ellipsis),
                      ),
                      Text(Formatters.date(l.date)),
                      const SizedBox(width: 12),
                      if (l.debit > 0) Text('Dr ${Formatters.currency(l.debit)}'),
                      if (l.credit > 0) Text('Cr ${Formatters.currency(l.credit)}'),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: highlight ? AppColors.warning : null,
                ),
          ),
        ],
      ),
    );
  }
}
