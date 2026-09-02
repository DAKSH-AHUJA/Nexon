import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/messages.dart';
import '../../../models/invoice_model.dart';

class InvoicePreviewDialog extends StatelessWidget {
  const InvoicePreviewDialog({super.key, required this.draft});

  final InvoiceDraft draft;

  @override
  Widget build(BuildContext context) {
    final customer = draft.customer!;
    final invoiceNo = draft.invoiceNo ?? 'DRAFT';

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 800),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text('Invoice Preview',
                      style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.lightBorder),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppConstants.companyName,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimaryLight,
                                ),
                              ),
                              Text(
                                'GST: ${AppConstants.companyGst}',
                                style: TextStyle(
                                    color: AppColors.textSecondaryLight),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                invoiceNo,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.emerald600,
                                ),
                              ),
                              Text(
                                Formatters.date(DateTime.now()),
                                style: const TextStyle(
                                    color: AppColors.textSecondaryLight),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Bill To',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        customer.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      Text(
                        '${customer.address}, ${customer.city}',
                        style: const TextStyle(
                            color: AppColors.textSecondaryLight),
                      ),
                      if (customer.gst.isNotEmpty)
                        Text(
                          'GST: ${customer.gst}',
                          style: const TextStyle(
                              color: AppColors.textSecondaryLight),
                        ),
                      const SizedBox(height: 24),
                      _InvoiceTable(draft: draft),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _TotalRow('Subtotal', draft.subtotal),
                            _TotalRow('GST', draft.totalGst),
                            const Divider(),
                            _TotalRow('Grand Total', draft.grandTotal,
                                bold: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.showMessage('PDF saved to Downloads');
                    },
                    child: const Text('Download PDF'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Invoice $invoiceNo created successfully'),
                        ),
                      );
                    },
                    child: const Text('Confirm'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceTable extends StatelessWidget {
  const _InvoiceTable({required this.draft});

  final InvoiceDraft draft;

  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder.all(color: AppColors.lightBorder),
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(1),
        5: FlexColumnWidth(1),
      },
      children: [
        const TableRow(
          decoration: BoxDecoration(color: Color(0xFFF1F5F9)),
          children: [
            _HeaderCell('Item'),
            _HeaderCell('Qty'),
            _HeaderCell('Rate'),
            _HeaderCell('Disc%'),
            _HeaderCell('GST'),
            _HeaderCell('Amount'),
          ],
        ),
        ...draft.items.map((item) {
          return TableRow(
            children: [
              _Cell(item.product.name),
              _Cell('${item.quantity} ${item.product.unit}'),
              _Cell(Formatters.currency(item.price)),
              _Cell('${item.discount}%'),
              _Cell('${item.gstRate}%'),
              _Cell(Formatters.currency(item.total)),
            ],
          );
        }),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: AppColors.textPrimaryLight,
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(text,
          style:
              const TextStyle(fontSize: 12, color: AppColors.textPrimaryLight)),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow(this.label, this.amount, {this.bold = false});

  final String label;
  final double amount;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: AppColors.textPrimaryLight,
              ),
            ),
          ),
          Text(
            Formatters.currency(amount),
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
