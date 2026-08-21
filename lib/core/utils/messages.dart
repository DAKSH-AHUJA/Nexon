import 'package:flutter/material.dart';

/// Snack bar helpers shared by every feature.
extension MessageX on BuildContext {
  void showMessage(String message) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(content: Text(message)));
  }
}
