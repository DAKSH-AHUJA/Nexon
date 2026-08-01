import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../nav_destinations.dart';

/// Left navigation sidebar for desktop and drawer for mobile.
class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.current,
    required this.onNavigate,
    required this.expanded,
    this.onToggleCollapse,
  });

  final NavDestination current;
  final ValueChanged<NavDestination> onNavigate;
  final bool expanded;
  final VoidCallback? onToggleCollapse;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(right: BorderSide(color: borderColor)),
      ),
      child: Column(
        children: [
          _LogoSection(expanded: expanded, onToggleCollapse: onToggleCollapse),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: NavDestination.values.map((dest) {
                final selected = dest == current;
                return _NavItem(
                  destination: dest,
                  selected: selected,
                  expanded: expanded,
                  onTap: () => onNavigate(dest),
                );
              }).toList(),
            ),
          ),
          if (expanded) _SidebarFooter(isDark: isDark),
        ],
      ),
    );
  }
}

class _LogoSection extends StatelessWidget {
  const _LogoSection({required this.expanded, this.onToggleCollapse});

  final bool expanded;
  final VoidCallback? onToggleCollapse;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(expanded ? 20 : 12, 20, expanded ? 16 : 12, 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.emerald600,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 20),
          ),
          if (expanded) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    'Wholesale ERP',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            if (onToggleCollapse != null)
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 20),
                onPressed: onToggleCollapse,
                tooltip: 'Collapse sidebar',
              ),
          ],
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  final NavDestination destination;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = widget.selected;
    final bgColor = selected
        ? AppColors.emerald600.withValues(alpha: 0.12)
        : _hovered
            ? (isDark
                ? AppColors.darkCardElevated
                : AppColors.lightBackground)
            : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: AppConstants.animationFast,
              padding: EdgeInsets.symmetric(
                horizontal: widget.expanded ? 12 : 0,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
                border: selected
                    ? Border.all(
                        color: AppColors.emerald600.withValues(alpha: 0.25),
                      )
                    : null,
              ),
              child: widget.expanded
                  ? Row(
                      children: [
                        Icon(
                          selected
                              ? widget.destination.selectedIcon
                              : widget.destination.icon,
                          size: 20,
                          color: selected
                              ? AppColors.emerald400
                              : (isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.destination.label,
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight:
                                          selected ? FontWeight.w600 : FontWeight.w500,
                                      color: selected
                                          ? AppColors.emerald400
                                          : null,
                                    ),
                          ),
                        ),
                        if (widget.destination == NavDestination.notifications)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.orange500,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    )
                  : Center(
                      child: Icon(
                        selected
                            ? widget.destination.selectedIcon
                            : widget.destination.icon,
                        size: 22,
                        color: selected
                            ? AppColors.emerald400
                            : (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.blue500.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.store_rounded, color: AppColors.blue400, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.companyName,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Pro Plan',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.emerald400,
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
