import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/messages.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/async_value_view.dart';
import '../../core/widgets/chart_axis.dart';
import '../../core/widgets/metric_card.dart';
import '../../core/widgets/nexon_card.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/section_card.dart';
import '../../services/suppliers_provider.dart';

enum ReportTab { sales, lotWise, customers, profit }

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  ReportTab _tab = ReportTab.sales;

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(reportsDataProvider);
    final responsive = Responsive(context);

    return Padding(
      padding: EdgeInsets.all(responsive.contentPadding),
      child: AsyncValueView(
        value: dataAsync,
        data: (data) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Reports',
              subtitle:
                  'Statements, outstanding, lot-wise, party-wise, and profit reports',
              actions: [
                OutlinedButton.icon(
                  onPressed: () =>
                      context.showMessage('Export started - CSV saved'),
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Export'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SegmentedButton<ReportTab>(
              segments: const [
                ButtonSegment(value: ReportTab.sales, label: Text('Sales')),
                ButtonSegment(
                    value: ReportTab.lotWise, label: Text('Lot Wise')),
                ButtonSegment(
                    value: ReportTab.customers, label: Text('Customers')),
                ButtonSegment(value: ReportTab.profit, label: Text('Profit')),
              ],
              selected: {_tab},
              onSelectionChanged: (s) => setState(() => _tab = s.first),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: switch (_tab) {
                  ReportTab.sales => _SalesReport(data: data['salesReport']),
                  ReportTab.lotWise =>
                    _LotWiseReport(data: data['inventoryReport']),
                  ReportTab.customers =>
                    _CustomerReport(data: data['customerReport']),
                  ReportTab.profit => _ProfitReport(data: data['profitReport']),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SalesReport extends StatelessWidget {
  const _SalesReport({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final monthly = (data['monthlyData'] as List<dynamic>);

    return Column(
      children: [
        MetricRow(
          cards: [
            MetricCard(
              label: 'Total Sales',
              value:
                  Formatters.currency((data['totalSales'] as num).toDouble()),
            ),
            MetricCard(
              label: 'Total Invoices',
              value: Formatters.number(data['totalInvoices'] as int),
            ),
            MetricCard(
              label: 'Avg Order Value',
              value: Formatters.currency(
                  (data['avgOrderValue'] as num).toDouble()),
            ),
          ],
        ),
        const SizedBox(height: 16),
        NexonCard(
          child: SizedBox(
            height: 280,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => const FlLine(
                      color: AppColors.lightBorder, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: categoryAxisTitles(
                    _months(monthly),
                    style: const TextStyle(fontSize: 10),
                  ),
                  leftTitles: hiddenAxisTitles,
                  topTitles: hiddenAxisTitles,
                  rightTitles: hiddenAxisTitles,
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: monthly.asMap().entries.map((e) {
                      return FlSpot(
                        e.key.toDouble(),
                        ((e.value as Map)['sales'] as num).toDouble() / 100000,
                      );
                    }).toList(),
                    isCurved: true,
                    color: AppColors.emerald500,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.emerald500.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LotWiseReport extends StatelessWidget {
  const _LotWiseReport({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final categories = (data['categories'] as List<dynamic>);

    return Column(
      children: [
        MetricRow(
          cards: [
            MetricCard(
              label: 'Lot Value',
              value:
                  Formatters.currency((data['totalValue'] as num).toDouble()),
            ),
            MetricCard(
              label: 'Open Lots',
              value: Formatters.number(data['lowStockItems'] as int),
            ),
          ],
        ),
        const SizedBox(height: 16),
        NexonCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: categories.map((c) {
              final cat = c as Map<String, dynamic>;
              return ListTile(
                title: Text(cat['name'] as String),
                subtitle: Text('${cat['items']} items'),
                trailing: Text(
                  Formatters.currency((cat['value'] as num).toDouble()),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _CustomerReport extends StatelessWidget {
  const _CustomerReport({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final top = (data['topCustomers'] as List<dynamic>);

    return Column(
      children: [
        MetricRow(
          cards: [
            MetricCard(
              label: 'Total Customers',
              value: Formatters.number(data['totalCustomers'] as int),
            ),
            MetricCard(
              label: 'Active',
              value: Formatters.number(data['activeCustomers'] as int),
            ),
            MetricCard(
              label: 'Outstanding',
              value: Formatters.currency(
                  (data['totalOutstanding'] as num).toDouble()),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Top Customers',
          children: [
            ...top.map((c) {
              final cust = c as Map<String, dynamic>;
              return ListTile(
                title: Text(cust['name'] as String),
                subtitle: Text('${cust['orders']} orders'),
                trailing: Text(
                  Formatters.currency((cust['purchases'] as num).toDouble()),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}

class _ProfitReport extends StatelessWidget {
  const _ProfitReport({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final monthly = (data['monthlyProfit'] as List<dynamic>);

    return Column(
      children: [
        MetricRow(
          cards: [
            MetricCard(
              label: 'Gross Profit',
              value:
                  Formatters.currency((data['grossProfit'] as num).toDouble()),
            ),
            MetricCard(
              label: 'Net Profit',
              value: Formatters.currency((data['netProfit'] as num).toDouble()),
            ),
            MetricCard(
              label: 'Margin',
              value: '${data['margin']}%',
            ),
          ],
        ),
        const SizedBox(height: 16),
        NexonCard(
          child: SizedBox(
            height: 280,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: categoryAxisTitles(
                    _months(monthly),
                    style: const TextStyle(fontSize: 10),
                  ),
                  leftTitles: hiddenAxisTitles,
                  topTitles: hiddenAxisTitles,
                  rightTitles: hiddenAxisTitles,
                ),
                borderData: FlBorderData(show: false),
                barGroups: monthly.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: ((e.value as Map)['profit'] as num).toDouble() /
                            100000,
                        color: AppColors.blue500,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

List<String> _months(List<dynamic> entries) =>
    entries.map((e) => (e as Map)['month'] as String).toList();
