import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_context.dart';
import '../../core/utils/responsive.dart';
import '../../domain/money.dart';
import '../../domain/models/purchase_lot.dart';
import '../../services/purc_spat_provider.dart';

/// First page: Shows all trucks purchased, stretched full width.
/// Click a truck to navigate to its customer details.
class PurcSpatPage extends ConsumerWidget {
  const PurcSpatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lots = ref.watch(purcSpatProvider);
    final responsive = Responsive(context);
    final isDark = context.isDarkMode;

    return Container(
      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(responsive.contentPadding),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Purchase / Sale Entry',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select a truck to view or add customer details',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_outlined, size: 18),
                  label: const Text('Add Truck'),
                ),
              ],
            ),
          ),
          Expanded(
            child: lots.isEmpty
                ? Center(
                    child: Text(
                      'No trucks added yet. Click "Add Truck" to start.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.contentPadding,
                    ),
                    itemCount: lots.length,
                    itemBuilder: (context, index) {
                      final lot = lots[index];
                      return _TruckCard(
                        lot: lot,
                        isDark: isDark,
                        onTap: () => context.push(
                          '/data-entry/purc-spat/${lot.id}',
                        ),
                      );
                    },
                  ),
          ),

class _TruckCard extends StatelessWidget {
  const _TruckCard({
    required this.lot,
    required this.isDark,
    required this.onTap,
  });

  final PurchaseLot lot;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.emerald600.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${lot.srNo}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.emerald600,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lot.item,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Party: ${lot.partyName}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${Money.formatQuantity(lot.bags)} bags',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (lot.totalCarets > Money.zero) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${Money.formatQuantity(lot.totalCarets)} carets',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    '${lot.sales.length} customers',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.emerald500,
                        ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
        ],
      ),
    );
  }
}