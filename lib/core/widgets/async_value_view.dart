import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders an [AsyncValue] with the app's default loading and error states.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.errorMessage = 'Error',
    this.loading,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;

  /// Prefix for the error text, e.g. `Failed to load dashboard`.
  final String errorMessage;

  /// Optional replacement for the default spinner.
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () =>
          loading ?? const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('$errorMessage: $error')),
      data: data,
    );
  }
}
