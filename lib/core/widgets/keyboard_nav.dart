import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wraps an input so ArrowDown/ArrowUp (and Enter) move focus to the next
/// field in a data-entry form.
///
/// Single-line [TextField]s ignore vertical arrows, so those key events bubble
/// up to this ancestor [Focus] node where we handle them. This gives the
/// operator a keyboard-only flow: type, press ↓, type, press ↓ … without ever
/// touching the mouse.
class ArrowKeyNav extends StatelessWidget {
  const ArrowKeyNav({
    super.key,
    this.next,
    this.previous,
    required this.child,
  });

  final FocusNode? next;
  final FocusNode? previous;
  final Widget child;

  KeyEventResult _handle(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown && next != null) {
      next!.requestFocus();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp && previous != null) {
      previous!.requestFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _handle,
      child: child,
    );
  }
}