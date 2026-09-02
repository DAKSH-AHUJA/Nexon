import 'package:flutter/material.dart';

import '../utils/formatters.dart';
import 'status_chip.dart';

/// One line of transaction history: reference, date, amount and status.
class TransactionRow extends StatelessWidget {
  const TransactionRow({
    super.key,
    required this.reference,
    required this.date,
    required this.amount,
    this.status,
  });

  final String reference;
  final DateTime date;
  final num amount;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final status = this.status;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(reference, overflow: TextOverflow.ellipsis)),
          Text(Formatters.date(date)),
          const SizedBox(width: 16),
          Text(Formatters.currency(amount)),
          if (status != null) ...[
            const SizedBox(width: 12),
            StatusChip.payment(status),
          ],
        ],
      ),
    );
  }
}
