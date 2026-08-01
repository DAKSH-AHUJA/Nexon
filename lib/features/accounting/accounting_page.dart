import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/nexon_card.dart';
import '../../core/widgets/page_header.dart';
import '../../services/suppliers_provider.dart';

class AccountingPage extends ConsumerWidget {
  const AccountingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(accountingDataProvider);
    final responsive = Responsive(context);

    return Padding(
      padding: EdgeInsets.all(responsive.contentPadding),
      child: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) => _AccountingContent(data: data, responsive: responsive),
      ),
    );
  }
}

class _AccountingContent extends StatelessWidget {
  const _AccountingContent({required this.data, required this.responsive});

  final Map<String, dynamic> data;
  final Responsive responsive;

  @override
  Widget build(BuildContext context) {
    final cashBook = data['cashBook'] as Map<String, dynamic>;
    final profit = data['profitSummary'] as Map<String, dynamic>;
    final expenses = (data['expenses'] as List<dynamic>);
    final payments = (data['payments'] as List<dynamic>);
    final banks = (data['bankAccounts'] as List<dynamic>);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Accounting',
            subtitle: 'Cash book, expenses, and profit summary',
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: responsive.value(mobile: 1, tablet: 2, desktop: 4),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: [
              _StatCard(
                label: 'Cash In',
                value: Formatters.currency(cashBook['totalIn']),
                color: AppColors.success,
              ),
              _StatCard(
                label: 'Cash Out',
                value: Formatters.currency(cashBook['totalOut']),
                color: AppColors.danger,
              ),
              _StatCard(
                label: 'Closing Balance',
                value: Formatters.currency(cashBook['closingBalance']),
                color: AppColors.emerald600,
              ),
              _StatCard(
                label: 'Net Profit',
                value: Formatters.currency(profit['netProfit']),
                color: AppColors.blue500,
              ),
            ],
          ),
          const SizedBox(height: 20),
          responsive.isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _ExpensesList(expenses: expenses)),
                    const SizedBox(width: 16),
                    Expanded(child: _PaymentsList(payments: payments)),
                  ],
                )
              : Column(
                  children: [
                    _ExpensesList(expenses: expenses),
                    const SizedBox(height: 16),
                    _PaymentsList(payments: payments),
                  ],
                ),
          const SizedBox(height: 20),
          _ProfitChart(profit: profit),
          const SizedBox(height: 20),
          _BankAccounts(banks: banks),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return NexonCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

class _ExpensesList extends StatelessWidget {
  const _ExpensesList({required this.expenses});

  final List<dynamic> expenses;

  @override
  Widget build(BuildContext context) {
    return NexonCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text('Expenses', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                OutlinedButton(onPressed: () {}, child: const Text('Add')),
              ],
            ),
          ),
          const Divider(height: 1),
          ...expenses.map((e) {
            final exp = e as Map<String, dynamic>;
            return ListTile(
              title: Text(exp['description'] as String),
              subtitle: Text('${exp['category']} · ${exp['paymentMode']}'),
              trailing: Text(
                Formatters.currency((exp['amount'] as num).toDouble()),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _PaymentsList extends StatelessWidget {
  const _PaymentsList({required this.payments});

  final List<dynamic> payments;

  @override
  Widget build(BuildContext context) {
    return NexonCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Recent Payments', style: Theme.of(context).textTheme.titleMedium),
          ),
          const Divider(height: 1),
          ...payments.map((p) {
            final pay = p as Map<String, dynamic>;
            final isReceipt = pay['type'] == 'customer_receipt';
            return ListTile(
              leading: Icon(
                isReceipt ? Icons.arrow_downward : Icons.arrow_upward,
                color: isReceipt ? AppColors.success : AppColors.danger,
                size: 20,
              ),
              title: Text(pay['party'] as String),
              subtitle: Text('${pay['mode']} · ${Formatters.date(DateTime.parse(pay['date'] as String))}'),
              trailing: Text(
                Formatters.currency((pay['amount'] as num).toDouble()),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isReceipt ? AppColors.success : AppColors.danger,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ProfitChart extends StatelessWidget {
  const _ProfitChart({required this.profit});

  final Map<String, dynamic> profit;

  @override
  Widget build(BuildContext context) {
    final revenue = (profit['revenue'] as num).toDouble();
    final cogs = (profit['cogs'] as num).toDouble();
    final expenses = (profit['expenses'] as num).toDouble();
    final net = (profit['netProfit'] as num).toDouble();

    return NexonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Profit Summary', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: revenue * 1.1,
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        const labels = ['Revenue', 'COGS', 'Expenses', 'Net'];
                        final i = v.toInt();
                        if (i < 0 || i >= labels.length) return const SizedBox();
                        return Text(labels[i], style: const TextStyle(fontSize: 11));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _bar(0, revenue, AppColors.emerald500),
                  _bar(1, cogs, AppColors.orange500),
                  _bar(2, expenses, AppColors.danger),
                  _bar(3, net, AppColors.blue500),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _bar(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [BarChartRodData(toY: y, color: color, width: 32, borderRadius: BorderRadius.circular(4))],
    );
  }
}

class _BankAccounts extends StatelessWidget {
  const _BankAccounts({required this.banks});

  final List<dynamic> banks;

  @override
  Widget build(BuildContext context) {
    return NexonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bank Accounts', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...banks.map((b) {
            final bank = b as Map<String, dynamic>;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.account_balance, color: AppColors.blue500),
              title: Text(bank['name'] as String),
              subtitle: Text(bank['accountNo'] as String),
              trailing: Text(
                Formatters.currency((bank['balance'] as num).toDouble()),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            );
          }),
        ],
      ),
    );
  }
}
