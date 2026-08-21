import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/nexon_card.dart';
import '../../core/widgets/page_header.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final responsive = Responsive(context);

    return Padding(
      padding: EdgeInsets.all(responsive.contentPadding),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(
              title: 'Settings',
              subtitle: 'Manage your company profile and preferences',
            ),
            const SizedBox(height: 24),
            _Section(
              title: 'Company',
              child: NexonCard(
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.emerald500.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.store,
                            color: AppColors.emerald600),
                      ),
                      title: const Text(AppConstants.companyName),
                      subtitle: const Text('GST: ${AppConstants.companyGst}'),
                      trailing: OutlinedButton(
                        onPressed: () {},
                        child: const Text('Edit'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _Section(
              title: 'Appearance',
              child: NexonCard(
                child: SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Use dark theme across the app'),
                  value: themeMode == ThemeMode.dark,
                  onChanged: (_) =>
                      ref.read(themeModeProvider.notifier).toggle(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _Section(
              title: 'Invoice',
              child: NexonCard(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Invoice Theme'),
                      subtitle: const Text('Classic White'),
                      trailing: DropdownButton<String>(
                        value: 'classic',
                        items: const [
                          DropdownMenuItem(
                              value: 'classic', child: Text('Classic White')),
                          DropdownMenuItem(
                              value: 'modern', child: Text('Modern Green')),
                        ],
                        onChanged: (_) {},
                      ),
                    ),
                    const Divider(height: 1),
                    const ListTile(
                      title: Text('Default GST Rate'),
                      subtitle: Text('5% for vegetables'),
                      trailing: Text('5%'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _Section(
              title: 'Users',
              child: NexonCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    const _UserTile(
                        name: 'Admin User',
                        email: 'admin@freshharvest.in',
                        role: 'Owner'),
                    const Divider(height: 1),
                    const _UserTile(
                        name: 'Billing Staff',
                        email: 'billing@freshharvest.in',
                        role: 'Staff'),
                    ListTile(
                      leading: const Icon(Icons.person_add_outlined),
                      title: const Text('Add User'),
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('User management coming in production')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _Section(
              title: 'Notifications',
              child: NexonCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Low Stock Alerts'),
                      value: true,
                      onChanged: (_) {},
                    ),
                    SwitchListTile(
                      title: const Text('Payment Reminders'),
                      value: true,
                      onChanged: (_) {},
                    ),
                    SwitchListTile(
                      title: const Text('Daily Summary Email'),
                      value: false,
                      onChanged: (_) {},
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.name,
    required this.email,
    required this.role,
  });

  final String name;
  final String email;
  final String role;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.blue500.withValues(alpha: 0.12),
        child: Text(
          name[0],
          style: const TextStyle(
              color: AppColors.blue600, fontWeight: FontWeight.w600),
        ),
      ),
      title: Text(name),
      subtitle: Text(email),
      trailing: Text(role, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
