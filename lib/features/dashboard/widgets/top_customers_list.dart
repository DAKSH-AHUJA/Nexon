import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/animated_counter.dart';
import '../../../core/widgets/nexon_card.dart';
import '../../../models/dashboard_model.dart';

/// Ranked list of top customers by purchase volume.
class TopCustomersList extends StatelessWidget {
  const TopCustomersList({super.key, required this.customers});

  final List<TopCustomer> customers;

  @override
  Widget build(BuildContext context) {
    return NexonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Customers',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ...customers.asMap().entries.map((entry) {
            return _CustomerRow(
              rank: entry.key + 1,
              customer: entry.value,
            );
          }),
        ],
      ),
    );
  }
}

class _CustomerRow extends StatelessWidget {
  const _CustomerRow({required this.rank, required this.customer});

  final int rank;
  final TopCustomer customer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rank <= 3
                  ? AppColors.emerald600.withValues(alpha: 0.15)
                  : context.appCardElevated,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$rank',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: rank <= 3 ? AppColors.emerald400 : null,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${customer.orders} orders',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedCounter(
                value: customer.totalPurchases,
                formatter: Formatters.currencyCompact,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (customer.outstanding > 0)
                Text(
                  '${Formatters.currencyCompact(customer.outstanding)} due',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.warning,
                      ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
