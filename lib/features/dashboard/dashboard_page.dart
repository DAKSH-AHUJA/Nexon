import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_context.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/animated_counter.dart';
import '../../core/widgets/async_value_view.dart';
import '../../core/widgets/nexon_card.dart';
import '../../core/widgets/nexon_skeleton.dart';
import '../../models/dashboard_model.dart';
import '../../services/data_service.dart';
import 'widgets/dashboard_charts.dart';
import 'widgets/recent_activity_list.dart';
import 'widgets/recent_bills_table.dart';
import 'widgets/recent_payments_list.dart';
import 'widgets/top_customers_list.dart';

/// Main dashboard with KPIs, charts, and recent activity.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardDataProvider);
    final responsive = Responsive(context);

    return _DashboardContent(
      padding: responsive.contentPadding,
      child: AsyncValueView(
        value: dashboardAsync,
        loading: const DashboardSkeleton(),
        errorMessage: 'Failed to load dashboard',
        data: (data) => _DashboardBody(data: data, responsive: responsive),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.padding, required this.child});

  final double padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: child,
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.data, required this.responsive});

  final DashboardData data;
  final Responsive responsive;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header().animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 24),
        _StatsGrid(stats: data.stats, responsive: responsive)
            .animate()
            .fadeIn(delay: 100.ms, duration: 500.ms),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            if (responsive.isDesktop) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        MonthlySalesChart(data: data.monthlySales),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: RecentBillsTable(bills: data.recentBills),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: RecentPaymentsList(
                                  payments: data.recentPayments),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        InventoryChart(data: data.inventoryByCategory),
                        const SizedBox(height: 20),
                        RecentActivityList(activities: data.recentActivity),
                        const SizedBox(height: 20),
                        TopCustomersList(customers: data.topCustomers),
                      ],
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                MonthlySalesChart(data: data.monthlySales),
                const SizedBox(height: 20),
                InventoryChart(data: data.inventoryByCategory),
                const SizedBox(height: 20),
                RecentActivityList(activities: data.recentActivity),
                const SizedBox(height: 20),
                TopCustomersList(customers: data.topCustomers),
                const SizedBox(height: 20),
                RecentBillsTable(bills: data.recentBills),
                const SizedBox(height: 20),
                RecentPaymentsList(payments: data.recentPayments),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = _greeting(now.hour);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, Admin',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 4),
              Text(
                "Here's what's happening with ${Formatters.date(now)}",
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: context.mutedText),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => context.go('/billing'),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('New Invoice'),
        ),
      ],
    );
  }

  String _greeting(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats, required this.responsive});

  final DashboardStats stats;
  final Responsive responsive;

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem(
        label: "Today's Sales",
        value: stats.todaySales,
        formatter: Formatters.currency,
        icon: Icons.trending_up_rounded,
        color: AppColors.emerald500,
        trend: '+12.5%',
      ),
      _StatItem(
        label: "Today's Profit",
        value: stats.todayProfit,
        formatter: Formatters.currency,
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.blue500,
        trend: '+8.2%',
      ),
      _StatItem(
        label: "Today's Cash",
        value: stats.todayCash,
        formatter: Formatters.currency,
        icon: Icons.payments_outlined,
        color: AppColors.orange500,
        trend: '+5.1%',
      ),
      _StatItem(
        label: 'Outstanding',
        value: stats.outstandingAmount,
        formatter: Formatters.currencyCompact,
        icon: Icons.pending_actions_outlined,
        color: AppColors.warning,
        trend: '-3.4%',
        trendDown: true,
      ),
      _StatItem(
        label: 'Inventory Value',
        value: stats.inventoryValue,
        formatter: Formatters.currencyCompact,
        icon: Icons.inventory_2_outlined,
        color: AppColors.info,
      ),
      _StatItem(
        label: "Today's Orders",
        value: stats.todayOrders.toDouble(),
        formatter: (v) => Formatters.number(v.toInt()),
        icon: Icons.shopping_cart_outlined,
        color: AppColors.emerald400,
        trend: '+6 today',
      ),
      _StatItem(
        label: 'Low Stock Alerts',
        value: stats.lowStockAlerts.toDouble(),
        formatter: (v) => Formatters.number(v.toInt()),
        icon: Icons.warning_amber_rounded,
        color: AppColors.danger,
        isAlert: true,
      ),
    ];

    final crossAxisCount = responsive.value(mobile: 1, tablet: 2, desktop: 4);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio:
            responsive.value(mobile: 2.2, tablet: 2.0, desktop: 1.8),
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return items[index]
            .animate(delay: (index * 50).ms)
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.08);
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.formatter,
    required this.icon,
    required this.color,
    this.trend,
    this.trendDown = false,
    this.isAlert = false,
  });

  final String label;
  final double value;
  final String Function(double) formatter;
  final IconData icon;
  final Color color;
  final String? trend;
  final bool trendDown;
  final bool isAlert;

  @override
  Widget build(BuildContext context) {
    return NexonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              if (trend != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (trendDown ? AppColors.danger : AppColors.success)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    trend!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color:
                              trendDown ? AppColors.danger : AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          AnimatedCounter(
            value: value,
            formatter: formatter,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isAlert && value > 0 ? AppColors.danger : null,
                ),
          ),
        ],
      ),
    );
  }
}
