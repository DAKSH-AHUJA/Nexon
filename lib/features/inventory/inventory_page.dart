import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/nexon_card.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/status_chip.dart';
import '../../models/product_model.dart';
import '../../services/products_provider.dart';
import 'widgets/stock_adjustment_dialog.dart';

class InventoryPage extends ConsumerWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productsProvider);
    final responsive = Responsive(context);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null) {
      return ErrorState(
        message: state.errorMessage!,
        onRetry: () => ref.read(productsProvider.notifier).load(),
      );
    }

    return Padding(
      padding: EdgeInsets.all(responsive.contentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Inventory',
            subtitle: '${state.products.length} products · ${state.transactions.length} transactions',
          ),
          const SizedBox(height: 20),
          _InventoryToolbar(state: state),
          const SizedBox(height: 16),
          Expanded(
            child: responsive.isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _ProductGrid(state: state)),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: _TimelinePanel(state: state)),
                    ],
                  )
                : Column(
                    children: [
                      Expanded(flex: 2, child: _ProductGrid(state: state)),
                      const SizedBox(height: 16),
                      Expanded(child: _TimelinePanel(state: state)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _InventoryToolbar extends ConsumerWidget {
  const _InventoryToolbar({required this.state});

  final ProductsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        TextField(
          decoration: const InputDecoration(
            hintText: 'Search products...',
            prefixIcon: Icon(Icons.search, size: 20),
            isDense: true,
          ),
          onChanged: (v) => ref.read(productsProvider.notifier).setSearch(v),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                label: const Text('All'),
                selected: state.categoryFilter == null && state.filter == ProductFilter.all,
                onSelected: (_) {
                  ref.read(productsProvider.notifier).setCategory(null);
                  ref.read(productsProvider.notifier).setFilter(ProductFilter.all);
                },
              ),
              ...ProductFilter.values.where((f) => f != ProductFilter.all).map((f) {
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: FilterChip(
                    label: Text(_filterLabel(f)),
                    selected: state.filter == f,
                    onSelected: (_) => ref.read(productsProvider.notifier).setFilter(f),
                  ),
                );
              }),
              const SizedBox(width: 8),
              ...state.categories.map((cat) {
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: state.categoryFilter == cat,
                    onSelected: (_) =>
                        ref.read(productsProvider.notifier).setCategory(cat),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  String _filterLabel(ProductFilter f) => switch (f) {
        ProductFilter.lowStock => 'Low Stock',
        ProductFilter.outOfStock => 'Out of Stock',
        ProductFilter.all => 'All',
      };
}

class _ProductGrid extends ConsumerWidget {
  const _ProductGrid({required this.state});

  final ProductsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = state.filtered;

    if (products.isEmpty) {
      return const NexonCard(
        child: EmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'No products found',
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) => _ProductCard(product: products[index]),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  const _ProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = product.stockStatus;
    final statusChip = switch (status) {
      StockStatus.inStock => StatusChip.success('In Stock'),
      StockStatus.lowStock => StatusChip.warning('Low Stock'),
      StockStatus.outOfStock => StatusChip.danger('Out of Stock'),
    };

    return NexonCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              statusChip,
            ],
          ),
          const SizedBox(height: 4),
          Text(
            product.category,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Stock', style: Theme.of(context).textTheme.labelSmall),
                  Text(
                    '${Formatters.number(product.currentStock)} ${product.unit}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Sell', style: Theme.of(context).textTheme.labelSmall),
                  Text(
                    Formatters.currency(product.sellingPrice),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showAdjust(context, ref, 'stock_in'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('+ Add', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showAdjust(context, ref, 'stock_out'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('- Remove', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAdjust(BuildContext context, WidgetRef ref, String type) {
    showDialog<void>(
      context: context,
      builder: (_) => StockAdjustmentDialog(product: product, type: type),
    );
  }
}

class _TimelinePanel extends StatelessWidget {
  const _TimelinePanel({required this.state});

  final ProductsState state;

  @override
  Widget build(BuildContext context) {
    final txns = state.transactions.take(20).toList();

    return NexonCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Stock History', style: Theme.of(context).textTheme.titleMedium),
          ),
          const Divider(height: 1),
          Expanded(
            child: txns.isEmpty
                ? const EmptyState(icon: Icons.history, title: 'No transactions yet')
                : ListView.separated(
                    itemCount: txns.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final t = txns[index];
                      final icon = switch (t.type) {
                        'stock_in' => Icons.add_circle_outline,
                        'stock_out' => Icons.remove_circle_outline,
                        _ => Icons.tune,
                      };
                      final color = switch (t.type) {
                        'stock_in' => AppColors.success,
                        'stock_out' => AppColors.danger,
                        _ => AppColors.warning,
                      };

                      return ListTile(
                        leading: Icon(icon, color: color, size: 20),
                        title: Text('${t.productName} · ${t.quantity}'),
                        subtitle: Text(t.note.isEmpty ? t.type : t.note),
                        trailing: Text(
                          Formatters.relativeTime(t.date),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
