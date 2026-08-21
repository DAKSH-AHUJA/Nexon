import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_context.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/responsive.dart';
import '../../services/auth_service.dart';

/// Top application bar with search, theme toggle, and profile.
class AppTopBar extends ConsumerWidget {
  const AppTopBar({
    super.key,
    this.onMenuTap,
    this.showMenuButton = false,
  });

  final VoidCallback? onMenuTap;
  final bool showMenuButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDarkMode;
    final themeMode = ref.watch(themeModeProvider);
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final company = ref.watch(authProvider).currentCompany;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          if (showMenuButton)
            IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: onMenuTap,
              tooltip: 'Menu',
            ),
          if (!showMenuButton) ...[
            Text(
              company?.name ?? AppConstants.appName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.emerald600.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Live',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.emerald400,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
          const Spacer(),
          if (!Responsive(context).isMobile)
            SizedBox(
              width: 280,
              child: _SearchField(isDark: isDark),
            ),
          if (!Responsive(context).isMobile) const SizedBox(width: 12),
          _TopBarIconButton(
            icon: themeMode == ThemeMode.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
            tooltip: 'Toggle theme',
            onTap: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
          const SizedBox(width: 8),
          _ProfileMenu(ref: ref),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search entries, parties, reports...',
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 20,
          color:
              isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        filled: true,
        fillColor: isDark ? AppColors.darkCard : AppColors.lightBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}

class _TopBarIconButton extends StatefulWidget {
  const _TopBarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_TopBarIconButton> createState() => _TopBarIconButtonState();
}

class _TopBarIconButtonState extends State<_TopBarIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 40,
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: _hovered
                  ? (isDark
                      ? AppColors.darkCardElevated
                      : AppColors.lightBackground)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(widget.icon, size: 20),
          ),
        ),
      ),
    );
  }
}

String _initials(String value) {
  final parts =
      value.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return 'AD';
  return parts.take(2).map((p) => p[0].toUpperCase()).join();
}

class _ProfileMenu extends StatelessWidget {
  const _ProfileMenu({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final company = ref.watch(authProvider).currentCompany;

    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'profile', child: Text('My Profile')),
        const PopupMenuItem(value: 'settings', child: Text('Settings')),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'logout', child: Text('Sign Out')),
      ],
      onSelected: (value) {
        if (value == 'logout') {
          ref.read(authProvider.notifier).logout();
          context.go('/login');
        } else if (value == 'settings') {
          context.go('/tools');
        }
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: context.isDarkMode
                  ? AppColors.darkBorder
                  : AppColors.lightBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.emerald600.withValues(alpha: 0.2),
                child: Text(
                  _initials(company?.name ?? 'Admin'),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.emerald400,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                company?.name ?? 'Admin',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(width: 4),
              const Icon(Icons.expand_more_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
