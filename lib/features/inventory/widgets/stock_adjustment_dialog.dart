import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/product_model.dart';
import '../../../services/products_provider.dart';

class StockAdjustmentDialog extends ConsumerStatefulWidget {
  const StockAdjustmentDialog({
    super.key,
    required this.product,
    required this.type,
  });

  final Product product;
  final String type;

  @override
  ConsumerState<StockAdjustmentDialog> createState() =>
      _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends ConsumerState<StockAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _qtyCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String get _title => switch (widget.type) {
        'stock_in' => 'Add Stock',
        'stock_out' => 'Remove Stock',
        _ => 'Adjust Stock',
      };

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final qty = double.parse(_qtyCtrl.text);
    ref.read(productsProvider.notifier).adjustStock(
          productId: widget.product.id,
          type: widget.type,
          quantity: qty,
          note: _noteCtrl.text.trim(),
        );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Stock updated for ${widget.product.name}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('$_title — ${widget.product.name}'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Current: ${widget.product.currentStock} ${widget.product.unit}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _qtyCtrl,
                decoration: InputDecoration(
                  labelText: 'Quantity (${widget.product.unit})',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final n = double.tryParse(v);
                  if (n == null || n <= 0) return 'Enter valid quantity';
                  if (widget.type == 'stock_out' && n > widget.product.currentStock) {
                    return 'Exceeds available stock';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _submit, child: const Text('Confirm')),
      ],
    );
  }
}
