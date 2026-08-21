import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/page_header.dart';

class DataEntryPage extends StatelessWidget {
  const DataEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TradingMenuPage(
      title: 'Data Entry',
      items: [
        TradingMenuItem('Purc/SPAT', '/data-entry/purc-spat'),
        TradingMenuItem('Sale', '/data-entry/sale'),
        TradingMenuItem('Cash', '/data-entry/cash'),
        TradingMenuItem('Bank', '/data-entry/bank'),
        TradingMenuItem('Journal', '/data-entry/journal'),
        TradingMenuItem('Sale Patti', '/data-entry/sale-patti'),
        TradingMenuItem('Carets Entry', '/data-entry/carets-entry'),
      ],
    );
  }
}

class CorrectEntryPage extends StatelessWidget {
  const CorrectEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TradingMenuPage(
      title: 'Correct Entry',
      items: [
        TradingMenuItem('Account', '/correct-entry/account'),
        TradingMenuItem('Item', '/correct-entry/item'),
      ],
    );
  }
}

class TradingReportsPage extends StatelessWidget {
  const TradingReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TradingMenuPage(
      title: 'Reports',
      items: [
        TradingMenuItem('Master', '/reports/master'),
        TradingMenuItem('Statement', '/reports/statement'),
        TradingMenuItem('Books', '/reports/books'),
        TradingMenuItem('Ledger', '/reports/ledger'),
        TradingMenuItem('Outstanding', '/reports/outstanding'),
        TradingMenuItem('Balancesheet', '/reports/balancesheet'),
      ],
    );
  }
}

class BackupPage extends StatelessWidget {
  const BackupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TradingSectionPage(title: 'Back up');
  }
}

class RestorePage extends StatelessWidget {
  const RestorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TradingSectionPage(title: 'Restore');
  }
}

class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TradingSectionPage(title: 'Tools');
  }
}

class TradingFeaturePage extends StatelessWidget {
  const TradingFeaturePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return TradingSectionPage(title: title);
  }
}

class TradingMenuItem {
  const TradingMenuItem(this.label, this.route);

  final String label;
  final String route;
}

class TradingMenuPage extends StatefulWidget {
  const TradingMenuPage({super.key, required this.title, required this.items});

  final String title;
  final List<TradingMenuItem> items;

  @override
  State<TradingMenuPage> createState() => _TradingMenuPageState();
}

class _TradingMenuPageState extends State<TradingMenuPage> {
  late final List<FocusNode> _focusNodes;
  final _scrollController = ScrollController();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(
      widget.items.length,
      (index) => FocusNode(debugLabel: '${widget.title} ${index + 1}'),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _focusNodes.isNotEmpty) {
        _focusNodes.first.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _moveSelection(int delta) {
    if (widget.items.isEmpty) return;
    final nextIndex = (_selectedIndex + delta).clamp(
      0,
      widget.items.length - 1,
    );
    _select(nextIndex);
  }

  void _select(int index) {
    if (index < 0 || index >= widget.items.length) return;
    setState(() => _selectedIndex = index);
    _focusNodes[index].requestFocus();
    final context = _focusNodes[index].context;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      alignment: 0.5,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
    );
  }

  void _openSelected() {
    if (widget.items.isEmpty) return;
    context.go(widget.items[_selectedIndex].route);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            _moveSelection(1),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
            _moveSelection(-1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            _moveSelection(1),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            _moveSelection(-1),
        const SingleActivator(LogicalKeyboardKey.enter): _openSelected,
        const SingleActivator(LogicalKeyboardKey.numpadEnter): _openSelected,
      },
      child: Focus(
        autofocus: true,
        child: Container(
          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.all(responsive.contentPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(title: widget.title),
                SizedBox(height: responsive.isMobile ? 28 : 48),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      children: [
                        for (var i = 0; i < widget.items.length; i++) ...[
                          _TradingMenuButton(
                            number: i + 1,
                            item: widget.items[i],
                            focusNode: _focusNodes[i],
                            selected: i == _selectedIndex,
                            onFocus: () => setState(() => _selectedIndex = i),
                            onPressed: () => context.go(widget.items[i].route),
                          ),
                          if (i != widget.items.length - 1)
                            const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TradingMenuButton extends StatelessWidget {
  const _TradingMenuButton({
    required this.number,
    required this.item,
    required this.focusNode,
    required this.selected,
    required this.onFocus,
    required this.onPressed,
  });

  final int number;
  final TradingMenuItem item;
  final FocusNode focusNode;
  final bool selected;
  final VoidCallback onFocus;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = selected
        ? AppColors.emerald500
        : isDark
            ? AppColors.darkBorder
            : AppColors.lightBorder;

    return Focus(
      focusNode: focusNode,
      onFocusChange: (hasFocus) {
        if (hasFocus) onFocus();
      },
      child: Builder(
        builder: (context) {
          final focused = Focus.of(context).hasFocus;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: focused
                  ? [
                      BoxShadow(
                        color: AppColors.emerald600.withValues(alpha: 0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : const [],
            ),
            child: Material(
              color: focused
                  ? AppColors.emerald600.withValues(alpha: 0.12)
                  : isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: borderColor,
                      width: focused ? 1.5 : 1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 34,
                        child: Text(
                          '$number.',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: focused ? AppColors.emerald400 : null,
                              ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.label,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_right_rounded,
                        color: focused
                            ? AppColors.emerald400
                            : isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class TradingSectionPage extends StatelessWidget {
  const TradingSectionPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(responsive.contentPadding),
        child: PageHeader(title: title),
      ),
    );
  }
}
