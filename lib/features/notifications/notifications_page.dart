import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/nexon_card.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/status_chip.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  static final _notifications = [
    _Notification(
      title: 'Low stock: Spinach',
      body: 'Only 12 kg remaining. Minimum level is 30 kg.',
      time: DateTime.now().subtract(const Duration(minutes: 30)),
      type: NotificationType.alert,
      read: false,
    ),
    _Notification(
      title: 'Payment received',
      body: 'Green Valley Traders paid ₹28,500 via UPI.',
      time: DateTime.now().subtract(const Duration(hours: 2)),
      type: NotificationType.payment,
      read: false,
    ),
    _Notification(
      title: 'Invoice INV-2847 created',
      body: 'Fresh Mart Wholesale — ₹45,200',
      time: DateTime.now().subtract(const Duration(hours: 3)),
      type: NotificationType.invoice,
      read: true,
    ),
    _Notification(
      title: 'Stock received',
      body: '500 kg Tomato from AgriFresh Suppliers.',
      time: DateTime.now().subtract(const Duration(hours: 5)),
      type: NotificationType.inventory,
      read: true,
    ),
    _Notification(
      title: 'New customer added',
      body: 'Sunrise Hotel & Restaurant joined your customer list.',
      time: DateTime.now().subtract(const Duration(days: 1)),
      type: NotificationType.customer,
      read: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final unread = _notifications.where((n) => !n.read).length;

    return Padding(
      padding: EdgeInsets.all(responsive.contentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Notifications',
            subtitle: unread > 0 ? '$unread unread' : 'All caught up',
            actions: [
              if (unread > 0)
                TextButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All notifications marked as read')),
                  ),
                  child: const Text('Mark all read'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: NexonCard(
              padding: EdgeInsets.zero,
              child: ListView.separated(
                itemCount: _notifications.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final n = _notifications[index];
                  return ListTile(
                    leading: _NotificationIcon(type: n.type),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: TextStyle(
                              fontWeight: n.read ? FontWeight.w500 : FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!n.read) StatusChip(label: 'New', color: AppColors.orange500),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(n.body),
                        const SizedBox(height: 4),
                        Text(
                          Formatters.relativeTime(n.time),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    onTap: () {},
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum NotificationType { alert, payment, invoice, inventory, customer }

class _Notification {
  const _Notification({
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    required this.read,
  });

  final String title;
  final String body;
  final DateTime time;
  final NotificationType type;
  final bool read;
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({required this.type});

  final NotificationType type;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      NotificationType.alert => (Icons.warning_amber_rounded, AppColors.warning),
      NotificationType.payment => (Icons.payments_outlined, AppColors.success),
      NotificationType.invoice => (Icons.receipt_long_outlined, AppColors.emerald600),
      NotificationType.inventory => (Icons.inventory_2_outlined, AppColors.blue500),
      NotificationType.customer => (Icons.person_add_outlined, AppColors.info),
    };

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
