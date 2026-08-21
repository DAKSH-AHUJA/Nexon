import 'package:flutter/material.dart';

import '../../../core/theme/theme_context.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/animated_counter.dart';
import '../../../core/widgets/nexon_card.dart';
import '../../../models/dashboard_model.dart';

/// Recent invoices with status badges.
class RecentBillsTable extends StatelessWidget {
  const RecentBillsTable({super.key, required this.bills});

  final List<RecentBill> bills;

  @override
  Widget build(BuildContext context) {
    return NexonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Recent Bills',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              TextButton(onPressed: () {}, child: const Text('View all')),
            ],
          ),
          const SizedBox(height: 12),
          ...bills.map((bill) => _BillRow(bill: bill)),
        ],
      ),
    );
  }
}

class _BillRow extends StatefulWidget {
  const _BillRow({required this.bill});

  final RecentBill bill;

  @override
  State<_BillRow> createState() => _BillRowState();
}

class _BillRowState extends State<_BillRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bill = widget.bill;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _hovered ? context.appCardElevated : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bill.invoiceNumber,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    bill.customerName,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Text(
                Formatters.date(bill.date),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            AnimatedCounter(
              value: bill.amount,
              formatter: Formatters.currency,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: 12),
            StatusBadge.invoice(bill.status),
          ],
        ),
      ),
    );
  }
}
