import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/nexon_card.dart';
import '../../core/widgets/page_header.dart';
import '../../models/customer_model.dart';
import '../../services/customers_provider.dart';

class CashEntryPage extends ConsumerStatefulWidget {
  const CashEntryPage({super.key});

  @override
  ConsumerState<CashEntryPage> createState() => _CashEntryPageState();
}

class _CashEntryPageState extends ConsumerState<CashEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedCustomerId;
  String _mode = 'Cash';

  static const _modes = ['Cash', 'UPI', 'Bank Transfer', 'Cheque'];

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customersProvider);
    final responsive = Responsive(context);
    final customersWithDues =
        state.customers.where((c) => c.hasOutstanding).toList();
    final selectedId = _selectedCustomerId != null &&
            customersWithDues.any((c) => c.id == _selectedCustomerId)
        ? _selectedCustomerId
        : (customersWithDues.isNotEmpty ? customersWithDues.first.id : null);
    final selectedCustomer = selectedId == null
        ? null
        : customersWithDues.firstWhere((c) => c.id == selectedId);
    final receipts = _cashReceipts(state.customers);
    final totalOutstanding = state.customers.fold<double>(
      0,
      (sum, c) => sum + c.outstandingBalance,
    );
    final collectedToday = receipts
        .where((r) => _isSameDay(r.date, DateTime.now()))
        .fold<double>(0, (sum, r) => sum + r.amount);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null) {
      return ErrorState(
        message: state.errorMessage!,
        onRetry: () => ref.read(customersProvider.notifier).load(),
      );
    }

    return Padding(
      padding: EdgeInsets.all(responsive.contentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Cash Entry',
            subtitle:
                'Record customer payments received against vegetable trading dues',
          ),
          const SizedBox(height: 20),
          _SummaryStrip(
            totalOutstanding: totalOutstanding,
            customersOwing: customersWithDues.length,
            collectedToday: collectedToday,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: responsive.isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: SingleChildScrollView(
                          child: _CashEntryForm(
                            formKey: _formKey,
                            customers: customersWithDues,
                            selectedCustomer: selectedCustomer,
                            selectedCustomerId: selectedId,
                            amountController: _amountController,
                            referenceController: _referenceController,
                            notesController: _notesController,
                            mode: _mode,
                            modes: _modes,
                            onModeChanged: (mode) =>
                                setState(() => _mode = mode),
                            onCustomerChanged: (id) =>
                                setState(() => _selectedCustomerId = id),
                            onSubmit: () => _submit(selectedCustomer),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: _ReceiptHistory(
                          receipts: receipts,
                          fillAvailableHeight: true,
                        ),
                      ),
                    ],
                  )
                : ListView(
                    children: [
                      _CashEntryForm(
                        formKey: _formKey,
                        customers: customersWithDues,
                        selectedCustomer: selectedCustomer,
                        selectedCustomerId: selectedId,
                        amountController: _amountController,
                        referenceController: _referenceController,
                        notesController: _notesController,
                        mode: _mode,
                        modes: _modes,
                        onModeChanged: (mode) => setState(() => _mode = mode),
                        onCustomerChanged: (id) =>
                            setState(() => _selectedCustomerId = id),
                        onSubmit: () => _submit(selectedCustomer),
                      ),
                      const SizedBox(height: 16),
                      _ReceiptHistory(
                        receipts: receipts,
                        fillAvailableHeight: false,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _submit(Customer? selectedCustomer) {
    if (selectedCustomer == null) return;
    if (!_formKey.currentState!.validate()) return;

    final amount = _parseAmount(_amountController.text);
    final updated = ref.read(customersProvider.notifier).applyCashPayment(
          customerId: selectedCustomer.id,
          amount: amount,
          mode: _mode,
          receivedAt: DateTime.now(),
          reference: _referenceController.text,
          notes: _notesController.text,
        );

    if (updated == null || !mounted) return;

    _amountController.clear();
    _referenceController.clear();
    _notesController.clear();
    setState(
        () => _selectedCustomerId = updated.hasOutstanding ? updated.id : null);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Received ${Formatters.currency(amount)} from ${updated.name}.',
        ),
      ),
    );
  }

  double _parseAmount(String value) {
    return double.tryParse(value.replaceAll(',', '').trim()) ?? 0;
  }

  List<_CashReceipt> _cashReceipts(List<Customer> customers) {
    final receipts = <_CashReceipt>[];
    for (final customer in customers) {
      for (final entry in customer.ledger) {
        if (entry.credit <= 0) continue;
        receipts.add(
          _CashReceipt(
            customerName: customer.name,
            date: entry.date,
            description: entry.description,
            amount: entry.credit,
            balance: entry.balance,
          ),
        );
      }
    }
    receipts.sort((a, b) => b.date.compareTo(a.date));
    return receipts;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.totalOutstanding,
    required this.customersOwing,
    required this.collectedToday,
  });

  final double totalOutstanding;
  final int customersOwing;
  final double collectedToday;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            label: 'Total Due',
            value: Formatters.currency(totalOutstanding),
            icon: Icons.account_balance_wallet_outlined,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricTile(
            label: 'Customers Owing',
            value: Formatters.number(customersOwing),
            icon: Icons.people_outline_rounded,
            color: AppColors.blue500,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricTile(
            label: 'Collected Today',
            value: Formatters.currency(collectedToday),
            icon: Icons.payments_outlined,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return NexonCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CashEntryForm extends StatelessWidget {
  const _CashEntryForm({
    required this.formKey,
    required this.customers,
    required this.selectedCustomer,
    required this.selectedCustomerId,
    required this.amountController,
    required this.referenceController,
    required this.notesController,
    required this.mode,
    required this.modes,
    required this.onModeChanged,
    required this.onCustomerChanged,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final List<Customer> customers;
  final Customer? selectedCustomer;
  final String? selectedCustomerId;
  final TextEditingController amountController;
  final TextEditingController referenceController;
  final TextEditingController notesController;
  final String mode;
  final List<String> modes;
  final ValueChanged<String> onModeChanged;
  final ValueChanged<String?> onCustomerChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    if (customers.isEmpty) {
      return const NexonCard(
        child: EmptyState(
          icon: Icons.check_circle_outline_rounded,
          title: 'No customer dues',
          subtitle: 'All customer balances are currently settled.',
        ),
      );
    }

    return NexonCard(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Receive Cash', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              AppConstants.companyName,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: selectedCustomerId,
              decoration: const InputDecoration(
                labelText: 'Customer',
                prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
              ),
              items: customers.map((customer) {
                return DropdownMenuItem(
                  value: customer.id,
                  child: Text(
                    '${customer.name} - ${Formatters.currency(customer.outstandingBalance)} due',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: onCustomerChanged,
            ),
            if (selectedCustomer != null) ...[
              const SizedBox(height: 12),
              _DueBanner(customer: selectedCustomer!),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Amount received',
                prefixIcon: Icon(Icons.currency_rupee_rounded, size: 20),
              ),
              validator: (value) {
                final amount = double.tryParse(
                      (value ?? '').replaceAll(',', '').trim(),
                    ) ??
                    0;
                if (amount <= 0) return 'Enter the cash amount received';
                if (selectedCustomer != null &&
                    amount > selectedCustomer!.outstandingBalance) {
                  return 'Amount cannot exceed outstanding balance';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: mode,
              decoration: const InputDecoration(
                labelText: 'Payment mode',
                prefixIcon: Icon(Icons.payments_outlined, size: 20),
              ),
              items: modes
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (value) {
                if (value != null) onModeChanged(value);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: referenceController,
              decoration: const InputDecoration(
                labelText: 'Reference number',
                prefixIcon: Icon(Icons.confirmation_number_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: notesController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Example: Received for tomato and potato bill',
                prefixIcon: Icon(Icons.notes_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onSubmit,
                icon: const Icon(Icons.add_card_outlined, size: 18),
                label: const Text('Record Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DueBanner extends StatelessWidget {
  const _DueBanner({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${customer.name} currently owes ${Formatters.currency(customer.outstandingBalance)}.',
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptHistory extends StatelessWidget {
  const _ReceiptHistory({
    required this.receipts,
    required this.fillAvailableHeight,
  });

  final List<_CashReceipt> receipts;
  final bool fillAvailableHeight;

  @override
  Widget build(BuildContext context) {
    if (receipts.isEmpty) {
      return const NexonCard(
        child: EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'No receipts recorded',
          subtitle: 'Cash entries will appear here as customer ledger credits.',
        ),
      );
    }

    final list = _ReceiptList(receipts: receipts);

    return NexonCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Recent Receipts',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const Divider(height: 1),
          if (fillAvailableHeight)
            Expanded(child: list)
          else
            SizedBox(height: 360, child: list),
        ],
      ),
    );
  }
}

class _ReceiptList extends StatelessWidget {
  const _ReceiptList({required this.receipts});

  final List<_CashReceipt> receipts;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: receipts.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final receipt = receipts[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.success.withValues(alpha: 0.12),
            child: const Icon(
              Icons.payments_outlined,
              color: AppColors.success,
              size: 20,
            ),
          ),
          title: Text(receipt.customerName),
          subtitle: Text(
            '${Formatters.dateTime(receipt.date)} - ${receipt.description}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.currency(receipt.amount),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                '${Formatters.currency(receipt.balance)} due',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CashReceipt {
  const _CashReceipt({
    required this.customerName,
    required this.date,
    required this.description,
    required this.amount,
    required this.balance,
  });

  final String customerName;
  final DateTime date;
  final String description;
  final double amount;
  final double balance;
}
